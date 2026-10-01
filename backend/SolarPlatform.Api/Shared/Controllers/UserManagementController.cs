using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SolarPlatform.Api.Authentication;
using SolarPlatform.Api.Data;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Models;

namespace SolarPlatform.Api.Controllers;

[ApiController]
[Route("api/admin/users")]
[Authorize(Roles = RoleConstants.Administrator)]
public class UserManagementController(AppDbContext db, IPasswordHasher passwordHasher) : ControllerBase
{
    private static readonly HashSet<string> AssignableRoles =
    [
        RoleConstants.SeniorEngineer,
        RoleConstants.FieldTechnician,
        RoleConstants.Administrator,
        RoleConstants.InventoryOfficer
    ];

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ManagedUserDto>>> List(CancellationToken ct)
    {
        var users = await db.Users
            .AsNoTracking()
            .Include(user => user.UserRoles)
            .ThenInclude(userRole => userRole.Role)
            .OrderByDescending(user => user.CreatedAt)
            .Select(user => new ManagedUserDto
            {
                Id = user.Id,
                FullName = user.FullName,
                Email = user.Email,
                PhoneNumber = user.PhoneNumber,
                IsActive = user.IsActive,
                CreatedAt = user.CreatedAt,
                Roles = user.UserRoles.Select(userRole => userRole.Role.Name).ToList()
            })
            .ToListAsync(ct);

        return Ok(users);
    }

    [HttpPost]
    public async Task<ActionResult<ManagedUserDto>> Create(CreateManagedUserDto request, CancellationToken ct)
    {
        var roleName = request.Role.Trim().ToUpperInvariant();
        if (!AssignableRoles.Contains(roleName))
            return BadRequest(new { message = "Select a staff role that can be assigned by an administrator." });

        var email = request.Email.Trim().ToLowerInvariant();
        if (await db.Users.AnyAsync(user => user.Email == email, ct))
            return Conflict(new { message = "A user with this email already exists." });

        var role = await db.Roles.SingleOrDefaultAsync(item => item.Name == roleName, ct);
        if (role is null)
            return BadRequest(new { message = "The selected role is not available." });

        var now = DateTime.UtcNow;
        var user = new User
        {
            Id = Guid.NewGuid(),
            FullName = request.FullName.Trim(),
            Email = email,
            PhoneNumber = string.IsNullOrWhiteSpace(request.PhoneNumber) ? null : request.PhoneNumber.Trim(),
            PasswordHash = passwordHasher.HashPassword(request.Password),
            IsActive = true,
            CreatedAt = now,
            UpdatedAt = now,
            UserRoles = [new UserRole { RoleId = role.Id }]
        };

        db.Users.Add(user);
        await db.SaveChangesAsync(ct);

        return CreatedAtAction(nameof(List), new { id = user.Id }, ToDto(user, [roleName]));
    }

    [HttpPut("{id:guid}/status")]
    public async Task<ActionResult<ManagedUserDto>> UpdateStatus(Guid id, UpdateManagedUserStatusDto request, CancellationToken ct)
    {
        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.Equals(currentUserId, id.ToString(), StringComparison.OrdinalIgnoreCase) && !request.IsActive)
            return BadRequest(new { message = "You cannot deactivate your own administrator account." });

        var user = await db.Users
            .Include(item => item.UserRoles)
            .ThenInclude(userRole => userRole.Role)
            .SingleOrDefaultAsync(item => item.Id == id, ct);

        if (user is null)
            return NotFound(new { message = "User not found." });

        if (user.IsActive != request.IsActive)
        {
            user.IsActive = request.IsActive;
            user.SecurityVersion++;
            user.UpdatedAt = DateTime.UtcNow;
            await db.SaveChangesAsync(ct);
        }

        return Ok(ToDto(user, user.UserRoles.Select(userRole => userRole.Role.Name).ToList()));
    }

    private static ManagedUserDto ToDto(User user, List<string> roles) => new()
    {
        Id = user.Id,
        FullName = user.FullName,
        Email = user.Email,
        PhoneNumber = user.PhoneNumber,
        Roles = roles,
        IsActive = user.IsActive,
        CreatedAt = user.CreatedAt
    };
}
