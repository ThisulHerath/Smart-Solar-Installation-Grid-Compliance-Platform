namespace SolarPlatform.Api.Models;

/// <summary>
/// Immutable audit record of every approval decision taken on an EngineeringProposal.
/// Written inside the same database transaction as the status update — never modified after creation.
/// </summary>
public class ApprovalAuditLog
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid EngineeringProposalId { get; set; }
    public string? WorkflowId { get; set; }

    /// <summary>Authenticated user who made the decision.</summary>
    public Guid UserId { get; set; }

    public ApprovalDecision Decision { get; set; }

    /// <summary>Mandatory for Rejected and RevisionRequested decisions.</summary>
    public string? Comment { get; set; }

    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    // ── Navigation ─────────────────────────────────────────────────────────────
    public EngineeringProposal EngineeringProposal { get; set; } = null!;
    public User User { get; set; } = null!;
}
