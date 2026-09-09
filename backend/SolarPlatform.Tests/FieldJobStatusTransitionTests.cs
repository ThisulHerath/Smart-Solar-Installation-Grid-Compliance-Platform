using SolarPlatform.Api.Models;
using SolarPlatform.Api.Services;

namespace SolarPlatform.Tests;

public class FieldJobStatusTransitionTests
{
    [Theory]
    [InlineData(FieldJobStatus.Assigned, FieldJobStatus.Accepted)]
    [InlineData(FieldJobStatus.Accepted, FieldJobStatus.InProgress)]
    [InlineData(FieldJobStatus.InProgress, FieldJobStatus.Submitted)]
    [InlineData(FieldJobStatus.Submitted, FieldJobStatus.ComplianceProcessing)]
    [InlineData(FieldJobStatus.ComplianceProcessing, FieldJobStatus.ComplianceComplete)]
    [InlineData(FieldJobStatus.ComplianceProcessing, FieldJobStatus.Failed)]
    [InlineData(FieldJobStatus.Failed, FieldJobStatus.Assigned)]
    public void AllowedTransitions_ReturnTrue(FieldJobStatus from, FieldJobStatus to)
    {
        Assert.True(FieldJobStatusTransition.CanTransition(from, to));
        FieldJobStatusTransition.ValidateTransition(from, to);
    }

    [Theory]
    [InlineData(FieldJobStatus.Assigned, FieldJobStatus.Submitted)]
    [InlineData(FieldJobStatus.Assigned, FieldJobStatus.ComplianceComplete)]
    [InlineData(FieldJobStatus.Accepted, FieldJobStatus.ComplianceComplete)]
    [InlineData(FieldJobStatus.Submitted, FieldJobStatus.ComplianceComplete)]
    public void DisallowedTransitions_ThrowInvalidOperationException(FieldJobStatus from, FieldJobStatus to)
    {
        Assert.False(FieldJobStatusTransition.CanTransition(from, to));
        Assert.Throws<InvalidOperationException>(() => FieldJobStatusTransition.ValidateTransition(from, to));
    }
}
