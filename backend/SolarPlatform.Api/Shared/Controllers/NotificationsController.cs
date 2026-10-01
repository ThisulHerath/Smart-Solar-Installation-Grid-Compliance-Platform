using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Services;

namespace SolarPlatform.Api.Controllers;

[ApiController, Authorize, Route("api/notifications")]
public class NotificationsController : ControllerBase
{
    private readonly INotificationService _notifications;
    public NotificationsController(INotificationService notifications) => _notifications = notifications;

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<NotificationDto>>> List([FromQuery] bool unreadOnly = false, [FromQuery] int limit = 50) =>
        Ok(await _notifications.GetForUserAsync(UserId(), unreadOnly, limit));

    [HttpGet("unread-count")]
    public async Task<ActionResult<NotificationCountDto>> UnreadCount() =>
        Ok(new NotificationCountDto(await _notifications.GetUnreadCountAsync(UserId())));

    [HttpPost("{id:guid}/read")]
    public async Task<IActionResult> MarkRead(Guid id) =>
        await _notifications.MarkReadAsync(UserId(), id) ? NoContent() : NotFound();

    [HttpPost("read-all")]
    public async Task<ActionResult<NotificationCountDto>> MarkAllRead() =>
        Ok(new NotificationCountDto(await _notifications.MarkAllReadAsync(UserId())));

    private Guid UserId() => Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub"), out var id)
        ? id : throw new UnauthorizedAccessException("Invalid token user identity.");
}
