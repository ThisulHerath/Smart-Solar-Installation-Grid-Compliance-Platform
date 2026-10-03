using SolarPlatform.Api.Models;
using SolarPlatform.Api.Services;
using Xunit;

namespace SolarPlatform.Tests;

public class ProposalStatusTransitionTests
{
    [Theory]
    [InlineData(ProposalStatus.Draft, ProposalStatus.Processing)]
    [InlineData(ProposalStatus.Processing, ProposalStatus.PendingApproval)]
    [InlineData(ProposalStatus.Processing, ProposalStatus.Failed)]
    [InlineData(ProposalStatus.PendingApproval, ProposalStatus.Approved)]
    [InlineData(ProposalStatus.PendingApproval, ProposalStatus.Rejected)]
    [InlineData(ProposalStatus.PendingApproval, ProposalStatus.RevisionRequested)]
    [InlineData(ProposalStatus.RevisionRequested, ProposalStatus.Processing)]
    [InlineData(ProposalStatus.Failed, ProposalStatus.Processing)]
    public void AllowedTransitions_ReturnTrue(ProposalStatus from, ProposalStatus to)
    {
        Assert.True(ProposalStatusTransition.CanTransition(from, to));
        ProposalStatusTransition.ValidateTransition(from, to);
    }

    [Theory]
    [InlineData(ProposalStatus.Draft, ProposalStatus.Approved)]
    [InlineData(ProposalStatus.Draft, ProposalStatus.Rejected)]
    [InlineData(ProposalStatus.Draft, ProposalStatus.PendingApproval)]
    [InlineData(ProposalStatus.PendingApproval, ProposalStatus.Draft)]
    [InlineData(ProposalStatus.Approved, ProposalStatus.Rejected)]
    [InlineData(ProposalStatus.Rejected, ProposalStatus.Approved)]
    [InlineData(ProposalStatus.Approved, ProposalStatus.Draft)]
    public void DisallowedTransitions_ThrowInvalidOperationException(ProposalStatus from, ProposalStatus to)
    {
        Assert.False(ProposalStatusTransition.CanTransition(from, to));
        Assert.Throws<InvalidOperationException>(() => ProposalStatusTransition.ValidateTransition(from, to));
    }
}
