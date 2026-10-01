using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using SolarPlatform.Api.Controllers;
using SolarPlatform.Api.Models;
using System.Reflection;

namespace SolarPlatform.Tests;

public class AuthorizationEndpointTests
{
    [Fact]
    public void AdminController_ReturnsSuccess_ForAdminIdentity()
    {
        var controller = new AdminController();
        var user = new ClaimsPrincipal(new ClaimsIdentity(new[]
        {
            new Claim(ClaimTypes.Name, "Admin User"),
            new Claim(ClaimTypes.Role, RoleConstants.Administrator)
        }, "TestAuth"));

        controller.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext { User = user }
        };

        var result = controller.GetAdminTest();

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);
    }

    [Fact]
    public void EngineerController_ReturnsSuccess_ForEngineerIdentity()
    {
        var controller = new EngineerController();
        var user = new ClaimsPrincipal(new ClaimsIdentity(new[]
        {
            new Claim(ClaimTypes.Name, "Engineer User"),
            new Claim(ClaimTypes.Role, RoleConstants.SeniorEngineer)
        }, "TestAuth"));

        controller.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext { User = user }
        };

        var result = controller.GetEngineerTest();

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);
    }

    [Fact]
    public void ProposalDecisionEndpoints_AllowEngineerAndAdministratorRoles()
    {
        var methods = typeof(ProposalsController).GetMethods(BindingFlags.Public | BindingFlags.Instance);
        foreach (var methodName in new[] { "Approve", "Reject", "Revise" })
        {
            var method = methods.Single(m => m.Name == methodName);
            var authorize = method.GetCustomAttributes<Microsoft.AspNetCore.Authorization.AuthorizeAttribute>().Single();
            Assert.Contains(RoleConstants.SeniorEngineer, authorize.Roles);
            Assert.Contains(RoleConstants.Administrator, authorize.Roles);
        }
    }
}
