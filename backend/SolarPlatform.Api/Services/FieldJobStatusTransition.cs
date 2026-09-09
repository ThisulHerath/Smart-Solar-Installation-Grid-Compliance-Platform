using SolarPlatform.Api.Models;

namespace SolarPlatform.Api.Services;

public static class FieldJobStatusTransition
{
    private static readonly Dictionary<FieldJobStatus, HashSet<FieldJobStatus>> AllowedTransitions = new()
    {
        [FieldJobStatus.Assigned] = new() { FieldJobStatus.Accepted, FieldJobStatus.Failed },
        [FieldJobStatus.Accepted] = new() { FieldJobStatus.InProgress, FieldJobStatus.Assigned, FieldJobStatus.Failed },
        [FieldJobStatus.InProgress] = new() { FieldJobStatus.Submitted, FieldJobStatus.Assigned, FieldJobStatus.Failed },
        [FieldJobStatus.Submitted] = new() { FieldJobStatus.ComplianceProcessing, FieldJobStatus.InProgress, FieldJobStatus.Failed },
        [FieldJobStatus.ComplianceProcessing] = new() { FieldJobStatus.ComplianceComplete, FieldJobStatus.Failed },
        [FieldJobStatus.ComplianceComplete] = new() { FieldJobStatus.Failed }, // Terminal or re-assessment
        [FieldJobStatus.Failed] = new() { FieldJobStatus.Assigned, FieldJobStatus.InProgress } // Allow retry / re-dispatch
    };

    public static bool CanTransition(FieldJobStatus from, FieldJobStatus to)
    {
        if (from == to) return true;
        return AllowedTransitions.TryGetValue(from, out var validTargets) && validTargets.Contains(to);
    }

    public static void ValidateTransition(FieldJobStatus from, FieldJobStatus to)
    {
        if (!CanTransition(from, to))
        {
            throw new InvalidOperationException($"Invalid status transition from '{from}' to '{to}'.");
        }
    }
}
