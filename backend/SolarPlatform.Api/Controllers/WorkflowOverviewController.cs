using System.Security.Claims;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SolarPlatform.Api.Data;
using SolarPlatform.Api.Models;

namespace SolarPlatform.Api.Controllers;

/// <summary>The survey ID correlates durable state across the asynchronous installation stages.</summary>
[ApiController, Authorize, Route("api/workflows/surveys")]
public class WorkflowOverviewController(AppDbContext db) : ControllerBase
{
    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Get(Guid id, CancellationToken ct)
    {
        var actor = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var staff = User.IsInRole(RoleConstants.Administrator) || User.IsInRole(RoleConstants.SeniorEngineer);
        var survey = await db.SolarSurveys.AsNoTracking().Include(x => x.Workflows).ThenInclude(x => x.ExecutionLogs)
            .SingleOrDefaultAsync(x => x.Id == id && (staff || x.Customer.UserId == actor), ct);
        if (survey == null) return NotFound();
        var sizing = survey.Workflows.OrderByDescending(x => x.CreatedAt).FirstOrDefault();
        var compliance = await db.ComplianceAssessments.AsNoTracking().Where(x => x.SiteInspection.FieldJob.SolarSurveyId == id).OrderByDescending(x => x.CreatedAt).FirstOrDefaultAsync(ct);
        var proposal = await db.EngineeringProposals.AsNoTracking().Include(x => x.AuditLogs).Include(x => x.LifecycleEvents).Where(x => x.SolarSurveyId == id).OrderByDescending(x => x.CreatedAt).FirstOrDefaultAsync(ct);
        var quotes = proposal == null ? new List<EquipmentQuote>() : await db.Set<EquipmentQuote>().AsNoTracking().Where(x => x.EngineeringProposalId == proposal.Id).OrderByDescending(x => x.CreatedAt).ToListAsync(ct);
        var activeQuote = quotes.FirstOrDefault(x => x.Status == "RESERVED") ?? quotes.FirstOrDefault();
        var completed = new List<string>();
        if (sizing?.Status == WorkflowStatus.Completed) completed.Add("SolarSizingAgent");
        if (compliance != null) completed.Add("GridComplianceAgent");
        if (proposal?.GuardrailResultJson != null) completed.Add("SafetyGuardrailAgent");
        if (proposal?.ProposalStatus == ProposalStatus.Approved) completed.Add("HumanApproval");
        if (activeQuote?.Status is "VALIDATED" or "RESERVED" or "RELEASED") completed.Add("EquipmentPricingAgent");
        if (activeQuote?.Status == "RESERVED") completed.Add("InventoryReservation");
        return Ok(new {
            workflowId = survey.Id, objective = sizing?.Objective ?? "Assess rooftop solar suitability and prepare an approved equipment plan",
            plan = ReadJson(sizing?.PlanJson), completedSteps = completed,
            status = activeQuote?.Status == "RESERVED" ? "COMPLETE" : proposal?.ProposalStatus.ToString() ?? survey.SurveyStatus.ToString(),
            approvalStatus = proposal?.ProposalStatus.ToString() ?? "NOT_REQUESTED",
            finalOutcome = activeQuote?.Status == "RESERVED" ? "Approved equipment reserved; ready for installation planning." : "Awaiting the next workflow stage.",
            sizing = ReadJson(sizing?.ResultJson), sizingValidation = ReadJson(sizing?.ValidationJson),
            compliance = compliance == null ? null : new { compliance.ComplianceStatus, compliance.RiskLevel, compliance.ValidationStatus, compliance.ComplianceNotes },
            safety = ReadJson(proposal?.GuardrailResultJson), safetyValidation = ReadJson(proposal?.ValidationResultJson),
            equipment = quotes.Select(x => new { x.Id, x.Status, x.Error, x.CreatedAt, x.ExpiresAt, result = ReadJson(x.ResultJson) }),
            errors = new[] { sizing?.ErrorMessage, activeQuote?.Error }.Where(x => !string.IsNullOrWhiteSpace(x)),
            executionLogs = sizing?.ExecutionLogs.OrderBy(x => x.StartedAt).Select(x => new { x.AgentName, x.StepName, x.Status, x.StartedAt, x.CompletedAt, x.DurationMs, x.OutputSummary, x.ErrorMessage, x.RetryCount }),
            approvalHistory = proposal?.AuditLogs.OrderBy(x => x.Timestamp).Select(x => new { x.Decision, x.Comment, x.Timestamp, x.UserId }),
            lifecycleEvents = proposal?.LifecycleEvents.OrderBy(x => x.Timestamp).Select(x => new { x.Event, x.Details, x.Timestamp }),
            ruleScope = "Preliminary Sri Lankan rooftop-solar assessment using documented project rules; utility approval remains external."
        });
    }
    private static JsonElement? ReadJson(string? value) => string.IsNullOrWhiteSpace(value) ? null : JsonSerializer.Deserialize<JsonElement>(value);
}
