using System.Text.Json.Serialization;

namespace SolarPlatform.Api.DTOs;

// ─── Response DTOs ────────────────────────────────────────────────────────────

public record ApprovalAuditLogDto(
    Guid Id,
    string Decision,
    string? Comment,
    Guid UserId,
    string? WorkflowId,
    DateTime Timestamp
);

public record ProposalLifecycleAuditEventDto(
    Guid Id,
    string Event,
    string? Details,
    string? WorkflowId,
    DateTime Timestamp
);

public record EngineeringProposalSummaryDto(
    Guid Id,
    Guid SolarSurveyId,
    string? WorkflowId,
    decimal RecommendedKw,
    int PanelCount,
    decimal InverterSizeKw,
    decimal EstimatedCostLkr,
    string GridComplianceStatus,
    string RiskLevel,
    string SafetyStatus,
    string ProposalStatus,
    bool RequiresApproval,
    DateTime CreatedAt,
    DateTime UpdatedAt
);

public record EngineeringProposalDto(
    Guid Id,
    Guid SolarSurveyId,
    string? WorkflowId,
    decimal RecommendedKw,
    int PanelCount,
    decimal InverterSizeKw,
    decimal EstimatedCostLkr,
    string GridComplianceStatus,
    string RiskLevel,
    string SafetyStatus,
    string ProposalStatus,
    bool RequiresApproval,
    string? RecommendationSummary,
    string? EngineerNotes,
    string? GuardrailResultJson,
    string? ValidationResultJson,
    DateTime CreatedAt,
    DateTime UpdatedAt,
    List<ApprovalAuditLogDto> AuditLogs,
    List<ProposalLifecycleAuditEventDto> LifecycleEvents,
    // Customer/survey summary fields
    string? CustomerName,
    string? PropertyAddress
);

// ─── Request DTOs ─────────────────────────────────────────────────────────────

public record CreateProposalRequestDto(
    Guid SolarSurveyId,
    string? Notes = null
);

public record ApproveProposalRequestDto(
    string? Comment = null
);

public record RejectProposalRequestDto(
    string Comment  // Required for rejection
);

public record ReviseProposalRequestDto(
    string Comment  // Required for revision request
);

// ─── Validation Result ────────────────────────────────────────────────────────

public record ProposalValidationResultDto(
    [property: JsonPropertyName("valid")] bool Valid,
    [property: JsonPropertyName("requiresApproval")] bool RequiresApproval,
    [property: JsonPropertyName("checks")] List<string> Checks,
    [property: JsonPropertyName("violations")] List<string> Violations,
    [property: JsonPropertyName("overrideReason")] string OverrideReason
);
