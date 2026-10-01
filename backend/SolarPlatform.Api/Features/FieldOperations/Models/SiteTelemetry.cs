namespace SolarPlatform.Api.Models;

public class SiteTelemetry
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid SiteInspectionId { get; set; }
    public MeasurementType MeasurementType { get; set; }
    public decimal MeasurementValue { get; set; }
    public string Unit { get; set; } = string.Empty;
    public DateTime RecordedAt { get; set; } = DateTime.UtcNow;

    // Navigation
    public SiteInspection SiteInspection { get; set; } = null!;
}
