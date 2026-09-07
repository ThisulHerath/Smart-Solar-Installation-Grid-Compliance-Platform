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
}
