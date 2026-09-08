using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Moq;
using SolarPlatform.Api.Data;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Integrations;
using SolarPlatform.Api.Models;
using SolarPlatform.Api.Services;

namespace SolarPlatform.Tests;

public class SurveyServiceTests
{
    private readonly AppDbContext _db;
    private readonly Mock<IAgenticAiService> _ai = new();
    private readonly Guid _owner = Guid.NewGuid();
    private readonly Guid _other = Guid.NewGuid();

    public SurveyServiceTests()
    {
        _db = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);
        _db.Users.AddRange(new User { Id = _owner, Email = "owner@test.local", FullName = "Owner", PasswordHash = "x" }, new User { Id = _other, Email = "other@test.local", FullName = "Other", PasswordHash = "x" });
        _db.SaveChanges();
        _ai.Setup(x => x.ExecuteSolarSizingAsync(It.IsAny<object>(), It.IsAny<CancellationToken>())).ReturnsAsync(Success());
    }

    private SurveyService Service() => new(_db, _ai.Object);
    private static SurveyRequestDto Request() => new() { MonthlyKwh = 900, RoofAreaSqm = 75, GridType = GridType.SinglePhase, PropertyAddress = "10 Solar Lane" };
    private static SolarSizingResponseDto Success() => new()
    {
        Status = "completed", Recommendation = JsonDocument.Parse("{\"recommended_kw\":7.5,\"estimated_panel_count\":19,\"estimated_inverter_kw\":7.5}").RootElement,
        ValidationResults = JsonDocument.Parse("{\"valid\":true}").RootElement,
        ExecutionLogs = new List<AgentExecutionLogDto> { new() { AgentName = "Planner", StepName = "planning", Status = "completed", OutputSummary = "Plan created" }, new() { AgentName = "SolarSizingAgent", StepName = "sizing", Status = "completed" }, new() { AgentName = "DeterministicValidator", StepName = "validation", Status = "completed", ValidationResult = JsonDocument.Parse("{\"valid\":true}").RootElement } }
    };

    [Fact] public async Task Homeowner_CanReadOwnSurvey_ButNotAnotherOwners()
    {
        var survey = await Service().CreateAsync(_owner, Request());
        Assert.NotNull(await Service().GetAsync(_owner, survey.Id));
        Assert.Null(await Service().GetAsync(_other, survey.Id));
    }

    [Fact] public async Task Homeowner_CanUpdateDraft_ButNotSubmittedSurvey()
    {
        var survey = await Service().CreateAsync(_owner, Request());
        var changed = Request(); changed.MonthlyKwh = 1000;
        Assert.Equal(1000, (await Service().UpdateAsync(_owner, survey.Id, changed))!.MonthlyKwh);
        await Service().SubmitAsync(_owner, survey.Id);
        await Assert.ThrowsAsync<InvalidOperationException>(() => Service().UpdateAsync(_owner, survey.Id, Request()));
    }

    [Fact] public async Task InvalidSurveyInput_IsRejected()
    {
        var request = Request(); request.MonthlyKwh = 0;
        await Assert.ThrowsAsync<ArgumentException>(() => Service().CreateAsync(_owner, request));
    }

    [Fact] public async Task Submission_RunsWorkflow_PersistsResultAndExecutionLogs()
    {
        var survey = await Service().CreateAsync(_owner, Request());
        var submitted = await Service().SubmitAsync(_owner, survey.Id);
        Assert.Equal(SurveyStatus.AnalysisComplete, submitted!.SurveyStatus);
        _ai.Verify(x => x.ExecuteSolarSizingAsync(It.IsAny<object>(), It.IsAny<CancellationToken>()), Times.Once);
        var workflow = await _db.AgentWorkflows.SingleAsync();
        Assert.Equal(WorkflowStatus.Completed, workflow.Status);
        Assert.NotNull(workflow.ResultJson);
        var logs = await _db.AgentExecutionLogs.ToListAsync();
        Assert.Equal(new[] { "Planner", "SolarSizingAgent", "DeterministicValidator" }.Order(), logs.Select(x => x.AgentName).Order());
        Assert.All(logs, log => { Assert.NotNull(log.CompletedAt); Assert.NotNull(log.DurationMs); });
    }

    [Fact] public async Task AiFailure_IsSafeAndTransitionsToFailed()
    {
        _ai.Setup(x => x.ExecuteSolarSizingAsync(It.IsAny<object>(), It.IsAny<CancellationToken>())).ReturnsAsync(new SolarSizingResponseDto { Status = "failed", Errors = new() { "unavailable" } });
        var survey = await Service().CreateAsync(_owner, Request());
        Assert.Equal(SurveyStatus.Failed, (await Service().SubmitAsync(_owner, survey.Id))!.SurveyStatus);
    }

    [Theory]
    [InlineData(SurveyStatus.Draft, SurveyStatus.Processing)]
    [InlineData(SurveyStatus.AnalysisComplete, SurveyStatus.Failed)]
    public void InvalidStatusTransition_IsRejected(SurveyStatus from, SurveyStatus to) => Assert.Throws<InvalidOperationException>(() => SurveyStatusTransition.EnsureAllowed(from, to));

    [Fact]
    public void AllowedStatusFlow_IsAccepted()
    {
        SurveyStatusTransition.EnsureAllowed(SurveyStatus.Draft, SurveyStatus.Submitted);
        SurveyStatusTransition.EnsureAllowed(SurveyStatus.Submitted, SurveyStatus.Processing);
        SurveyStatusTransition.EnsureAllowed(SurveyStatus.Processing, SurveyStatus.AnalysisComplete);
        SurveyStatusTransition.EnsureAllowed(SurveyStatus.Processing, SurveyStatus.Failed);
    }
}
