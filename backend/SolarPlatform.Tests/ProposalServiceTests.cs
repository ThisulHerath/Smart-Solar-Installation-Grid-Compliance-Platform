using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.Logging;
using Moq;
using SolarPlatform.Api.Data;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Integrations;
using SolarPlatform.Api.Models;
using SolarPlatform.Api.Services;
using Xunit;

namespace SolarPlatform.Tests;

public class ProposalServiceTests
{
    private readonly AppDbContext _db;
    private readonly Mock<IAgenticAiService> _aiMock = new();
    private readonly Mock<ILogger<ProposalService>> _loggerMock = new();

    private readonly Guid _engineerId = Guid.NewGuid();
    private readonly Guid _homeownerId = Guid.NewGuid();
    private readonly Guid _surveyId = Guid.NewGuid();

    public ProposalServiceTests()
    {
        _db = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .ConfigureWarnings(w => w.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options);

        var engineer = new User
        {
            Id = _engineerId,
            Email = "engineer@smartsolar.local",
            FullName = "Senior Engineer",
            PasswordHash = "hash"
        };

        var homeowner = new User
        {
            Id = _homeownerId,
            Email = "homeowner@smartsolar.local",
            FullName = "Homeowner User",
            PasswordHash = "hash",
            CustomerProfile = new CustomerProfile
            {
                Id = Guid.NewGuid(),
                UserId = _homeownerId,
                FullName = "Homeowner User",
                PhoneNumber = "+94771112233"
            }
        };

        var survey = new SolarSurvey
        {
            Id = _surveyId,
            SurveyStatus = SurveyStatus.AnalysisComplete,
            CustomerId = homeowner.CustomerProfile.Id,
            MonthlyKwh = 1500,
            RoofAreaSqm = 100,
            GridType = GridType.ThreePhase,
            PropertyAddress = "123 Solar Way, Kandy"
        };

        _db.Users.AddRange(engineer, homeowner);
        _db.SolarSurveys.Add(survey);
        var job = new FieldJob { SolarSurveyId = survey.Id, TechnicianId = _engineerId };
        var inspection = new SiteInspection { FieldJobId = job.Id };
        _db.AddRange(job, inspection, new ComplianceAssessment {
            SiteInspectionId = inspection.Id, ComplianceStatus = "COMPLIANT", RiskLevel = "LOW", GridCompliant = true });
        _db.SaveChanges();

        // Setup AI mock default response
        _aiMock
            .Setup(x => x.EvaluateGuardrailAsync(It.IsAny<object>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new GuardrailResultDto
            {
                WorkflowId = "wf-guardrail-test",
                SafetyStatus = "REQUIRES_APPROVAL",
                RiskLevel = "MEDIUM",
                RequiresApproval = true,
                Issues = new List<string> { "kW 12.0 exceeds 10.0 kW automatic threshold" },
                Recommendations = new List<string> { "Senior engineer review recommended" },
                RecommendationSummary = "Guardrail evaluation complete"
            });
    }

    private ProposalService CreateService() =>
        new(_db, _aiMock.Object, _loggerMock.Object);

    [Fact]
    public async Task Approval_RequiresComplianceEvidence()
    {
        _db.ComplianceAssessments.RemoveRange(_db.ComplianceAssessments);
        await _db.SaveChangesAsync();
        var service = CreateService();
        var proposal = await service.CreateAsync(_surveyId, _homeownerId, null);
        await Assert.ThrowsAsync<InvalidOperationException>(() => service.ApproveAsync(proposal.Id, _engineerId, "Review"));
        Assert.Equal(ProposalStatus.PendingApproval, (await _db.EngineeringProposals.FindAsync(proposal.Id))!.ProposalStatus);
        Assert.Empty(await _db.ApprovalAuditLogs.ToListAsync());
    }

    [Fact]
    public async Task DraftSurvey_CannotGenerateProposal()
    {
        (await _db.SolarSurveys.FindAsync(_surveyId))!.SurveyStatus = SurveyStatus.Draft;
        await _db.SaveChangesAsync();
        await Assert.ThrowsAsync<InvalidOperationException>(() => CreateService().CreateAsync(_surveyId, _homeownerId, null));
        Assert.Empty(await _db.EngineeringProposals.ToListAsync());
    }

    [Fact]
    public async Task CreateProposal_CalculatesSpecsAndSetsStatusToPendingApproval()
    {
        var service = CreateService();
        var proposal = await service.CreateAsync(_surveyId, _homeownerId, null);

        Assert.NotNull(proposal);
        Assert.Equal(_surveyId, proposal.SolarSurveyId);
        Assert.Equal(ProposalStatus.PendingApproval.ToString(), proposal.ProposalStatus);
        Assert.True(proposal.RecommendedKw > 0);
        Assert.True(proposal.PanelCount > 0);
        Assert.True(proposal.EstimatedCostLkr > 0);
    }

    [Fact]
    public async Task ApproveProposal_WhenPendingApproval_UpdatesStatusAndCreatesAuditLog()
    {
        var service = CreateService();
        var proposal = await service.CreateAsync(_surveyId, _homeownerId, null);

        var approved = await service.ApproveAsync(proposal.Id, _engineerId, "System specs verified compliant");

        Assert.NotNull(approved);
        Assert.Equal(ProposalStatus.Approved.ToString(), approved.ProposalStatus);
        Assert.Single(approved.AuditLogs);
        Assert.Equal(ApprovalDecision.Approved.ToString(), approved.AuditLogs.First().Decision);
        Assert.Equal("System specs verified compliant", approved.AuditLogs.First().Comment);
    }

    [Fact]
    public async Task RejectProposal_WithoutComment_ThrowsArgumentException()
    {
        var service = CreateService();
        var proposal = await service.CreateAsync(_surveyId, _homeownerId, null);

        await Assert.ThrowsAsync<ArgumentException>(() =>
            service.RejectAsync(proposal.Id, _engineerId, ""));
    }

    [Fact]
    public async Task RejectProposal_WithComment_UpdatesStatusToRejected()
    {
        var service = CreateService();
        var proposal = await service.CreateAsync(_surveyId, _homeownerId, null);

        var rejected = await service.RejectAsync(proposal.Id, _engineerId, "Unsafe grid connection location");

        Assert.Equal(ProposalStatus.Rejected.ToString(), rejected.ProposalStatus);
        Assert.Single(rejected.AuditLogs);
        Assert.Equal(ApprovalDecision.Rejected.ToString(), rejected.AuditLogs.First().Decision);
    }

    [Fact]
    public async Task RequestRevision_WithComment_UpdatesStatusToRevisionRequested()
    {
        var service = CreateService();
        var proposal = await service.CreateAsync(_surveyId, _homeownerId, null);

        var revised = await service.RequestRevisionAsync(proposal.Id, _engineerId, "Please recalculate with 3-phase inverter");

        Assert.Equal(ProposalStatus.RevisionRequested.ToString(), revised.ProposalStatus);
        Assert.Single(revised.AuditLogs);
        Assert.Equal(ApprovalDecision.RevisionRequested.ToString(), revised.AuditLogs.First().Decision);
    }

    [Fact]
    public async Task ApproveProposal_WhenAlreadyApproved_ThrowsInvalidOperationException()
    {
        var service = CreateService();
        var proposal = await service.CreateAsync(_surveyId, _homeownerId, null);
        await service.ApproveAsync(proposal.Id, _engineerId, "First approval");

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            service.ApproveAsync(proposal.Id, _engineerId, "Second approval attempt"));
    }

    [Fact]
    public async Task GetPendingAsync_ReturnsOnlyPendingProposals()
    {
        var service = CreateService();
        var proposal = await service.CreateAsync(_surveyId, _homeownerId, null);

        var pending = await service.GetPendingAsync();
        Assert.Single(pending);
        Assert.Equal(proposal.Id, pending.First().Id);

        await service.ApproveAsync(proposal.Id, _engineerId, "Approved");

        var pendingAfter = await service.GetPendingAsync();
        Assert.Empty(pendingAfter);
    }

    [Fact]
    public async Task GetProposalDetail_IsolatedFromOtherHomeowners()
    {
        var service = CreateService();
        var proposal = await service.CreateAsync(_surveyId, _homeownerId, null);

        var visible = await service.GetAsync(proposal.Id, _homeownerId, false);
        var hidden = await service.GetAsync(proposal.Id, Guid.NewGuid(), false);

        Assert.NotNull(visible);
        Assert.Null(hidden);
    }

    [Fact]
    public async Task ApproveProposal_WhenStatusIsInvalid_RollsBackDecision()
    {
        var service = CreateService();
        var proposal = await service.CreateAsync(_surveyId, _homeownerId, null);
        await service.RejectAsync(proposal.Id, _engineerId, "Rejected for rollback test");

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            service.ApproveAsync(proposal.Id, _engineerId, "Invalid approval"));

        var reloaded = await service.GetAsync(proposal.Id, _engineerId, true);
        Assert.Equal(ProposalStatus.Rejected.ToString(), reloaded!.ProposalStatus);
        Assert.Single(reloaded.AuditLogs);
    }
}
