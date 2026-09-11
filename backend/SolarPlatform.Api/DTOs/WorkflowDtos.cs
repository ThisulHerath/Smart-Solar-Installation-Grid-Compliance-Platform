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

/// <summary>
/// Structured output from the SafetyGuardrailAgent.
/// Never trusted as the final approval decision — deterministic validation runs after this.
/// </summary>
public class GuardrailResultDto
{
    [JsonPropertyName("safety_status")]
    public string SafetyStatus { get; set; } = "REQUIRES_APPROVAL";

    [JsonPropertyName("risk_level")]
    public string RiskLevel { get; set; } = "HIGH";

    [JsonPropertyName("requires_approval")]
    public bool RequiresApproval { get; set; } = true;

    [JsonPropertyName("issues")]
    public List<string> Issues { get; set; } = new();

    [JsonPropertyName("recommendations")]
    public List<string> Recommendations { get; set; } = new();

    [JsonPropertyName("recommendation_summary")]
    public string? RecommendationSummary { get; set; }

    [JsonPropertyName("workflow_id")]
    public string? WorkflowId { get; set; }

    [JsonPropertyName("execution_logs")]
    public List<Dictionary<string, object>> ExecutionLogs { get; set; } = new();

    /// <summary>Fail-safe default — always requires approval when AI is unavailable.</summary>
    public static GuardrailResultDto SafeDefault() => new()
    {
        SafetyStatus = "REQUIRES_APPROVAL",
        RiskLevel = "HIGH",
        RequiresApproval = true,
        Issues = new List<string> { "Safety guardrail evaluation unavailable — approval required by default." },
        Recommendations = new List<string> { "Retry after AI service is restored." },
        RecommendationSummary = "AI guardrail could not be evaluated. Manual review required."
    };
}
