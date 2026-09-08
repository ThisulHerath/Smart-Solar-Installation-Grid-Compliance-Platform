using System.Net.Http.Json;
using System.Text.Json;
using SolarPlatform.Api.DTOs;

namespace SolarPlatform.Api.Integrations;

public interface IAgenticAiService
{
    Task<(bool IsHealthy, string Message)> CheckHealthAsync(CancellationToken cancellationToken = default);
    Task<WorkflowTestResponseDto> ExecuteTestWorkflowAsync(WorkflowTestRequestDto request, CancellationToken cancellationToken = default);
    Task<SolarSizingResponseDto> ExecuteSolarSizingAsync(object request, CancellationToken cancellationToken = default);
}

public class AgenticAiService : IAgenticAiService
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;
    private readonly ILogger<AgenticAiService> _logger;

    public AgenticAiService(HttpClient httpClient, IConfiguration configuration, ILogger<AgenticAiService> logger)
    {
        _httpClient = httpClient;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<(bool IsHealthy, string Message)> CheckHealthAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync("/health", cancellationToken);
            if (response.IsSuccessStatusCode)
            {
                var content = await response.Content.ReadAsStringAsync(cancellationToken);
                return (true, "Agentic AI service is reachable and healthy.");
            }

            return (false, $"Agentic AI returned non-success status code: {response.StatusCode}");
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Agentic AI health check probe failed.");
            return (false, $"Agentic AI is currently unavailable: {ex.Message}");
        }
    }

    public async Task<WorkflowTestResponseDto> ExecuteTestWorkflowAsync(WorkflowTestRequestDto request, CancellationToken cancellationToken = default)
    {
        try
        {
            _logger.LogInformation("Forwarding test workflow objective to Python Agentic AI: {Objective}", request.Objective);

            var internalKey = _configuration["AgenticAi:InternalKey"] 
                ?? Environment.GetEnvironmentVariable("AGENTIC_AI_INTERNAL_KEY") 
                ?? "smart-solar-ai-internal-key-development";

            using var message = new HttpRequestMessage(HttpMethod.Post, "/workflow/test")
            {
                Content = JsonContent.Create(request)
            };
            message.Headers.Add("X-Internal-Key", internalKey);

            var response = await _httpClient.SendAsync(message, cancellationToken);
            
            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync(cancellationToken);
                _logger.LogError("Agentic AI service returned error {StatusCode}: {ErrorBody}", response.StatusCode, errorBody);

                return new WorkflowTestResponseDto
                {
                    WorkflowId = Guid.NewGuid().ToString(),
                    Objective = request.Objective,
                    CurrentStep = "failed",
                    ApprovalStatus = "error",
                    FinalOutcome = "Agentic AI execution failed with error status code from downstream service.",
                    Errors = new List<string> { $"AI Service error ({response.StatusCode}): {errorBody}" },
                    ExecutionLogs = new List<string> { "ASP.NET Core received non-200 response from Agentic AI service." }
                };
            }

            var result = await response.Content.ReadFromJsonAsync<WorkflowTestResponseDto>(cancellationToken: cancellationToken);
            return result ?? new WorkflowTestResponseDto
            {
                WorkflowId = Guid.NewGuid().ToString(),
                Objective = request.Objective,
                CurrentStep = "completed",
                FinalOutcome = "Empty response received from Agentic AI."
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to connect to Agentic AI service.");

            return new WorkflowTestResponseDto
            {
                WorkflowId = Guid.NewGuid().ToString(),
                Objective = request.Objective,
                CurrentStep = "failed",
                ApprovalStatus = "unavailable",
                FinalOutcome = "The Agentic AI service is currently unavailable or unreachable.",
                Errors = new List<string> { ex.Message },
                ExecutionLogs = new List<string> 
                { 
                    "ASP.NET Core attempted internal connection to Agentic AI.", 
                    "Downstream call failed gracefully without platform crash." 
                }
            };
        }
    }

    public async Task<SolarSizingResponseDto> ExecuteSolarSizingAsync(object request, CancellationToken cancellationToken = default)
    {
        var internalKey = _configuration["AgenticAi:InternalKey"] ?? Environment.GetEnvironmentVariable("AGENTIC_AI_INTERNAL_KEY") ?? "smart-solar-ai-internal-key-development";
        using var message = new HttpRequestMessage(HttpMethod.Post, "/workflow/solar-sizing") { Content = JsonContent.Create(request) };
        message.Headers.Add("X-Internal-Key", internalKey);
        try
        {
            var response = await _httpClient.SendAsync(message, cancellationToken);
            if (!response.IsSuccessStatusCode) return new SolarSizingResponseDto { Status = "failed", Errors = new List<string> { "Agentic AI service returned an error." } };
            return await response.Content.ReadFromJsonAsync<SolarSizingResponseDto>(cancellationToken: cancellationToken) ?? new SolarSizingResponseDto { Status = "failed", Errors = new List<string> { "Empty AI response." } };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Solar sizing workflow failed.");
            return new SolarSizingResponseDto { Status = "failed", Errors = new List<string> { "Agentic AI service is unavailable." } };
        }
    }
}
