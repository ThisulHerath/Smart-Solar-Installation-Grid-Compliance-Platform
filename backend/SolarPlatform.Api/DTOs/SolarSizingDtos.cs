using System.Text.Json;
using System.Text.Json.Serialization;

namespace SolarPlatform.Api.DTOs;

public class SolarSizingResponseDto
{
    [JsonPropertyName("workflow_id")] public string WorkflowId { get; set; } = string.Empty;
    [JsonPropertyName("status")] public string Status { get; set; } = string.Empty;
    [JsonPropertyName("recommendation")] public JsonElement? Recommendation { get; set; }
    [JsonPropertyName("validation_results")] public JsonElement? ValidationResults { get; set; }
    [JsonPropertyName("errors")] public List<string> Errors { get; set; } = new();
}
