using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Models;
using SolarPlatform.Api.Services;

namespace SolarPlatform.Api.Controllers;

[ApiController]
[Route("api/technician/jobs")]
[Authorize(Roles = $"{RoleConstants.FieldTechnician},{RoleConstants.Administrator},{RoleConstants.SeniorEngineer}")]
public class TechnicianController : ControllerBase
{
    private readonly IFieldJobService _fieldJobService;
    private readonly ILogger<TechnicianController> _logger;

    public TechnicianController(IFieldJobService fieldJobService, ILogger<TechnicianController> logger)
    {
        _fieldJobService = fieldJobService;
        _logger = logger;
    }

    private Guid GetUserId()
    {
        var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(idClaim) || !Guid.TryParse(idClaim, out var userId))
        {
            throw new UnauthorizedAccessException("User ID is missing or invalid in claims.");
        }
        return userId;
    }

    private bool IsAdminOrEngineer() =>
        User.IsInRole(RoleConstants.Administrator) || User.IsInRole(RoleConstants.SeniorEngineer);

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<FieldJobResponseDto>>> GetMyJobs([FromQuery] FieldJobStatus? status)
    {
        var userId = GetUserId();
        // If Admin/Engineer without FieldTechnician role, allow viewing all or own
        if (IsAdminOrEngineer() && !User.IsInRole(RoleConstants.FieldTechnician))
        {
            var allJobs = await _fieldJobService.GetAllJobsAsync(status);
            return Ok(allJobs);
        }

        var jobs = await _fieldJobService.GetJobsForTechnicianAsync(userId, status);
        return Ok(jobs);
    }

    [HttpGet("{jobId:guid}")]
    public async Task<ActionResult<FieldJobResponseDto>> GetJobById(Guid jobId)
    {
        var userId = GetUserId();
        var job = await _fieldJobService.GetJobByIdAsync(jobId, IsAdminOrEngineer() ? null : userId);
        if (job == null) return NotFound(new { message = $"Job {jobId} not found or not assigned to you." });
        return Ok(job);
    }

    [HttpPut("{jobId:guid}/status")]
    public async Task<ActionResult<FieldJobResponseDto>> UpdateStatus(Guid jobId, [FromBody] UpdateJobStatusDto dto)
    {
        var userId = GetUserId();
        try
        {
            var updated = await _fieldJobService.UpdateJobStatusAsync(jobId, userId, dto.NewStatus);
            if (updated == null) return NotFound(new { message = $"Job {jobId} not found." });
            return Ok(updated);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("{jobId:guid}/check-in")]
    public async Task<ActionResult<SiteInspectionResponseDto>> CheckIn(Guid jobId, [FromBody] CheckInDto dto)
    {
        if (dto.Latitude < -90 || dto.Latitude > 90 || dto.Longitude < -180 || dto.Longitude > 180)
        {
            return BadRequest(new { message = "Invalid latitude or longitude coordinates." });
        }

        var userId = GetUserId();
        var result = await _fieldJobService.CheckInAsync(jobId, userId, dto);
        if (result == null) return NotFound(new { message = $"Job {jobId} not found." });
        return Ok(result);
    }

    [HttpPut("{jobId:guid}/inspection")]
    public async Task<ActionResult<SiteInspectionResponseDto>> SaveInspectionDraft(Guid jobId, [FromBody] SaveSiteInspectionDto dto)
    {
        var userId = GetUserId();
        var result = await _fieldJobService.SaveInspectionDraftAsync(jobId, userId, dto);
        if (result == null) return NotFound(new { message = $"Job {jobId} not found." });
        return Ok(result);
    }

    [HttpPost("{jobId:guid}/telemetry")]
    public async Task<ActionResult<SiteTelemetryDto>> RecordTelemetry(Guid jobId, [FromBody] RecordTelemetryDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Unit))
        {
            return BadRequest(new { message = "Telemetry measurement unit is required." });
        }

        var userId = GetUserId();
        var result = await _fieldJobService.RecordTelemetryAsync(jobId, userId, dto);
        if (result == null) return NotFound(new { message = $"Job {jobId} not found." });
        return Ok(result);
    }

    [HttpPost("{jobId:guid}/photos")]
    [Consumes("multipart/form-data")]
    public async Task<ActionResult<SitePhotoDto>> UploadPhoto(
        Guid jobId,
        IFormFile file,
        [FromForm] SitePhotoType photoType)
    {
        if (file == null || file.Length == 0 || file.Length > 5 * 1024 * 1024)
        {
            return BadRequest(new { message = "A photo of at most 5 MB is required." });
        }

        // Validate content type / extension
        var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp" };
        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!allowedExtensions.Contains(ext))
        {
            return BadRequest(new { message = "Only image files (.jpg, .jpeg, .png, .webp) are supported." });
        }

        var userId = GetUserId();
        using var stream = file.OpenReadStream();
        var result = await _fieldJobService.UploadPhotoAsync(jobId, userId, photoType, stream, file.FileName);
        if (result == null) return NotFound(new { message = $"Job {jobId} not found." });
        return Ok(result);
    }

    [HttpPost("{jobId:guid}/submit")]
    public async Task<ActionResult<SiteInspectionResponseDto>> SubmitInspection(Guid jobId)
    {
        var userId = GetUserId();
        try
        {
            var result = await _fieldJobService.SubmitInspectionAsync(jobId, userId);
            if (result == null) return NotFound(new { message = $"Job {jobId} or inspection draft not found." });
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("{jobId:guid}/compliance")]
    public async Task<ActionResult<ComplianceAssessmentDto>> GetCompliance(Guid jobId)
    {
        var job = await _fieldJobService.GetJobByIdAsync(jobId, IsAdminOrEngineer() ? null : GetUserId());
        if (job == null) return NotFound(new { message = "Job not found." });
        var assessment = await _fieldJobService.GetComplianceAssessmentAsync(jobId);
        if (assessment == null) return NotFound(new { message = "Compliance assessment not found for this job." });
        return Ok(assessment);
    }
}
