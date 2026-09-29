using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Moq;
using SolarPlatform.Api.Controllers;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Integrations;

namespace SolarPlatform.Tests;

public class LocationsControllerTests
{
    [Fact]
    public async Task Search_ReturnsValidatedGeocodingResults()
    {
        var service = new Mock<IGeocodingService>();
        var expected = new[]
        {
            new LocationSearchResultDto("Colombo, Sri Lanka", 6.9271m, 79.8612m),
        };
        service.Setup(x => x.SearchAsync("Colombo", It.IsAny<CancellationToken>()))
            .ReturnsAsync(expected);

        var controller = new LocationsController(service.Object);
        var result = await controller.Search("  Colombo  ", CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        Assert.Same(expected, ok.Value);
        service.Verify(x => x.SearchAsync("Colombo", It.IsAny<CancellationToken>()), Times.Once);
    }

    [Theory]
    [InlineData("")]
    [InlineData("ab")]
    public async Task Search_RejectsTooShortQueries(string query)
    {
        var service = new Mock<IGeocodingService>();
        var controller = new LocationsController(service.Object);

        var result = await controller.Search(query, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
        service.VerifyNoOtherCalls();
    }

    [Fact]
    public async Task Search_ReturnsServiceUnavailable_WhenProviderCannotBeReached()
    {
        var service = new Mock<IGeocodingService>();
        service.Setup(x => x.SearchAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new InvalidOperationException("Address search is temporarily unavailable."));
        var controller = new LocationsController(service.Object);

        var result = await controller.Search("Kandy", CancellationToken.None);

        var unavailable = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status503ServiceUnavailable, unavailable.StatusCode);
    }
}
