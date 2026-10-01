using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SolarPlatform.Api.Data;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Integrations;

namespace SolarPlatform.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class HealthController : ControllerBase
{
    private readonly AppDbContext _dbContext;
    private readonly IAgenticAiService _agenticAiService;
    private readonly IWebHostEnvironment _environment;
    private readonly ILogger<HealthController> _logger;

    public HealthController(
        AppDbContext dbContext,
        IAgenticAiService agenticAiService,
        IWebHostEnvironment environment,
        ILogger<HealthController> logger)
    {
        _dbContext = dbContext;
        _agenticAiService = agenticAiService;
        _environment = environment;
        _logger = logger;
    }

    [HttpGet]
    [ProducesResponseType(typeof(HealthResponseDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetHealth(CancellationToken cancellationToken)
    {
        var response = new HealthResponseDto
        {
            Status = "healthy",
            Environment = _environment.EnvironmentName,
            Timestamp = DateTime.UtcNow
        };

        // Check Database Connectivity
        try
        {
            var canConnect = await _dbContext.Database.CanConnectAsync(cancellationToken);
            if (canConnect)
            {
                response.Database = "connected";
                response.Details["database"] = "Neon Managed PostgreSQL is reachable and operational.";
            }
            else
            {
                response.Database = "unreachable";
                response.Status = "degraded";
                response.Details["database"] = "Cannot establish connection to database.";
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Database probe failed during health check.");
            response.Database = "unavailable";
            response.Status = "degraded";
            response.Details["database"] = $"Database connection error: {ex.Message}";
        }

        // Check Agentic AI Connectivity
        try
        {
            var (isHealthy, message) = await _agenticAiService.CheckHealthAsync(cancellationToken);
            if (isHealthy)
            {
                response.AgenticAi = "available";
                response.Details["agenticAi"] = message;
            }
            else
            {
                response.AgenticAi = "unavailable";
                response.Status = "degraded";
                response.Details["agenticAi"] = message;
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Agentic AI probe failed during health check.");
            response.AgenticAi = "unavailable";
            response.Status = "degraded";
            response.Details["agenticAi"] = $"AI service error: {ex.Message}";
        }

        return Ok(response);
    }
}
