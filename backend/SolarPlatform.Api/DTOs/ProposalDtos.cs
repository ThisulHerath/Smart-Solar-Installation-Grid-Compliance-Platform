using System.Text.Json.Serialization;

namespace SolarPlatform.Api.DTOs;

// ─── Response DTOs ────────────────────────────────────────────────────────────

public record ApprovalAuditLogDto(
    Guid Id,

    // String form of ApprovalDecision (Approved / Rejected / RevisionRequested).
    string Decision,
    string? Comment,
    Guid UserId,
    string? WorkflowId,
    DateTime Timestamp
);

public record ProposalLifecycleAuditEventDto(
    Guid Id,
    string Event,

    // Optional free-text context for this event, e.g. the comment that accompanied a revision request.
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

    // Preliminary estimate only; see EquipmentQuote for the live-priced figure once pricing has run.
    decimal EstimatedCostLkr,
    string GridComplianceStatus,
    string RiskLevel,
    string SafetyStatus,

    // String form of ProposalStatus.
    string ProposalStatus,
    bool RequiresApproval,
    DateTime CreatedAt,
    DateTime UpdatedAt,
    string? ProjectName,
    string? CustomerName
);

public record EngineeringProposalDto(
    Guid Id,
    Guid SolarSurveyId,
    string? WorkflowId,
    decimal RecommendedKw,
    int PanelCount,
    decimal InverterSizeKw,

    // Preliminary estimate only; see EquipmentQuote for the live-priced figure once pricing has run.
    decimal EstimatedCostLkr,
    string GridComplianceStatus,
    string RiskLevel,
    string SafetyStatus,

     // String form of ProposalStatus.
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
    string? ProjectName,
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

/// A DTO representing the result of proposal validation.
public record ProposalValidationResultDto(
    [property: JsonPropertyName("valid")] bool Valid,
    [property: JsonPropertyName("requiresApproval")] bool RequiresApproval,
    [property: JsonPropertyName("checks")] List<string> Checks,
    [property: JsonPropertyName("violations")] List<string> Violations,
    [property: JsonPropertyName("overrideReason")] string OverrideReason
);
