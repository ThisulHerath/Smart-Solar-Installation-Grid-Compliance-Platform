using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using SolarPlatform.Api.Data;
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
    private readonly AppDbContext _db;
    private readonly IFileStorageService _fileStorage;

    public AuthController(IAuthService authService, ILogger<AuthController> logger, EmailVerificationService verification, AppDbContext db, IFileStorageService fileStorage)
    {
        _authService = authService;
        _logger = logger;
        _verification = verification;
        _db = db;
        _fileStorage = fileStorage;
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

    [HttpPost("password/reset/request-otp")]
    public async Task<IActionResult> RequestPasswordReset(ForgotPasswordRequestDto request)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var challenge = await _verification.RequestPasswordResetAsync(request);
        return Ok(new
        {
            challenge,
            message = "If an active account uses that email address, we sent a verification code."
        });
    }

    [HttpPost("password/reset/confirm")]
    public async Task<IActionResult> ConfirmPasswordReset(VerifyEmailCodeDto request)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        await _verification.ConfirmPasswordResetAsync(request);
        return Ok(new { message = "Password reset. You can now sign in with your new password." });
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

    [Authorize, HttpPost("profile-image")]
    [RequestSizeLimit(5 * 1024 * 1024)]
    public async Task<IActionResult> UploadProfileImage(IFormFile file, CancellationToken cancellationToken)
    {
        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (file.Length <= 0 || file.Length > 5 * 1024 * 1024 || extension is not ".jpg" and not ".jpeg" and not ".png" and not ".webp")
            return BadRequest(new { message = "Choose a JPG, PNG or WebP image up to 5 MB." });

        var user = await _db.Users.SingleAsync(u => u.Id == CurrentUserId, cancellationToken);
        await using var stream = file.OpenReadStream();
        var imageUrl = await _fileStorage.SaveFileAsync(stream, file.FileName, $"profile-images/{user.Id:N}", cancellationToken);
        var oldUrl = user.ProfileImageUrl;
        user.ProfileImageUrl = imageUrl;
        user.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);
        if (!string.IsNullOrWhiteSpace(oldUrl)) await _fileStorage.DeleteFileAsync(oldUrl, cancellationToken);
        return Ok(new { profileImageUrl = imageUrl });
    }

    [Authorize, HttpDelete("profile-image")]
    public async Task<IActionResult> DeleteProfileImage(CancellationToken cancellationToken)
    {
        var user = await _db.Users.SingleAsync(u => u.Id == CurrentUserId, cancellationToken);
        if (string.IsNullOrWhiteSpace(user.ProfileImageUrl)) return NoContent();
        var oldUrl = user.ProfileImageUrl;
        if (!await _fileStorage.DeleteFileAsync(oldUrl, cancellationToken))
            return StatusCode(StatusCodes.Status500InternalServerError, new { message = "Unable to remove the profile image. Please try again." });
        user.ProfileImageUrl = null;
        user.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);
        return NoContent();
    }
}
