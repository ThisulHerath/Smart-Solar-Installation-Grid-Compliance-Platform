using System.Text;

namespace SolarPlatform.Api.Authentication;

public static class PasswordPolicy
{
    public const string ErrorMessage = "Use 12–64 characters with uppercase, lowercase, number and symbol.";

    public static bool IsValid(string? password) =>
        !string.IsNullOrWhiteSpace(password) &&
        password.Length is >= 12 and <= 64 &&
        Encoding.UTF8.GetByteCount(password) <= 72 &&
        password.Any(char.IsUpper) &&
        password.Any(char.IsLower) &&
        password.Any(char.IsDigit) &&
        password.Any(character => !char.IsLetterOrDigit(character));

    public static void Validate(string? password)
    {
        if (!IsValid(password)) throw new ArgumentException(ErrorMessage);
    }
}
