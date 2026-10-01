using System.ComponentModel.DataAnnotations;
using System.Text.Json;
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

public class StructuredWorkflowStartDto
{
    [Required]
    public Guid SurveyId { get; set; }

    [Required, StringLength(500, MinimumLength = 3)]
    public string Objective { get; set; } = "Prepare an approved rooftop solar installation plan";
}

public class StructuredWorkflowResumeDto
{
    [Required]
    public string Event { get; set; } = string.Empty;

    public Dictionary<string, object> EventData { get; set; } = new();
}

public class StructuredWorkflowResultDto
{
    [JsonPropertyName("workflow_id")]
    public string WorkflowId { get; set; } = string.Empty;

    [JsonPropertyName("customer_id")]
    public string? CustomerId { get; set; }

    [JsonPropertyName("objective")]
    public string Objective { get; set; } = string.Empty;

    [JsonPropertyName("workflow_type")]
    public string? WorkflowType { get; set; }

    [JsonPropertyName("workflow_status")]
    public string WorkflowStatus { get; set; } = "FAILED";

    [JsonPropertyName("current_step_id")]
    public string CurrentStepId { get; set; } = "planning";

    [JsonPropertyName("approval_status")]
    public string ApprovalStatus { get; set; } = "NOT_REQUESTED";

    [JsonPropertyName("plan")]
    public List<string> Plan { get; set; } = new();

    [JsonPropertyName("structured_plan")]
    public JsonElement? StructuredPlan { get; set; }

    [JsonPropertyName("input_data")]
    public JsonElement? InputData { get; set; }

    [JsonPropertyName("completed_steps")]
    public List<string> CompletedSteps { get; set; } = new();

    [JsonPropertyName("failed_steps")]
    public List<string> FailedSteps { get; set; } = new();

    [JsonPropertyName("agent_outputs")]
    public JsonElement? AgentOutputs { get; set; }

    [JsonPropertyName("tool_results")]
    public JsonElement? ToolResults { get; set; }

    [JsonPropertyName("validation_results")]
    public JsonElement? ValidationResults { get; set; }

    [JsonPropertyName("execution_logs")]
    public List<Dictionary<string, JsonElement>> ExecutionLogs { get; set; } = new();

    [JsonPropertyName("errors")]
    public JsonElement? Errors { get; set; }

    [JsonPropertyName("retry_count")]
    public int RetryCount { get; set; }

    [JsonPropertyName("final_outcome")]
    public string FinalOutcome { get; set; } = string.Empty;
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

}
