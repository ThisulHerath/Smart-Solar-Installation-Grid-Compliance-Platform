using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SolarPlatform.Api.Data;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Models;

namespace SolarPlatform.Api.Controllers;

[ApiController, Authorize]
[Route("api/chat")]
public class ChatController : ControllerBase
{
    private readonly AppDbContext _db;

    public ChatController(AppDbContext db) => _db = db;

    [HttpGet("conversations")]
    public async Task<ActionResult<IReadOnlyList<ConversationDto>>> List()
    {
        var userId = UserId();
        var isHomeowner = User.IsInRole(RoleConstants.Homeowner);
        var isTechnician = User.IsInRole(RoleConstants.FieldTechnician);
        var isStaff = User.IsInRole(RoleConstants.Administrator) ||
                      User.IsInRole(RoleConstants.SeniorEngineer);

        if (!isHomeowner && !isTechnician && !isStaff) return Forbid();

        var query = _db.SupportConversations.AsNoTracking();
        if (!isStaff)
        {
            query = isHomeowner
                ? query.Where(c => c.HomeownerId == userId)
                : query.Where(c => c.TechnicianId == userId);
        }

        var conversations = await query
            .OrderByDescending(c => c.LastMessageAt)
            .Select(c => new ConversationDto(
                c.Id,
                c.SolarSurveyId,
                c.SolarSurvey.PropertyAddress,
                isHomeowner ? c.TechnicianId : c.HomeownerId,
                isHomeowner ? c.Technician.FullName : c.Homeowner.FullName,
                c.Messages.OrderByDescending(m => m.CreatedAt)
                    .Select(m => m.Body).FirstOrDefault(),
                c.LastMessageAt,
                c.Messages.Count(m => m.SenderId != userId && m.ReadAt == null)))
            .ToListAsync();

        return Ok(conversations);
    }

    [HttpPost("conversations")]
    [Authorize(Roles = RoleConstants.Homeowner)]
    public async Task<ActionResult<ConversationDto>> Create(CreateConversationRequest request)
    {
        var homeownerId = UserId();
        var survey = await _db.SolarSurveys
            .Include(s => s.Customer)
            .SingleOrDefaultAsync(s => s.Id == request.SurveyId &&
                                       s.Customer.UserId == homeownerId);
        if (survey == null) return NotFound(new { message = "Survey not found." });

        var existing = await _db.SupportConversations
            .Include(c => c.Technician)
            .Include(c => c.SolarSurvey)
            .SingleOrDefaultAsync(c => c.SolarSurveyId == request.SurveyId);
        if (existing != null)
        {
            return Ok(ToConversationDto(existing, homeownerId, true));
        }

        var technicianId = await _db.FieldJobs
            .Where(j => j.SolarSurveyId == survey.Id && j.Technician.IsActive)
            .OrderByDescending(j => j.AssignedAt)
            .Select(j => (Guid?)j.TechnicianId)
            .FirstOrDefaultAsync();

        technicianId ??= await _db.Users
            .Where(u => u.IsActive && u.UserRoles.Any(ur =>
                ur.Role.Name == RoleConstants.FieldTechnician))
            .OrderBy(u => u.FullName)
            .Select(u => (Guid?)u.Id)
            .FirstOrDefaultAsync();

        if (technicianId == null)
            return Conflict(new { message = "No support technician is available yet." });

        var conversation = new SupportConversation
        {
            SolarSurveyId = survey.Id,
            HomeownerId = homeownerId,
            TechnicianId = technicianId.Value,
            SolarSurvey = survey,
            CreatedAt = DateTime.UtcNow,
            LastMessageAt = DateTime.UtcNow
        };
        _db.SupportConversations.Add(conversation);
        await _db.SaveChangesAsync();
        await _db.Entry(conversation).Reference(c => c.Technician).LoadAsync();

        return CreatedAtAction(nameof(Messages), new { id = conversation.Id },
            ToConversationDto(conversation, homeownerId, true));
    }

    [HttpGet("conversations/{id:guid}/messages")]
    public async Task<ActionResult<IReadOnlyList<ChatMessageDto>>> Messages(Guid id)
    {
        var userId = UserId();
        var conversation = await AuthorizedConversation(id, userId);
        if (conversation == null) return NotFound();

        var messages = await _db.SupportMessages.AsNoTracking()
            .Where(m => m.ConversationId == id)
            .OrderBy(m => m.CreatedAt)
            .Take(300)
            .Select(m => new ChatMessageDto(
                m.Id,
                m.ConversationId,
                m.SenderId,
                m.Sender.FullName,
                m.Body,
                m.CreatedAt,
                m.ReadAt,
                m.SenderId == userId))
            .ToListAsync();

        return Ok(messages);
    }

    [HttpPost("conversations/{id:guid}/messages")]
    public async Task<ActionResult<ChatMessageDto>> Send(
        Guid id, SendMessageRequest request)
    {
        var userId = UserId();
        var conversation = await AuthorizedConversation(id, userId);
        if (conversation == null) return NotFound();

        var body = request.Body?.Trim();
        if (string.IsNullOrWhiteSpace(body))
            return BadRequest(new { message = "Message cannot be empty." });
        if (body.Length > 2000)
            return BadRequest(new { message = "Message cannot exceed 2000 characters." });

        var senderName = await _db.Users.Where(u => u.Id == userId)
            .Select(u => u.FullName).SingleAsync();
        var message = new SupportMessage
        {
            ConversationId = id,
            SenderId = userId,
            Body = body,
            CreatedAt = DateTime.UtcNow
        };
        conversation.LastMessageAt = message.CreatedAt;
        _db.SupportMessages.Add(message);
        await _db.SaveChangesAsync();

        return Ok(new ChatMessageDto(message.Id, id, userId, senderName,
            message.Body, message.CreatedAt, null, true));
    }

    [HttpPost("conversations/{id:guid}/read")]
    public async Task<IActionResult> MarkRead(Guid id)
    {
        var userId = UserId();
        if (await AuthorizedConversation(id, userId) == null) return NotFound();

        var unread = await _db.SupportMessages
            .Where(m => m.ConversationId == id &&
                        m.SenderId != userId && m.ReadAt == null)
            .ToListAsync();
        var now = DateTime.UtcNow;
        foreach (var message in unread) message.ReadAt = now;
        await _db.SaveChangesAsync();
        return NoContent();
    }

    [HttpGet("unread-count")]
    public async Task<IActionResult> UnreadCount()
    {
        var userId = UserId();
        var count = await _db.SupportMessages.AsNoTracking().CountAsync(m =>
            m.SenderId != userId && m.ReadAt == null &&
            (m.Conversation.HomeownerId == userId ||
             m.Conversation.TechnicianId == userId));
        return Ok(new { count });
    }

    private async Task<SupportConversation?> AuthorizedConversation(
        Guid id, Guid userId)
    {
        var isStaff = User.IsInRole(RoleConstants.Administrator) ||
                      User.IsInRole(RoleConstants.SeniorEngineer);
        return await _db.SupportConversations.SingleOrDefaultAsync(c =>
            c.Id == id && (isStaff || c.HomeownerId == userId ||
                           c.TechnicianId == userId));
    }

    private static ConversationDto ToConversationDto(
        SupportConversation conversation, Guid userId, bool isHomeowner) =>
        new(
            conversation.Id,
            conversation.SolarSurveyId,
            conversation.SolarSurvey?.PropertyAddress ?? string.Empty,
            isHomeowner ? conversation.TechnicianId : conversation.HomeownerId,
            isHomeowner
                ? conversation.Technician?.FullName ?? "Support technician"
                : conversation.Homeowner?.FullName ?? "Homeowner",
            null,
            conversation.LastMessageAt,
            0);

    private Guid UserId() => Guid.TryParse(
        User.FindFirstValue(ClaimTypes.NameIdentifier) ??
        User.FindFirstValue("sub"), out var id)
        ? id
        : throw new UnauthorizedAccessException("Invalid token user identity.");
}
