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
    bool Valid,
    bool RequiresApproval,
    List<string> Checks,
    List<string> Violations,
    string OverrideReason
);
