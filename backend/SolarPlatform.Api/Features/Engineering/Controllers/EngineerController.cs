using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SolarPlatform.Api.Models;

namespace SolarPlatform.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class EngineerController : ControllerBase
{
    [HttpGet("test")]
    [Authorize(Roles = RoleConstants.SeniorEngineer)]
    public IActionResult GetEngineerTest()
    {
        return Ok(new
        {
            success = true,
            message = "Access granted to Senior Engineer endpoint.",
            user = User.Identity?.Name,
            role = RoleConstants.SeniorEngineer,
            timestamp = DateTime.UtcNow
        });
    }
}
