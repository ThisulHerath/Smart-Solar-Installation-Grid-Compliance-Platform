using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Models;
using SolarPlatform.Api.Services;

namespace SolarPlatform.Api.Controllers;

[ApiController, Authorize]
[Route("api/proposals")]
public class ProposalsController : ControllerBase
{
    private readonly IProposalService _service;
    public ProposalsController(IProposalService service) => _service = service;

    // GET /api/proposals — Senior Engineer / Admin sees all proposals
    [HttpGet, Authorize(Roles = $"{RoleConstants.SeniorEngineer},{RoleConstants.Administrator}")]
    public async Task<IActionResult> List(CancellationToken ct)
    {
        var proposals = await _service.GetAllAsync(ct);
        return Ok(proposals);
    }

    // GET /api/proposals/pending — pending approval queue
    [HttpGet("pending"), Authorize(Roles = $"{RoleConstants.SeniorEngineer},{RoleConstants.Administrator}")]
    public async Task<IActionResult> Pending(CancellationToken ct)
    {
        var proposals = await _service.GetPendingAsync(ct);
        return Ok(proposals);
    }

    // GET /api/proposals/survey/{surveyId} — homeowner status check + staff view
    [HttpGet("survey/{surveyId:guid}")]
    public async Task<IActionResult> BySurvey(Guid surveyId, CancellationToken ct)
    {
        var isStaff = User.IsInRole(RoleConstants.SeniorEngineer) || User.IsInRole(RoleConstants.Administrator);
        var proposals = await _service.GetBySurveyAsync(surveyId, UserId(), isStaff, ct);
        return Ok(proposals);
    }

    // GET /api/proposals/{id}
    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Get(Guid id, CancellationToken ct)
    {
        var isStaff = User.IsInRole(RoleConstants.SeniorEngineer) || User.IsInRole(RoleConstants.Administrator);
        var proposal = await _service.GetAsync(id, UserId(), isStaff, ct);
        return proposal == null ? NotFound() : Ok(proposal);
    }

    // POST /api/proposals — homeowner initiates proposal from a completed survey
    [HttpPost, Authorize(Roles = RoleConstants.Homeowner)]
    public async Task<IActionResult> Create([FromBody] CreateProposalRequestDto request, CancellationToken ct)
    {
        if (!ModelState.IsValid) return ValidationProblem(ModelState);
        try
        {
            var proposal = await _service.CreateAsync(request.SolarSurveyId, UserId(), request.Notes, ct);
            return CreatedAtAction(nameof(Get), new { id = proposal.Id }, proposal);
        }
        catch (ArgumentException ex) { return NotFound(new { message = ex.Message }); }
        catch (UnauthorizedAccessException) { return Forbid(); }
    }

    // POST /api/proposals/{id}/approve
    [HttpPost("{id:guid}/approve"), Authorize(Roles = $"{RoleConstants.SeniorEngineer},{RoleConstants.Administrator}")]
    public async Task<IActionResult> Approve(Guid id, [FromBody] ApproveProposalRequestDto request, CancellationToken ct)
    {
        try
        {
            var proposal = await _service.ApproveAsync(id, UserId(), request.Comment, ct);
            return Ok(proposal);
        }
        catch (ArgumentException ex) { return NotFound(new { message = ex.Message }); }
        catch (InvalidOperationException ex) { return Conflict(new { message = ex.Message }); }
    }

    // POST /api/proposals/{id}/reject
    [HttpPost("{id:guid}/reject"), Authorize(Roles = $"{RoleConstants.SeniorEngineer},{RoleConstants.Administrator}")]
    public async Task<IActionResult> Reject(Guid id, [FromBody] RejectProposalRequestDto request, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(request.Comment))
            return BadRequest(new { message = "A comment is required when rejecting a proposal." });
        try
        {
            var proposal = await _service.RejectAsync(id, UserId(), request.Comment, ct);
            return Ok(proposal);
        }
        catch (ArgumentException ex) { return NotFound(new { message = ex.Message }); }
        catch (InvalidOperationException ex) { return Conflict(new { message = ex.Message }); }
    }

    // POST /api/proposals/{id}/revise
    [HttpPost("{id:guid}/revise"), Authorize(Roles = $"{RoleConstants.SeniorEngineer},{RoleConstants.Administrator}")]
    public async Task<IActionResult> Revise(Guid id, [FromBody] ReviseProposalRequestDto request, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(request.Comment))
            return BadRequest(new { message = "A comment is required when requesting a revision." });
        try
        {
            var proposal = await _service.RequestRevisionAsync(id, UserId(), request.Comment, ct);
            return Ok(proposal);
        }
        catch (ArgumentException ex) { return NotFound(new { message = ex.Message }); }
        catch (InvalidOperationException ex) { return Conflict(new { message = ex.Message }); }
    }

    private Guid UserId() =>
        Guid.TryParse(
            User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub"),
            out var id)
            ? id
            : throw new UnauthorizedAccessException("Invalid token user identity.");
}
