namespace SolarPlatform.Api.Models;

public class ComplianceAssessment
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid SiteInspectionId { get; set; }
    public string? WorkflowId { get; set; }
    public bool GridCompliant { get; set; }
    public string ComplianceStatus { get; set; } = string.Empty;
    public string RiskLevel { get; set; } = string.Empty;
    public string? ComplianceNotes { get; set; }
    public string? ValidationStatus { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Navigation
    public SiteInspection SiteInspection { get; set; } = null!;
}
