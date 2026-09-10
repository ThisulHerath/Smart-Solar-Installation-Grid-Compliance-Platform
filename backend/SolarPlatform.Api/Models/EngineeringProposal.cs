namespace SolarPlatform.Api.Models;

/// <summary>
/// Formal engineering proposal generated from a completed SolarSurvey + SiteInspection + ComplianceAssessment.
/// Progresses through an approval state machine requiring Senior Engineer sign-off for high-impact installations.
/// </summary>
public class EngineeringProposal
{
    public Guid Id { get; set; } = Guid.NewGuid();

    /// <summary>The solar survey this proposal is based on.</summary>
    public Guid SolarSurveyId { get; set; }

    /// <summary>Reference to the agentic workflow that generated this proposal.</summary>
    public string? WorkflowId { get; set; }

    // ── Technical Specifications ───────────────────────────────────────────────
    public decimal RecommendedKw { get; set; }
    public int PanelCount { get; set; }
    public decimal InverterSizeKw { get; set; }
    public decimal EstimatedCostLkr { get; set; }

    // ── Compliance & Safety ────────────────────────────────────────────────────
    /// <summary>Mirrors ComplianceAssessment.ComplianceStatus (COMPLIANT / NON_COMPLIANT / CONDITIONAL).</summary>
    public string GridComplianceStatus { get; set; } = string.Empty;
    public string RiskLevel { get; set; } = string.Empty;
    /// <summary>Safety verdict from SafetyGuardrailAgent (SAFE / REQUIRES_APPROVAL / BLOCKED).</summary>
    public string SafetyStatus { get; set; } = string.Empty;

    // ── Approval State ─────────────────────────────────────────────────────────
    public ProposalStatus ProposalStatus { get; set; } = ProposalStatus.Draft;

    // ── Summaries ──────────────────────────────────────────────────────────────
    public string? RecommendationSummary { get; set; }
    public string? EngineerNotes { get; set; }

    /// <summary>Raw JSON from SafetyGuardrailAgent (issues, recommendations).</summary>
    public string? GuardrailResultJson { get; set; }

    /// <summary>Raw JSON from DeterministicProposalValidator.</summary>
    public string? ValidationResultJson { get; set; }

    /// <summary>True when deterministic rules require approval (kW > 10 or non-compliant).</summary>
    public bool RequiresApproval { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // ── Navigation Properties ──────────────────────────────────────────────────
    public SolarSurvey SolarSurvey { get; set; } = null!;
    public ICollection<ApprovalAuditLog> AuditLogs { get; set; } = new List<ApprovalAuditLog>();
}
