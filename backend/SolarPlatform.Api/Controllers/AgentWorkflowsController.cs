using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Integrations;
using SolarPlatform.Api.Models;

namespace SolarPlatform.Api.Controllers;

[ApiController, Authorize(Roles = RoleConstants.Administrator + "," + RoleConstants.SeniorEngineer)]
[Route("api/agent-workflows")]
public class AgentWorkflowsController : ControllerBase
{
    private readonly IAgenticAiService _agenticAiService;
    private readonly ILogger<AgentWorkflowsController> _logger;

    public AgentWorkflowsController(IAgenticAiService agenticAiService, ILogger<AgentWorkflowsController> logger)
    {
        _agenticAiService = agenticAiService;
        _logger = logger;
    }

    [HttpPost("test")]
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
}
