using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using System.Text.Json;
using SolarPlatform.Api.Data;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Integrations;
using SolarPlatform.Api.Models;

namespace SolarPlatform.Api.Controllers;

[ApiController, Authorize]
[Route("api/agent-workflows")]
public class AgentWorkflowsController : ControllerBase
{
    private readonly IAgenticAiService _agenticAiService;
    private readonly ILogger<AgentWorkflowsController> _logger;
    private readonly AppDbContext _db;

    public AgentWorkflowsController(IAgenticAiService agenticAiService, ILogger<AgentWorkflowsController> logger, AppDbContext db)
    {
        _agenticAiService = agenticAiService;
        _logger = logger;
        _db = db;
    }

    [HttpPost("test")]
    [Authorize(Roles = RoleConstants.Administrator + "," + RoleConstants.SeniorEngineer)]
    [ProducesResponseType(typeof(WorkflowTestResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> ExecuteTestWorkflow([FromBody] WorkflowTestRequestDto request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Objective))
        {
            return BadRequest(new { message = "Objective must not be empty." });
        }

        _logger.LogInformation("Received request to trigger Agentic AI test workflow with objective: {Objective}", request.Objective);
        var result = await _agenticAiService.ExecuteTestWorkflowAsync(request, cancellationToken);
        return Ok(result);
    }

    [HttpPost("start")]
    [Authorize(Roles = RoleConstants.Homeowner + "," + RoleConstants.Administrator + "," + RoleConstants.SeniorEngineer)]
    public async Task<IActionResult> StartStructuredWorkflow([FromBody] StructuredWorkflowStartDto request, CancellationToken cancellationToken)
    {
        var survey = await _db.SolarSurveys.Include(x => x.Customer).SingleOrDefaultAsync(x => x.Id == request.SurveyId, cancellationToken);
        if (survey == null) return NotFound(new { message = "Survey was not found." });
        if (User.IsInRole(RoleConstants.Homeowner) && survey.Customer.UserId != UserId()) return Forbid();

        var workflow = new AgentWorkflow
        {
            SolarSurveyId = survey.Id,
            Objective = request.Objective.Trim(),
            Status = WorkflowStatus.Processing,
            CurrentStep = "planning",
            StartedAt = DateTime.UtcNow,
        };
        _db.AgentWorkflows.Add(workflow);

        var result = await _agenticAiService.StartStructuredWorkflowAsync(new
        {
            workflow_id = workflow.WorkflowId,
            objective = workflow.Objective,
            customer_id = survey.CustomerId.ToString(),
            input_data = new
            {
                monthly_kwh = survey.MonthlyKwh,
                roof_area_sqm = survey.RoofAreaSqm,
                grid_type = survey.GridType.ToString(),
                property_address = survey.PropertyAddress,
            },
        }, cancellationToken);
        if (result == null) return StatusCode(StatusCodes.Status503ServiceUnavailable, new { message = "The workflow service is unavailable. No workflow result was accepted." });

        await PersistStateAsync(workflow, result, cancellationToken);
        return Ok(result);
    }

    [HttpPost("{workflowId}/resume")]
    [Authorize(Roles = RoleConstants.FieldTechnician + "," + RoleConstants.SeniorEngineer + "," + RoleConstants.InventoryOfficer + "," + RoleConstants.Administrator)]
    public async Task<IActionResult> ResumeStructuredWorkflow(string workflowId, [FromBody] StructuredWorkflowResumeDto request, CancellationToken cancellationToken)
    {
        var workflow = await _db.AgentWorkflows.SingleOrDefaultAsync(x => x.WorkflowId == workflowId, cancellationToken);
        if (workflow == null) return NotFound(new { message = "Workflow was not found." });
        if (string.IsNullOrWhiteSpace(workflow.StateJson)) return Conflict(new { message = "Workflow has no recoverable state." });
        if (!CanApplyEvent(request.Event)) return Forbid();
        var eventName = request.Event.Trim().ToUpperInvariant();
        var businessStateError = await ValidateBusinessStateAsync(workflow.SolarSurveyId, eventName, cancellationToken);
        if (businessStateError != null) return Conflict(new { message = businessStateError });
        Dictionary<string, object?> verifiedEventData = eventName == "INSPECTION_COMPLETED"
            ? await InspectionEventDataAsync(workflow.SolarSurveyId, cancellationToken)
            : request.EventData.ToDictionary(x => x.Key, x => (object?)x.Value);

        using var state = JsonDocument.Parse(workflow.StateJson);
        var result = await _agenticAiService.ResumeStructuredWorkflowAsync(new
        {
            workflow_state = state.RootElement,
            @event = eventName,
            event_data = verifiedEventData,
        }, cancellationToken);
        if (result == null) return StatusCode(StatusCodes.Status503ServiceUnavailable, new { message = "The workflow service is unavailable. Existing state was preserved." });

        await PersistStateAsync(workflow, result, cancellationToken);
        return Ok(result);
    }

    [HttpGet("{workflowId}")]
    public async Task<IActionResult> GetStructuredWorkflow(string workflowId, CancellationToken cancellationToken)
    {
        var workflow = await _db.AgentWorkflows.Include(x => x.SolarSurvey).ThenInclude(x => x.Customer)
            .SingleOrDefaultAsync(x => x.WorkflowId == workflowId, cancellationToken);
        if (workflow == null) return NotFound();
        var staff = User.IsInRole(RoleConstants.Administrator) || User.IsInRole(RoleConstants.SeniorEngineer)
            || User.IsInRole(RoleConstants.FieldTechnician) || User.IsInRole(RoleConstants.InventoryOfficer);
        if (!staff && workflow.SolarSurvey.Customer.UserId != UserId()) return Forbid();
        if (string.IsNullOrWhiteSpace(workflow.StateJson)) return Ok(new { workflow.WorkflowId, workflow.Objective, status = workflow.Status.ToString(), workflow.CurrentStep, workflow.ApprovalStatus });
        return Content(workflow.StateJson, "application/json");
    }

    private bool CanApplyEvent(string value)
    {
        var eventName = value.Trim().ToUpperInvariant();
        if (eventName is not ("INSPECTION_COMPLETED" or "ENGINEER_APPROVED" or "ENGINEER_REJECTED"
            or "REVISION_REQUESTED" or "PRICING_REQUESTED" or "INVENTORY_RESERVED")) return false;
        if (User.IsInRole(RoleConstants.Administrator)) return true;
        if (eventName == "INSPECTION_COMPLETED") return User.IsInRole(RoleConstants.FieldTechnician);
        if (eventName is "ENGINEER_APPROVED" or "ENGINEER_REJECTED" or "REVISION_REQUESTED") return User.IsInRole(RoleConstants.SeniorEngineer);
        if (eventName is "PRICING_REQUESTED" or "INVENTORY_RESERVED") return User.IsInRole(RoleConstants.InventoryOfficer);
        return false;
    }

    private async Task<string?> ValidateBusinessStateAsync(Guid surveyId, string eventName, CancellationToken cancellationToken)
    {
        if (eventName == "INSPECTION_COMPLETED")
        {
            var submitted = await _db.SiteInspections.AnyAsync(x => x.FieldJob.SolarSurveyId == surveyId
                && (x.InspectionStatus == InspectionStatus.Submitted || x.InspectionStatus == InspectionStatus.Reviewed), cancellationToken);
            return submitted ? null : "Submit the site inspection before resuming compliance evaluation.";
        }

        ProposalStatus? requiredProposalStatus = eventName switch
        {
            "ENGINEER_APPROVED" or "PRICING_REQUESTED" => ProposalStatus.Approved,
            "ENGINEER_REJECTED" => ProposalStatus.Rejected,
            "REVISION_REQUESTED" => ProposalStatus.RevisionRequested,
            _ => null,
        };
        if (requiredProposalStatus.HasValue)
        {
            var found = await _db.EngineeringProposals.AnyAsync(x => x.SolarSurveyId == surveyId
                && x.ProposalStatus == requiredProposalStatus.Value, cancellationToken);
            return found ? null : $"Complete the proposal action first; this workflow event requires proposal status {requiredProposalStatus.Value}.";
        }

        if (eventName == "INVENTORY_RESERVED")
        {
            var reserved = await _db.Set<EquipmentQuote>().AnyAsync(x => x.EngineeringProposal.SolarSurveyId == surveyId
                && x.Status == "RESERVED", cancellationToken);
            return reserved ? null : "Reserve the validated equipment quote before completing the workflow.";
        }

        return null;
    }

    private async Task<Dictionary<string, object?>> InspectionEventDataAsync(Guid surveyId, CancellationToken cancellationToken)
    {
        var inspection = await _db.SiteInspections.AsNoTracking().Include(x => x.Telemetry)
            .Where(x => x.FieldJob.SolarSurveyId == surveyId
                && (x.InspectionStatus == InspectionStatus.Submitted || x.InspectionStatus == InspectionStatus.Reviewed))
            .OrderByDescending(x => x.UpdatedAt).FirstAsync(cancellationToken);
        decimal? Reading(MeasurementType type) => inspection.Telemetry
            .Where(x => x.MeasurementType == type).OrderByDescending(x => x.RecordedAt)
            .Select(x => (decimal?)x.MeasurementValue).FirstOrDefault();
        return new Dictionary<string, object?>
        {
            ["inspection_id"] = inspection.Id.ToString(),
            ["field_job_id"] = inspection.FieldJobId.ToString(),
            ["grid_type"] = inspection.GridTypeObserved.ToString(),
            ["phase_count"] = inspection.PhaseCount,
            ["main_breaker_rating"] = inspection.MainBreakerRating,
            ["inverter_location_suitable"] = inspection.InverterLocationSuitable,
            ["roof_area_sqm"] = inspection.RoofAreaMeasuredSqm,
            ["roof_tilt"] = inspection.RoofTilt,
            ["roof_orientation"] = inspection.RoofOrientation.ToString(),
            ["voc"] = Reading(MeasurementType.Voc),
            ["isc"] = Reading(MeasurementType.Isc),
            ["vmp"] = Reading(MeasurementType.Vmp),
            ["imp"] = Reading(MeasurementType.Imp),
            ["irradiance"] = Reading(MeasurementType.Irradiance),
            ["temperature"] = Reading(MeasurementType.Temperature),
            ["grid_voltage"] = Reading(MeasurementType.GridVoltage),
            ["grid_frequency"] = Reading(MeasurementType.GridFrequency),
            ["safety_notes"] = inspection.SafetyNotes,
            ["technician_notes"] = inspection.TechnicianNotes,
        };
    }

    private async Task PersistStateAsync(AgentWorkflow workflow, StructuredWorkflowResultDto result, CancellationToken cancellationToken)
    {
        workflow.CurrentStep = result.CurrentStepId;
        workflow.ApprovalStatus = result.ApprovalStatus;
        workflow.RetryCount = result.RetryCount;
        workflow.PlanJson = JsonSerializer.Serialize(result.Plan);
        workflow.StateJson = JsonSerializer.Serialize(result);
        workflow.ResultJson = JsonOrNull(result.AgentOutputs);
        workflow.ValidationJson = JsonOrNull(result.ValidationResults);
        workflow.ErrorMessage = result.WorkflowStatus == "FAILED" ? JsonOrNull(result.Errors) : null;
        workflow.Status = result.WorkflowStatus switch
        {
            "COMPLETED" => WorkflowStatus.Completed,
            "FAILED" => WorkflowStatus.Failed,
            _ => WorkflowStatus.Processing,
        };
        workflow.CompletedAt = workflow.Status is WorkflowStatus.Completed or WorkflowStatus.Failed ? DateTime.UtcNow : null;
        workflow.UpdatedAt = DateTime.UtcNow;

        if (workflow.Id != Guid.Empty)
        {
            var oldLogs = _db.AgentExecutionLogs.Where(x => x.AgentWorkflowId == workflow.Id);
            _db.AgentExecutionLogs.RemoveRange(oldLogs);
        }
        foreach (var log in result.ExecutionLogs)
        {
            _db.AgentExecutionLogs.Add(new AgentExecutionLog
            {
                AgentWorkflowId = workflow.Id,
                AgentName = Text(log, "agent_name") ?? "Workflow",
                StepName = Text(log, "step_name") ?? "execution",
                ToolName = Text(log, "tool_name"),
                TraceId = Text(log, "trace_id") ?? result.WorkflowId,
                SpanId = Text(log, "span_id"),
                Status = Text(log, "status") ?? "completed",
                StartedAt = Date(log, "started_at") ?? DateTime.UtcNow,
                CompletedAt = Date(log, "completed_at"),
                DurationMs = Number(log, "duration_ms"),
                OutputSummary = Text(log, "output_summary"),
                ValidationResult = log.TryGetValue("validation_result", out var validation) ? validation.GetRawText() : null,
                ErrorMessage = Text(log, "error_message"),
                RetryCount = (int)(Number(log, "retry_count") ?? 0),
            });
        }
        await _db.SaveChangesAsync(cancellationToken);
    }

    private static string? JsonOrNull(JsonElement? value) => value is null || value.Value.ValueKind is JsonValueKind.Undefined or JsonValueKind.Null ? null : value.Value.GetRawText();
    private static string? Text(Dictionary<string, JsonElement> values, string key) => values.TryGetValue(key, out var value) && value.ValueKind == JsonValueKind.String ? value.GetString() : null;
    private static DateTime? Date(Dictionary<string, JsonElement> values, string key) => DateTime.TryParse(Text(values, key), out var value) ? value.ToUniversalTime() : null;
    private static long? Number(Dictionary<string, JsonElement> values, string key) => values.TryGetValue(key, out var value) && value.TryGetDouble(out var number) ? Math.Max(0, (long)Math.Round(number)) : null;
    private Guid UserId() => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
}
