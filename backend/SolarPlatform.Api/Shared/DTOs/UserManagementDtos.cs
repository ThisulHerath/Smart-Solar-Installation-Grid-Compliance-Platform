using System.ComponentModel.DataAnnotations;

namespace SolarPlatform.Api.DTOs;

public class ManagedUserDto
{
    public Guid Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public List<string> Roles { get; set; } = new();
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class CreateManagedUserDto
{
    [Required, StringLength(255)]
    public string FullName { get; set; } = string.Empty;

    [Required, EmailAddress, StringLength(255)]
    public string Email { get; set; } = string.Empty;

    [Required, MinLength(8)]
    public string Password { get; set; } = string.Empty;

    [StringLength(50)]
    public string? PhoneNumber { get; set; }

    [Required]
    public string Role { get; set; } = string.Empty;
}

public class UpdateManagedUserStatusDto
{
    public bool IsActive { get; set; }
}
