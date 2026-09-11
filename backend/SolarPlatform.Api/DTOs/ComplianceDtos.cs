using System.Text.Json.Serialization;

namespace SolarPlatform.Api.DTOs;

public record ComplianceAssessmentDto(
    Guid Id,
    Guid SiteInspectionId,
    string? WorkflowId,
    bool GridCompliant,
    string ComplianceStatus,
    string RiskLevel,
    string? ComplianceNotes,
    string? ValidationStatus,
    DateTime CreatedAt,
    DateTime UpdatedAt,
    List<string>? Violations = null,
    List<string>? Recommendations = null
);

public record EvaluateComplianceRequestDto(
    Guid InspectionId,
    Guid FieldJobId,
    string GridType,
    int? PhaseCount,
    decimal? MainBreakerRating,
    bool? InverterLocationSuitable,
    decimal? RoofAreaSqm,
    decimal? RoofTilt,
    string? RoofOrientation,
    decimal? Voc,
    decimal? Isc,
    decimal? Vmp,
    decimal? Imp,
    decimal? Irradiance,
    decimal? Temperature,
    decimal? GridVoltage,
    decimal? GridFrequency,
    string? SafetyNotes,
    string? TechnicianNotes
);

public record EvaluateComplianceResponseDto(
    [property: JsonPropertyName("workflow_id")] string WorkflowId,
    [property: JsonPropertyName("grid_compliant")] bool GridCompliant,
    [property: JsonPropertyName("compliance_status")] string ComplianceStatus,
    [property: JsonPropertyName("risk_level")] string RiskLevel,
    [property: JsonPropertyName("violations")] List<string> Violations,
    [property: JsonPropertyName("recommendations")] List<string> Recommendations,
    [property: JsonPropertyName("validation_status")] string ValidationStatus,
    [property: JsonPropertyName("notes")] string? Notes,
    [property: JsonPropertyName("execution_logs")] List<ComplianceExecutionLogDto> ExecutionLogs
);

public record ComplianceExecutionLogDto(
    [property: JsonPropertyName("agent_name")] string AgentName,
    [property: JsonPropertyName("step_name")] string StepName,
    [property: JsonPropertyName("status")] string Status,
    [property: JsonPropertyName("output_summary")] string? OutputSummary,
    [property: JsonPropertyName("error_message")] string? ErrorMessage,
    [property: JsonPropertyName("duration_ms")] long DurationMs
);
