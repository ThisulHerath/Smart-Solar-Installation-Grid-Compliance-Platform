using System.Text.Json;
using SolarPlatform.Api.DTOs;

namespace SolarPlatform.Tests;

public class ComplianceContractTests
{
    [Fact]
    public void OutboundInspectionUsesPythonFieldNamesAndPreservesReadings()
    {
        var request = new EvaluateComplianceRequestDto(Guid.NewGuid(), Guid.NewGuid(), "ThreePhase", 3,
            63, true, 80, 20, "South", 48, 12, null, null, null, null, 400, 50, "Site review", "Measured");
        using var json = JsonDocument.Parse(JsonSerializer.Serialize(request, new JsonSerializerOptions(JsonSerializerDefaults.Web)));
        var data = json.RootElement;
        Assert.Equal("ThreePhase", data.GetProperty("grid_type").GetString());
        Assert.Equal(400, data.GetProperty("grid_voltage").GetDecimal());
        Assert.Equal(50, data.GetProperty("grid_frequency").GetDecimal());
        Assert.Equal(63, data.GetProperty("main_breaker_rating").GetDecimal());
        Assert.Equal(3, data.GetProperty("phase_count").GetInt32());
        Assert.True(data.GetProperty("inverter_location_suitable").GetBoolean());
        Assert.False(data.TryGetProperty("gridVoltage", out _));
    }
}
