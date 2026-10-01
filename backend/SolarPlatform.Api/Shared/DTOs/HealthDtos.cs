namespace SolarPlatform.Api.DTOs;

public class HealthResponseDto
{
    public string Status { get; set; } = "healthy";
    public string Environment { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    public string Database { get; set; } = "unknown";
    public string AgenticAi { get; set; } = "unknown";
    public Dictionary<string, string> Details { get; set; } = new();
}
