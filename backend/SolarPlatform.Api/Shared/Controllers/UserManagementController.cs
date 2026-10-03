using System.Security.Claims;
using System.Text.RegularExpressions;
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
            .Where(user => user.DeletedAt == null)
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
                EmailVerified = user.EmailVerifiedAt != null,
                MustChangePassword = user.MustChangePassword,
                CreatedAt = user.CreatedAt,
                Roles = user.UserRoles.Select(userRole => userRole.Role.Name).ToList()
            })
            .ToListAsync(ct);

        return Ok(users);
    }

    [HttpPost]
    public async Task<ActionResult<ManagedUserDto>> Create(CreateManagedUserDto request, CancellationToken ct)
    {
        var fullName = request.FullName.Trim();
        if (!Regex.IsMatch(fullName, @"^[\p{L}][\p{L}\p{M} .'-]{1,99}$"))
            return BadRequest(new { message = "Enter a valid full name using 2–100 letters, spaces, apostrophes or hyphens." });

        var roleName = request.Role.Trim().ToUpperInvariant();
        if (!AssignableRoles.Contains(roleName))
            return BadRequest(new { message = "Select a staff role that can be assigned by an administrator." });

        var email = request.Email.Trim().ToLowerInvariant();
        if (email.Length > 254)
            return BadRequest(new { message = "Enter a valid email address up to 254 characters." });
        if (await db.Users.AnyAsync(user => user.Email == email, ct))
            return Conflict(new { message = "A user with this email already exists." });

        if (!PasswordPolicy.IsValid(request.Password))
            return BadRequest(new { message = PasswordPolicy.ErrorMessage });

        var phone = NormalizePhone(request.PhoneNumber);
        if (!string.IsNullOrWhiteSpace(request.PhoneNumber) && phone is null)
            return BadRequest(new { message = "Enter a valid phone number with 7–15 digits, such as +94 77 123 4567." });

        var role = await db.Roles.SingleOrDefaultAsync(item => item.Name == roleName, ct);
        if (role is null)
            return BadRequest(new { message = "The selected role is not available." });

        var now = DateTime.UtcNow;
        var user = new User
        {
            Id = Guid.NewGuid(),
            FullName = fullName,
            Email = email,
            PhoneNumber = phone,
            PasswordHash = passwordHasher.HashPassword(request.Password),
            IsActive = true,
            MustChangePassword = true,
            EmailVerifiedAt = null,
            CreatedAt = now,
            UpdatedAt = now,
            UserRoles = [new UserRole { RoleId = role.Id }]
        };

        db.Users.Add(user);
        await db.SaveChangesAsync(ct);

        return CreatedAtAction(nameof(List), new { id = user.Id }, ToDto(user, [roleName]));
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    {
        var currentUserIdValue = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!Guid.TryParse(currentUserIdValue, out var currentUserId)) return Unauthorized();
        if (currentUserId == id)
            return BadRequest(new { message = "You cannot delete your own administrator account." });

        var user = await db.Users.Include(item => item.UserRoles).ThenInclude(userRole => userRole.Role)
            .SingleOrDefaultAsync(item => item.Id == id && item.DeletedAt == null, ct);
        if (user is null) return NotFound(new { message = "User not found." });

        if (user.UserRoles.Any(userRole => userRole.Role.Name == RoleConstants.Administrator))
        {
            var activeAdministratorCount = await db.UserRoles.CountAsync(userRole =>
                userRole.Role.Name == RoleConstants.Administrator && userRole.User.IsActive && userRole.User.DeletedAt == null, ct);
            if (activeAdministratorCount <= 1)
                return BadRequest(new { message = "The final active administrator cannot be deleted." });
        }

        user.IsActive = false;
        user.DeletedAt = DateTime.UtcNow;
        user.DeletedByUserId = currentUserId;
        user.SecurityVersion++;
        user.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return NoContent();
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
            .SingleOrDefaultAsync(item => item.Id == id && item.DeletedAt == null, ct);

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
        EmailVerified = user.EmailVerifiedAt != null,
        MustChangePassword = user.MustChangePassword,
        CreatedAt = user.CreatedAt
    };

    private static string? NormalizePhone(string? value)
    {
        if (string.IsNullOrWhiteSpace(value)) return null;
        var trimmed = value.Trim();
        if (!Regex.IsMatch(trimmed, @"^\+?[0-9() .-]+$")) return null;
        var digits = Regex.Replace(trimmed, @"\D", "");
        if (digits.Length is < 7 or > 15) return null;
        return trimmed.StartsWith('+') ? $"+{digits}" : digits;
    }
}
