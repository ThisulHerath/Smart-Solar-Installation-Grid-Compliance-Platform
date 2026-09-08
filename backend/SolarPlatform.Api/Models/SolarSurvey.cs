namespace SolarPlatform.Api.Models;

public class SolarSurvey
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid CustomerId { get; set; }
    public decimal MonthlyKwh { get; set; }
    public decimal RoofAreaSqm { get; set; }
    public GridType GridType { get; set; }
    public RoofOrientation RoofOrientation { get; set; } = RoofOrientation.Unknown;
    public decimal? RoofTilt { get; set; }
    public string PropertyAddress { get; set; } = string.Empty;
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
    public SurveyStatus SurveyStatus { get; set; } = SurveyStatus.Draft;
    public string? Notes { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public CustomerProfile Customer { get; set; } = null!;
    public ICollection<SolarSurveyImage> Images { get; set; } = new List<SolarSurveyImage>();
    public ICollection<AgentWorkflow> Workflows { get; set; } = new List<AgentWorkflow>();
}
