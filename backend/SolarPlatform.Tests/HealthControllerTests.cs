using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Moq;
using SolarPlatform.Api.Controllers;
using SolarPlatform.Api.Data;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Integrations;

namespace SolarPlatform.Tests;

public class HealthControllerTests
{
    [Fact]
    public async Task GetHealth_WhenDependenciesAreHealthy_ReturnsHealthyStatus()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;
        var dbContext = new AppDbContext(options);

        var aiServiceMock = new Mock<IAgenticAiService>();
        aiServiceMock
            .Setup(s => s.CheckHealthAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync((true, "FastAPI is running"));

        var envMock = new Mock<IWebHostEnvironment>();
        envMock.Setup(e => e.EnvironmentName).Returns("Testing");

        var loggerMock = new Mock<ILogger<HealthController>>();

        var controller = new HealthController(dbContext, aiServiceMock.Object, envMock.Object, loggerMock.Object);

        var result = await controller.GetHealth(CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var response = Assert.IsType<HealthResponseDto>(okResult.Value);

        Assert.Equal("healthy", response.Status);
        Assert.Equal("connected", response.Database);
        Assert.Equal("available", response.AgenticAi);
    }

    [Fact]
    public async Task GetHealth_WhenAiServiceIsUnavailable_DoesNotCrashAndReturnsDegradedStatus()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;
        var dbContext = new AppDbContext(options);

        var aiServiceMock = new Mock<IAgenticAiService>();
        aiServiceMock
            .Setup(s => s.CheckHealthAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync((false, "Connection refused"));

        var envMock = new Mock<IWebHostEnvironment>();
        envMock.Setup(e => e.EnvironmentName).Returns("Testing");

        var loggerMock = new Mock<ILogger<HealthController>>();

        var controller = new HealthController(dbContext, aiServiceMock.Object, envMock.Object, loggerMock.Object);

        var result = await controller.GetHealth(CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var response = Assert.IsType<HealthResponseDto>(okResult.Value);

        Assert.Equal("degraded", response.Status);
        Assert.Equal("unavailable", response.AgenticAi);
    }
}
