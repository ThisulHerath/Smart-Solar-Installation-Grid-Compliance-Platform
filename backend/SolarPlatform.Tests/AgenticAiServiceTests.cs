using System.Net;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Moq;
using Moq.Protected;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Integrations;

namespace SolarPlatform.Tests;

public class AgenticAiServiceTests
{
    [Theory]
    [InlineData(false)]
    [InlineData(true)]
    public async Task TestWorkflow_UsesPythonContract_AndFailsClosedOnEmptyResponse(bool emptyResponse)
    {
        using var handler = new WorkflowContractHandler(emptyResponse);
        using var client = new HttpClient(handler) { BaseAddress = new Uri("http://localhost:8001") };
        var config = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["AgenticAi:InternalKey"] = "test-key"
        }).Build();
        var service = new AgenticAiService(client, config, Mock.Of<ILogger<AgenticAiService>>());
        var result = await service.ExecuteTestWorkflowAsync(new WorkflowTestRequestDto
        {
            Objective = "Assess rooftop", CustomerId = "customer-42",
            InputData = new() { ["monthly_kwh"] = 600 }
        });
        Assert.Equal(emptyResponse ? "failed" : "completed", result.CurrentStep);
        if (emptyResponse) Assert.NotEmpty(result.Errors);
        else Assert.Single(result.ExecutionLogs);
    }

    private sealed class WorkflowContractHandler(bool emptyResponse) : HttpMessageHandler
    {
        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            Assert.Equal("/workflow/test", request.RequestUri!.AbsolutePath);
            Assert.Equal("test-key", request.Headers.GetValues("X-Internal-Key").Single());
            using var payload = System.Text.Json.JsonDocument.Parse(await request.Content!.ReadAsStringAsync(cancellationToken));
            Assert.Equal("customer-42", payload.RootElement.GetProperty("customer_id").GetString());
            Assert.Equal(600, payload.RootElement.GetProperty("input_data").GetProperty("monthly_kwh").GetInt32());
            return new(HttpStatusCode.OK)
            {
                Content = new StringContent(emptyResponse ? "null" : """
                    {"objective":"Assess rooftop","current_step":"completed","execution_logs":["validated"]}
                    """)
            };
        }
    }

    [Fact]
    public async Task CheckHealthAsync_WhenServerReturnsOk_ReturnsTrue()
    {
        var handlerMock = new Mock<HttpMessageHandler>();
        handlerMock
            .Protected()
            .Setup<Task<HttpResponseMessage>>(
                "SendAsync",
                ItExpr.IsAny<HttpRequestMessage>(),
                ItExpr.IsAny<CancellationToken>()
            )
            .ReturnsAsync(new HttpResponseMessage
            {
                StatusCode = HttpStatusCode.OK,
                Content = new StringContent("{\"status\":\"healthy\"}")
            });

        var httpClient = new HttpClient(handlerMock.Object) { BaseAddress = new Uri("http://localhost:8000") };
        var config = new ConfigurationBuilder().Build();
        var loggerMock = new Mock<ILogger<AgenticAiService>>();

        var service = new AgenticAiService(httpClient, config, loggerMock.Object);

        var (isHealthy, message) = await service.CheckHealthAsync();

        Assert.True(isHealthy);
        Assert.Contains("healthy", message);
    }

    [Fact]
    public async Task ExecuteTestWorkflowAsync_WhenHttpRequestFails_ReturnsSafeFailureDtoWithoutThrowing()
    {
        var handlerMock = new Mock<HttpMessageHandler>();
        handlerMock
            .Protected()
            .Setup<Task<HttpResponseMessage>>(
                "SendAsync",
                ItExpr.IsAny<HttpRequestMessage>(),
                ItExpr.IsAny<CancellationToken>()
            )
            .ThrowsAsync(new HttpRequestException("Connection refused"));

        var httpClient = new HttpClient(handlerMock.Object) { BaseAddress = new Uri("http://localhost:8000") };
        var config = new ConfigurationBuilder().Build();
        var loggerMock = new Mock<ILogger<AgenticAiService>>();

        var service = new AgenticAiService(httpClient, config, loggerMock.Object);

        var result = await service.ExecuteTestWorkflowAsync(new WorkflowTestRequestDto { Objective = "Test Objective" });

        Assert.NotNull(result);
        Assert.Equal("failed", result.CurrentStep);
        Assert.NotEmpty(result.Errors);
    }

    [Theory]
    [InlineData(true, "/workflow/start")]
    [InlineData(false, "/workflow/resume")]
    public async Task StructuredWorkflow_UsesAuthenticatedStartAndResumeContracts(bool start, string expectedPath)
    {
        using var handler = new StructuredWorkflowContractHandler(expectedPath);
        using var client = new HttpClient(handler) { BaseAddress = new Uri("http://localhost:8001") };
        var config = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["AgenticAi:InternalKey"] = "structured-test-key"
        }).Build();
        var service = new AgenticAiService(client, config, Mock.Of<ILogger<AgenticAiService>>());

        var result = start
            ? await service.StartStructuredWorkflowAsync(new { workflow_id = "wf-42", objective = "Prepare installation" })
            : await service.ResumeStructuredWorkflowAsync(new { workflow_id = "wf-42", @event = "INSPECTION_COMPLETED", state = new { } });

        Assert.NotNull(result);
        Assert.Equal("wf-42", result.WorkflowId);
        Assert.Equal("WAITING_FOR_INSPECTION", result.WorkflowStatus);
        Assert.Equal("site-inspection", result.CurrentStepId);
        Assert.Equal("NOT_REQUESTED", result.ApprovalStatus);
    }

    private sealed class StructuredWorkflowContractHandler(string expectedPath) : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            Assert.Equal(expectedPath, request.RequestUri!.AbsolutePath);
            Assert.Equal("structured-test-key", request.Headers.GetValues("X-Internal-Key").Single());
            return Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent("""
                    {"workflow_id":"wf-42","objective":"Prepare installation","workflow_type":"FULL_INSTALLATION","workflow_status":"WAITING_FOR_INSPECTION","current_step_id":"site-inspection","approval_status":"NOT_REQUESTED","plan":[],"structured_plan":[],"completed_steps":[],"failed_steps":[],"agent_outputs":{},"tool_results":{},"validation_results":{},"execution_logs":[],"errors":[],"retry_count":0,"final_outcome":""}
                    """, System.Text.Encoding.UTF8, "application/json")
            });
        }
    }
}
