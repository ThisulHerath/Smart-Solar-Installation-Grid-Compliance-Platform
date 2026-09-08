namespace SolarPlatform.Api.Models;

public class AgentExecutionLog
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid AgentWorkflowId { get; set; }
    public string AgentName { get; set; } = string.Empty;
    public string StepName { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime StartedAt { get; set; } = DateTime.UtcNow;
    public DateTime? CompletedAt { get; set; }
    public long? DurationMs { get; set; }
    public string? OutputSummary { get; set; }
    public string? ValidationResult { get; set; }
    public string? ErrorMessage { get; set; }
    public int RetryCount { get; set; }
    public AgentWorkflow AgentWorkflow { get; set; } = null!;
}
