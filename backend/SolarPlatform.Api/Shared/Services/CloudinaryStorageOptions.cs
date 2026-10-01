namespace SolarPlatform.Api.Services;

public sealed class CloudinaryStorageOptions
{
    public required string CloudName { get; init; }
    public required string ApiKey { get; init; }
    public required string ApiSecret { get; init; }
    public string RootFolder { get; init; } = "smart-solar";
}
