using System.Text.Json;
using System.Text.Json.Serialization;

namespace SolarPlatform.Api.DTOs;

public class SolarSizingResponseDto
{
    [JsonPropertyName("workflow_id")] public string WorkflowId { get; set; } = string.Empty;
    [JsonPropertyName("status")] public string Status { get; set; } = string.Empty;
    [JsonPropertyName("plan")] public List<string> Plan { get; set; } = new();
    [JsonPropertyName("recommendation")] public JsonElement? Recommendation { get; set; }
    [JsonPropertyName("validation_results")] public JsonElement? ValidationResults { get; set; }
    [JsonPropertyName("errors")] public List<string> Errors { get; set; } = new();
    [JsonPropertyName("execution_logs")] public List<AgentExecutionLogDto> ExecutionLogs { get; set; } = new();
}

public class AgentExecutionLogDto
{
    [JsonPropertyName("agent_name")] public string AgentName { get; set; } = string.Empty;
    [JsonPropertyName("step_name")] public string StepName { get; set; } = string.Empty;
    [JsonPropertyName("status")] public string Status { get; set; } = string.Empty;
    [JsonPropertyName("output_summary")] public string? OutputSummary { get; set; }
    [JsonPropertyName("validation_result")] public JsonElement? ValidationResult { get; set; }
    [JsonPropertyName("error_message")] public string? ErrorMessage { get; set; }
    [JsonPropertyName("started_at")] public DateTime? StartedAt { get; set; }
    [JsonPropertyName("completed_at")] public DateTime? CompletedAt { get; set; }
    [JsonPropertyName("retry_count")] public int RetryCount { get; set; }
}
