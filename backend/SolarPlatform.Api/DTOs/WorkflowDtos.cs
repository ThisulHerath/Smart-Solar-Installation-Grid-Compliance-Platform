using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace SolarPlatform.Api.DTOs;

public class WorkflowTestRequestDto
{
    [Required]
    [JsonPropertyName("objective")]
    public string Objective { get; set; } = string.Empty;

    [JsonPropertyName("customerId")]
    public string? CustomerId { get; set; }

    [JsonPropertyName("inputData")]
    public Dictionary<string, object>? InputData { get; set; }
}

public class WorkflowTestResponseDto
{
    [JsonPropertyName("workflow_id")]
    public string WorkflowId { get; set; } = string.Empty;

    [JsonPropertyName("customer_id")]
    public string? CustomerId { get; set; }

    [JsonPropertyName("objective")]
    public string Objective { get; set; } = string.Empty;

    [JsonPropertyName("current_step")]
    public string CurrentStep { get; set; } = string.Empty;

    [JsonPropertyName("completed_steps")]
    public List<string> CompletedSteps { get; set; } = new();

    [JsonPropertyName("approval_status")]
    public string ApprovalStatus { get; set; } = string.Empty;

    [JsonPropertyName("final_outcome")]
    public string FinalOutcome { get; set; } = string.Empty;

    [JsonPropertyName("plan")]
    public List<string> Plan { get; set; } = new();

    [JsonPropertyName("execution_logs")]
    public List<string> ExecutionLogs { get; set; } = new();

    [JsonPropertyName("errors")]
    public List<string> Errors { get; set; } = new();

    [JsonPropertyName("tool_results")]
    public Dictionary<string, object> ToolResults { get; set; } = new();

    [JsonPropertyName("validation_results")]
    public Dictionary<string, object> ValidationResults { get; set; } = new();
}
