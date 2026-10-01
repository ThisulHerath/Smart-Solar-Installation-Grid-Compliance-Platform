namespace SolarPlatform.Api.Models;

public class SitePhoto
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid SiteInspectionId { get; set; }
    public SitePhotoType PhotoType { get; set; }
    public string FileUrl { get; set; } = string.Empty;
    public string FileName { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation
    public SiteInspection SiteInspection { get; set; } = null!;
}
