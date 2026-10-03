using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Services;

namespace SolarPlatform.Api.Controllers;

[ApiController, Authorize(Roles = "HOMEOWNER")]
[Route("api/customer")]
public class CustomerController : ControllerBase
{
    private readonly ISurveyService _service;
    public CustomerController(ISurveyService service) => _service = service;

    [HttpGet("profile")]
    public async Task<IActionResult> GetProfile() => Ok(await _service.GetProfileAsync(UserId()));

    [HttpPut("profile")]
    public async Task<IActionResult> UpdateProfile(UpdateProfileRequestDto request)
    {
        if (!ModelState.IsValid) return ValidationProblem(ModelState);
        return Ok(await _service.UpdateProfileAsync(UserId(), request));
    }

    private Guid UserId() => Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub"), out var id) ? id : throw new UnauthorizedAccessException("Invalid token user identity.");
}
