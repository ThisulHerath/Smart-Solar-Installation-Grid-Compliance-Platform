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
    [property: JsonPropertyName("inspection_id")] Guid InspectionId,
    [property: JsonPropertyName("field_job_id")] Guid FieldJobId,
    [property: JsonPropertyName("grid_type")] string GridType,
    [property: JsonPropertyName("phase_count")] int? PhaseCount,
    [property: JsonPropertyName("main_breaker_rating")] decimal? MainBreakerRating,
    [property: JsonPropertyName("inverter_location_suitable")] bool? InverterLocationSuitable,
    [property: JsonPropertyName("roof_area_sqm")] decimal? RoofAreaSqm,
    [property: JsonPropertyName("roof_tilt")] decimal? RoofTilt,
    [property: JsonPropertyName("roof_orientation")] string? RoofOrientation,
    [property: JsonPropertyName("voc")] decimal? Voc,
    [property: JsonPropertyName("isc")] decimal? Isc,
    [property: JsonPropertyName("vmp")] decimal? Vmp,
    [property: JsonPropertyName("imp")] decimal? Imp,
    [property: JsonPropertyName("irradiance")] decimal? Irradiance,
    [property: JsonPropertyName("temperature")] decimal? Temperature,
    [property: JsonPropertyName("grid_voltage")] decimal? GridVoltage,
    [property: JsonPropertyName("grid_frequency")] decimal? GridFrequency,
    [property: JsonPropertyName("safety_notes")] string? SafetyNotes,
    [property: JsonPropertyName("technician_notes")] string? TechnicianNotes
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
