namespace SolarPlatform.Api.Models;

public class SiteInspection
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid FieldJobId { get; set; }

    // GPS Check-in
    public decimal? CheckInLatitude { get; set; }
    public decimal? CheckInLongitude { get; set; }
    public DateTime? CheckInAt { get; set; }

    // Roof measurements
    public decimal? RoofAreaMeasuredSqm { get; set; }
    public RoofOrientation RoofOrientation { get; set; } = RoofOrientation.Unknown;
    public decimal? RoofTilt { get; set; }

    // Electrical observations
    public GridType GridTypeObserved { get; set; } = GridType.Unknown;
    public int? PhaseCount { get; set; }
    public decimal? MainBreakerRating { get; set; }
    public bool? InverterLocationSuitable { get; set; }

    // Notes
    public string? SafetyNotes { get; set; }
    public string? TechnicianNotes { get; set; }

    public InspectionStatus InspectionStatus { get; set; } = InspectionStatus.Draft;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public FieldJob FieldJob { get; set; } = null!;
    public ICollection<SiteTelemetry> Telemetry { get; set; } = new List<SiteTelemetry>();
    public ICollection<SitePhoto> Photos { get; set; } = new List<SitePhoto>();
    public ComplianceAssessment? ComplianceAssessment { get; set; }
}
