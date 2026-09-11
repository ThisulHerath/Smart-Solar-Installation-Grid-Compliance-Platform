namespace SolarPlatform.Api.Models;

/// <summary>Lifecycle states for an engineering proposal.</summary>
public enum ProposalStatus
{
    Draft,
    Processing,
    PendingApproval,
    Approved,
    Rejected,
    RevisionRequested,
    Failed
}

/// <summary>Decision made by a Senior Engineer on a proposal.</summary>
public enum ApprovalDecision
{
    Approved,
    Rejected,
    RevisionRequested
}

public enum ProposalLifecycleEvent
{
    PROPOSAL_CREATED,
    GUARDRAIL_STARTED,
    VALIDATION_COMPLETED,
    APPROVAL_REQUIRED,
    APPROVAL_BLOCKED,
    APPROVED,
    REJECTED,
    REVISION_REQUESTED
}
