namespace SolarPlatform.Api.Models;

public class AgentWorkflow
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string WorkflowId { get; set; } = Guid.NewGuid().ToString();
    public Guid SolarSurveyId { get; set; }
    public string Objective { get; set; } = string.Empty;
    public WorkflowStatus Status { get; set; } = WorkflowStatus.Pending;
    public string? PlanJson { get; set; }
    public string? ResultJson { get; set; }
    public string? ValidationJson { get; set; }
    public string? ErrorMessage { get; set; }
    public DateTime? StartedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public SolarSurvey SolarSurvey { get; set; } = null!;
}
