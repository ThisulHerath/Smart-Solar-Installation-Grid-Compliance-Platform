using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Services;

namespace SolarPlatform.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[EnableRateLimiting("auth")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly ILogger<AuthController> _logger;
    private readonly EmailVerificationService _verification;

    public AuthController(IAuthService authService, ILogger<AuthController> logger, EmailVerificationService verification)
    {
        _authService = authService;
        _logger = logger;
        _verification = verification;
    }

    [HttpPost("register")]
    [ProducesResponseType(typeof(AuthResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Register([FromBody] VerifyEmailCodeDto request)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var result = await _verification.VerifyRegistrationAsync(request);
        return Ok(result);
    }

    [HttpPost("register/request-otp")]
    public async Task<IActionResult> RequestRegistration(RegisterRequestDto request) => Ok(await _verification.RequestRegistrationAsync(request));

    private Guid CurrentUserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    [Authorize, HttpPost("password/request-otp")]
    public async Task<IActionResult> RequestPassword(ChangePasswordRequestDto request) =>
        Ok(await _verification.RequestAccountActionAsync(CurrentUserId, EmailVerificationService.PasswordChange, request.NewPassword));

    [Authorize, HttpPost("password/confirm")]
    public async Task<IActionResult> ConfirmPassword(VerifyEmailCodeDto request)
    {
        await _verification.ConfirmAccountActionAsync(CurrentUserId, EmailVerificationService.PasswordChange, request);
        return Ok(new { message = "Password changed. Please sign in with your new password." });
    }

    [Authorize, HttpPost("account-deletion/request-otp")]
    public async Task<IActionResult> RequestDeletion() =>
        Ok(await _verification.RequestAccountActionAsync(CurrentUserId, EmailVerificationService.Deletion));

    [Authorize, HttpPost("account-deletion/confirm")]
    public async Task<IActionResult> ConfirmDeletion(VerifyEmailCodeDto request)
    {
        await _verification.ConfirmAccountActionAsync(CurrentUserId, EmailVerificationService.Deletion, request);
        return Ok(new { message = "Your account has been deleted." });
    }

    [HttpPost("login")]
    [ProducesResponseType(typeof(AuthResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Login([FromBody] LoginRequestDto request)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var result = await _authService.LoginAsync(request);
        return Ok(result);
    }

    [HttpGet("me")]
    [Authorize]
    [ProducesResponseType(typeof(UserDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetCurrentUser()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value 
            ?? User.FindFirst("sub")?.Value;

        if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var userId))
        {
            return Unauthorized(new { message = "Invalid token user identity." });
        }

        var user = await _authService.GetCurrentUserAsync(userId);
        if (user == null)
        {
            return NotFound(new { message = "User not found." });
        }

        return Ok(user);
    }
}
