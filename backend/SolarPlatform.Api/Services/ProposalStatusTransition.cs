using SolarPlatform.Api.Models;

namespace SolarPlatform.Api.Services;

/// <summary>
/// Enforces valid ProposalStatus transitions for the engineering proposal state machine.
/// Invalid transitions throw <see cref="InvalidOperationException"/> — never silently succeed.
/// </summary>
public static class ProposalStatusTransition
{
    private static readonly Dictionary<ProposalStatus, HashSet<ProposalStatus>> AllowedTransitions = new()
    {
        [ProposalStatus.Draft]             = new() { ProposalStatus.Processing, ProposalStatus.Failed },
        [ProposalStatus.Processing]        = new() { ProposalStatus.PendingApproval, ProposalStatus.Failed },
        [ProposalStatus.PendingApproval]   = new() { ProposalStatus.Approved, ProposalStatus.Rejected, ProposalStatus.RevisionRequested },
        [ProposalStatus.RevisionRequested] = new() { ProposalStatus.Processing, ProposalStatus.Failed },
        [ProposalStatus.Approved]          = new HashSet<ProposalStatus>(), // Terminal
        [ProposalStatus.Rejected]          = new HashSet<ProposalStatus>(), // Terminal
        [ProposalStatus.Failed]            = new() { ProposalStatus.Processing }  // Allow retry
    };

    public static bool CanTransition(ProposalStatus from, ProposalStatus to)
    {
        if (from == to) return true;
        return AllowedTransitions.TryGetValue(from, out var targets) && targets.Contains(to);
    }

    public static void ValidateTransition(ProposalStatus from, ProposalStatus to)
    {
        if (!CanTransition(from, to))
            throw new InvalidOperationException(
                $"Invalid proposal status transition from '{from}' to '{to}'.");
    }
}
