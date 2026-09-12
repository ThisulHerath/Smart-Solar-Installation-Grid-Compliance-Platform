using System.ComponentModel.DataAnnotations;

namespace SolarPlatform.Api.DTOs;

public class VerifyEmailCodeDto
{
    [Required] public Guid ChallengeId { get; set; }
    [Required, RegularExpression("^[0-9]{6}$", ErrorMessage = "Enter the six-digit email code.")]
    public string Code { get; set; } = "";
}

public class ChangePasswordRequestDto
{
    [Required, StringLength(64, MinimumLength = 12)]
    public string NewPassword { get; set; } = "";
}

public record EmailChallengeResponse(Guid ChallengeId, string MaskedEmail, DateTime ExpiresAt, int ResendAfterSeconds = 60);
