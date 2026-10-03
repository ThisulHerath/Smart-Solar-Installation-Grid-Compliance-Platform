using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SolarPlatform.Api.Authentication;
using SolarPlatform.Api.Controllers;
using SolarPlatform.Api.Data;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Models;

namespace SolarPlatform.Tests;

public class UserManagementControllerTests
{
    private static (AppDbContext Db, UserManagementController Controller) CreateController(Guid administratorId)
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        var db = new AppDbContext(options);
        var controller = new UserManagementController(db, new PasswordHasher())
        {
            ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext
                {
                    User = new ClaimsPrincipal(new ClaimsIdentity(
                    [new Claim(ClaimTypes.NameIdentifier, administratorId.ToString())], "test"))
                }
            }
        };
        return (db, controller);
    }

    [Fact]
    public async Task Create_ValidStaffMember_RequiresFirstLoginSetup()
    {
        var administratorId = Guid.NewGuid();
        var (db, controller) = CreateController(administratorId);
        db.Roles.Add(new Role { Name = RoleConstants.SeniorEngineer });
        await db.SaveChangesAsync();

        var result = await controller.Create(new CreateManagedUserDto
        {
            FullName = "Nimal Perera",
            Email = "NIMAL@SMARTSOLAR.LK",
            PhoneNumber = "+94 77 123 4567",
            Password = "TemporaryPass!123",
            Role = RoleConstants.SeniorEngineer
        }, CancellationToken.None);

        var created = Assert.IsType<CreatedAtActionResult>(result.Result);
        var dto = Assert.IsType<ManagedUserDto>(created.Value);
        Assert.True(dto.MustChangePassword);
        Assert.False(dto.EmailVerified);
        Assert.Equal("nimal@smartsolar.lk", dto.Email);
        var stored = await db.Users.SingleAsync();
        Assert.True(stored.MustChangePassword);
        Assert.Null(stored.EmailVerifiedAt);
    }

    [Fact]
    public async Task Delete_SoftDeletesStaffAndRevokesExistingSessions()
    {
        var administratorId = Guid.NewGuid();
        var target = new User { FullName = "Staff Member", Email = "staff@example.invalid", PasswordHash = "hash", SecurityVersion = 3 };
        var (db, controller) = CreateController(administratorId);
        db.Users.Add(target);
        await db.SaveChangesAsync();

        var result = await controller.Delete(target.Id, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
        Assert.False(target.IsActive);
        Assert.NotNull(target.DeletedAt);
        Assert.Equal(administratorId, target.DeletedByUserId);
        Assert.Equal(4, target.SecurityVersion);
    }

    [Fact]
    public async Task Delete_FinalAdministrator_IsRejected()
    {
        var currentAdministratorId = Guid.NewGuid();
        var target = new User { FullName = "Only Administrator", Email = "admin@example.invalid", PasswordHash = "hash" };
        var role = new Role { Name = RoleConstants.Administrator };
        target.UserRoles.Add(new UserRole { UserId = target.Id, RoleId = role.Id, Role = role, User = target });
        var (db, controller) = CreateController(currentAdministratorId);
        db.Roles.Add(role);
        db.Users.Add(target);
        await db.SaveChangesAsync();

        var result = await controller.Delete(target.Id, CancellationToken.None);

        var badRequest = Assert.IsType<BadRequestObjectResult>(result);
        Assert.Contains("final active administrator", badRequest.Value!.ToString(), StringComparison.OrdinalIgnoreCase);
        Assert.True(target.IsActive);
        Assert.Null(target.DeletedAt);
    }
}
