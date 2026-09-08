using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Models;
using SolarPlatform.Api.Services;

namespace SolarPlatform.Api.Controllers;

[ApiController, Authorize]
[Route("api/surveys")]
public class SurveysController : ControllerBase
{
    private readonly ISurveyService _service;
    public SurveysController(ISurveyService service) => _service = service;

    [HttpPost, Authorize(Roles = RoleConstants.Homeowner)]
    public async Task<IActionResult> Create(SurveyRequestDto request)
    {
        if (!ModelState.IsValid) return ValidationProblem(ModelState);
        try
        {
            var survey = await _service.CreateAsync(UserId(), request);
            return CreatedAtAction(nameof(Get), new { id = survey.Id }, survey);
        }
        catch (ArgumentException ex) { return BadRequest(new { message = ex.Message }); }
    }

    [HttpGet]
    public async Task<IActionResult> List()
    {
        var staff = User.IsInRole(RoleConstants.SeniorEngineer) || User.IsInRole(RoleConstants.Administrator);
        return Ok(staff ? await _service.GetAllAsync() : await _service.GetMineAsync(UserId()));
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Get(Guid id)
    {
        var staff = User.IsInRole(RoleConstants.SeniorEngineer) || User.IsInRole(RoleConstants.Administrator);
        var survey = await _service.GetAsync(UserId(), id, staff);
        return survey == null ? NotFound() : Ok(survey);
    }

    [HttpPut("{id:guid}"), Authorize(Roles = RoleConstants.Homeowner)]
    public async Task<IActionResult> Update(Guid id, SurveyRequestDto request)
    {
        if (!ModelState.IsValid) return ValidationProblem(ModelState);
        try { var survey = await _service.UpdateAsync(UserId(), id, request); return survey == null ? NotFound() : Ok(survey); }
        catch (ArgumentException ex) { return BadRequest(new { message = ex.Message }); }
        catch (InvalidOperationException ex) { return Conflict(new { message = ex.Message }); }
    }

    [HttpPost("{id:guid}/submit"), Authorize(Roles = RoleConstants.Homeowner)]
    public async Task<IActionResult> Submit(Guid id)
    {
        try { var survey = await _service.SubmitAsync(UserId(), id); return survey == null ? NotFound() : Ok(survey); }
        catch (InvalidOperationException ex) { return Conflict(new { message = ex.Message }); }
    }

    [HttpPost("{id:guid}/images"), Authorize(Roles = RoleConstants.Homeowner)]
    [RequestSizeLimit(5 * 1024 * 1024)]
    public async Task<IActionResult> UploadImage(Guid id, IFormFile file, [FromForm] SurveyImageType imageType)
    {
        var allowed = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase) { [".jpg"] = "image/jpeg", [".jpeg"] = "image/jpeg", [".png"] = "image/png" };
        var extension = Path.GetExtension(file.FileName);
        if (file.Length <= 0 || file.Length > 5 * 1024 * 1024 || !allowed.TryGetValue(extension, out var mime) || !string.Equals(file.ContentType, mime, StringComparison.OrdinalIgnoreCase)) return BadRequest(new { message = "Only JPEG and PNG images up to 5 MB are accepted." });
        var safeName = $"{Guid.NewGuid():N}{extension.ToLowerInvariant()}";
        var uploadRoot = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads");
        Directory.CreateDirectory(uploadRoot);
        await using (var stream = System.IO.File.Create(Path.Combine(uploadRoot, safeName))) await file.CopyToAsync(stream);
        try { var survey = await _service.AddImageAsync(UserId(), id, imageType, $"/uploads/{safeName}", Path.GetFileName(file.FileName)); return survey == null ? NotFound() : Ok(survey); }
        catch (InvalidOperationException ex) { return Conflict(new { message = ex.Message }); }
    }

    [HttpGet("{id:guid}/status")]
    public async Task<IActionResult> Status(Guid id)
    {
        var staff = User.IsInRole(RoleConstants.SeniorEngineer) || User.IsInRole(RoleConstants.Administrator);
        var survey = await _service.GetAsync(UserId(), id, staff);
        return survey == null ? NotFound() : Ok(new { survey.Id, survey.SurveyStatus, survey.Workflows });
    }

    private Guid UserId() => Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub"), out var id) ? id : throw new UnauthorizedAccessException("Invalid token user identity.");
}
