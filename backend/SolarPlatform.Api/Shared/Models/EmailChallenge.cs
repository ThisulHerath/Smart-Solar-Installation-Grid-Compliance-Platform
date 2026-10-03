namespace SolarPlatform.Api.Models;

public class EmailChallenge
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Email { get; set; } = "";
    public string Purpose { get; set; } = "";
    public Guid? UserId { get; set; }
    public int UserVersion { get; set; }
    public string CodeHash { get; set; } = "";
    public string? PasswordHash { get; set; }
    public string? FullName { get; set; }
    public string? PhoneNumber { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime ExpiresAt { get; set; }
    public DateTime? ConsumedAt { get; set; }
    public int Attempts { get; set; }
    public Guid Revision { get; set; } = Guid.NewGuid();
}
