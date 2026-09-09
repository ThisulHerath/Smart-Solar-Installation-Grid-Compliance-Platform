using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Models;
using SolarPlatform.Api.Services;

namespace SolarPlatform.Api.Controllers;

[ApiController]
[Route("api/field-jobs")]
[Authorize(Roles = $"{RoleConstants.Administrator},{RoleConstants.SeniorEngineer}")]
public class FieldJobsController : ControllerBase
{
    private readonly IFieldJobService _fieldJobService;
    private readonly ILogger<FieldJobsController> _logger;

    public FieldJobsController(IFieldJobService fieldJobService, ILogger<FieldJobsController> logger)
    {
        _fieldJobService = fieldJobService;
        _logger = logger;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<FieldJobResponseDto>>> GetAllJobs([FromQuery] FieldJobStatus? status)
    {
        var jobs = await _fieldJobService.GetAllJobsAsync(status);
        return Ok(jobs);
    }

    [HttpGet("{jobId:guid}")]
    public async Task<ActionResult<FieldJobResponseDto>> GetJobById(Guid jobId)
    {
        var job = await _fieldJobService.GetJobByIdAsync(jobId);
        if (job == null) return NotFound(new { message = $"Job {jobId} not found." });
        return Ok(job);
    }

    [HttpPost]
    public async Task<ActionResult<FieldJobResponseDto>> CreateJob([FromBody] CreateFieldJobDto dto)
    {
        try
        {
            var job = await _fieldJobService.CreateOrAssignJobAsync(dto);
            return CreatedAtAction(nameof(GetJobById), new { jobId = job.Id }, job);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    [HttpPut("{jobId:guid}/assign")]
    public async Task<ActionResult<FieldJobResponseDto>> AssignJob(Guid jobId, [FromBody] AssignFieldJobDto dto)
    {
        try
        {
            var job = await _fieldJobService.AssignJobAsync(jobId, dto);
            if (job == null) return NotFound(new { message = $"Job {jobId} not found." });
            return Ok(job);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    [HttpPost("{jobId:guid}/evaluate-compliance")]
    public async Task<ActionResult<ComplianceAssessmentDto>> EvaluateCompliance(Guid jobId)
    {
        var assessment = await _fieldJobService.TriggerComplianceEvaluationAsync(jobId);
        if (assessment == null) return NotFound(new { message = $"Job {jobId} or inspection draft not found." });
        return Ok(assessment);
    }
}
