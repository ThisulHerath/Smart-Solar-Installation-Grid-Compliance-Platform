using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SolarPlatform.Api.Models;

namespace SolarPlatform.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AdminController : ControllerBase
{
    [HttpGet("test")]
    [Authorize(Roles = RoleConstants.Administrator)]
    public IActionResult GetAdminTest()
    {
        return Ok(new
        {
            success = true,
            message = "Access granted to Administrator endpoint.",
            user = User.Identity?.Name,
            role = RoleConstants.Administrator,
            timestamp = DateTime.UtcNow
        });
    }
}
