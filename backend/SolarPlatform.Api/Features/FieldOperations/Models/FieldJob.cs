namespace SolarPlatform.Api.Models;

public class FieldJob
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid SolarSurveyId { get; set; }
    public Guid TechnicianId { get; set; }
    public DateTime AssignedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ScheduledAt { get; set; }
    public FieldJobStatus Status { get; set; } = FieldJobStatus.Assigned;
    public FieldJobPriority Priority { get; set; } = FieldJobPriority.Medium;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public SolarSurvey SolarSurvey { get; set; } = null!;
    public User Technician { get; set; } = null!;
    public SiteInspection? Inspection { get; set; }
}
