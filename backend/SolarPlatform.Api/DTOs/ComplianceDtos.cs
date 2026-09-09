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
    string WorkflowId,
    bool GridCompliant,
    string ComplianceStatus,
    string RiskLevel,
    List<string> Violations,
    List<string> Recommendations,
    string ValidationStatus,
    string? Notes,
    List<ComplianceExecutionLogDto> ExecutionLogs
);

public record ComplianceExecutionLogDto(
    string AgentName,
    string StepName,
    string Status,
    string? OutputSummary,
    string? ErrorMessage,
    long DurationMs
);
