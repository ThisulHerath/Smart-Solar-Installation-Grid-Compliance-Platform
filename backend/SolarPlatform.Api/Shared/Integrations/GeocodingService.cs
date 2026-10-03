using System.Globalization;
using System.Text.Json.Serialization;
using Microsoft.Extensions.Caching.Memory;
using SolarPlatform.Api.DTOs;

namespace SolarPlatform.Api.Integrations;

public interface IGeocodingService
{
    Task<IReadOnlyList<LocationSearchResultDto>> SearchAsync(string query, CancellationToken cancellationToken);
    Task<LocationSearchResultDto?> ReverseAsync(decimal latitude, decimal longitude, CancellationToken cancellationToken);
}

public sealed class NominatimGeocodingService : IGeocodingService
{
    private static readonly SemaphoreSlim RequestGate = new(1, 1);
    private static DateTime _lastRequestUtc = DateTime.MinValue;
    private readonly HttpClient _httpClient;
    private readonly IMemoryCache _cache;
    private readonly ILogger<NominatimGeocodingService> _logger;

    public NominatimGeocodingService(HttpClient httpClient, IMemoryCache cache, ILogger<NominatimGeocodingService> logger)
    {
        _httpClient = httpClient;
        _cache = cache;
        _logger = logger;
    }

    public async Task<IReadOnlyList<LocationSearchResultDto>> SearchAsync(string query, CancellationToken cancellationToken)
    {
        var normalized = string.Join(' ', query.Trim().Split(' ', StringSplitOptions.RemoveEmptyEntries));
        var cacheKey = $"geocode:lk:{normalized.ToLowerInvariant()}";
        if (_cache.TryGetValue(cacheKey, out IReadOnlyList<LocationSearchResultDto>? cached) && cached != null)
        {
            return cached;
        }

        await RequestGate.WaitAsync(cancellationToken);
        try
        {
            var wait = TimeSpan.FromSeconds(1) - (DateTime.UtcNow - _lastRequestUtc);
            if (wait > TimeSpan.Zero) await Task.Delay(wait, cancellationToken);

            var path = $"search?format=jsonv2&countrycodes=lk&limit=5&addressdetails=1&q={Uri.EscapeDataString(normalized)}";
            var response = await _httpClient.GetAsync(path, cancellationToken);
            _lastRequestUtc = DateTime.UtcNow;
            response.EnsureSuccessStatusCode();
            var rows = await response.Content.ReadFromJsonAsync<List<NominatimResult>>(cancellationToken: cancellationToken) ?? [];
            var results = rows
                .Select(row => new
                {
                    row.DisplayName,
                    Latitude = ParseCoordinate(row.Latitude),
                    Longitude = ParseCoordinate(row.Longitude),
                })
                .Where(row => row.Latitude.HasValue && row.Longitude.HasValue && !string.IsNullOrWhiteSpace(row.DisplayName))
                .Select(row => new LocationSearchResultDto(row.DisplayName!, row.Latitude!.Value, row.Longitude!.Value))
                .ToList();

            _cache.Set(cacheKey, results, TimeSpan.FromHours(12));
            return results;
        }
        catch (HttpRequestException ex)
        {
            _logger.LogWarning(ex, "Address lookup failed for a Sri Lankan property query.");
            throw new InvalidOperationException("Address search is temporarily unavailable. You can still choose the location directly on the map.");
        }
        finally
        {
            RequestGate.Release();
        }
    }

    public async Task<LocationSearchResultDto?> ReverseAsync(
        decimal latitude,
        decimal longitude,
        CancellationToken cancellationToken)
    {
        var latitudeText = latitude.ToString("0.######", CultureInfo.InvariantCulture);
        var longitudeText = longitude.ToString("0.######", CultureInfo.InvariantCulture);
        var cacheKey = $"reverse-geocode:{latitudeText}:{longitudeText}";
        if (_cache.TryGetValue(cacheKey, out LocationSearchResultDto? cached))
        {
            return cached;
        }

        await RequestGate.WaitAsync(cancellationToken);
        try
        {
            var wait = TimeSpan.FromSeconds(1) - (DateTime.UtcNow - _lastRequestUtc);
            if (wait > TimeSpan.Zero) await Task.Delay(wait, cancellationToken);

            var path = $"reverse?format=jsonv2&lat={latitudeText}&lon={longitudeText}&zoom=18&addressdetails=1";
            var response = await _httpClient.GetAsync(path, cancellationToken);
            _lastRequestUtc = DateTime.UtcNow;
            response.EnsureSuccessStatusCode();
            var row = await response.Content.ReadFromJsonAsync<NominatimResult>(cancellationToken: cancellationToken);
            var displayName = row?.DisplayName?.Trim();
            var result = string.IsNullOrWhiteSpace(displayName)
                ? null
                : new LocationSearchResultDto(displayName, latitude, longitude);

            if (result != null)
            {
                _cache.Set(cacheKey, result, TimeSpan.FromHours(12));
            }
            return result;
        }
        catch (HttpRequestException ex)
        {
            _logger.LogWarning(ex, "Reverse address lookup failed for coordinates {Latitude}, {Longitude}.", latitude, longitude);
            throw new InvalidOperationException("The address for this map point is temporarily unavailable. The selected coordinates are still saved.");
        }
        finally
        {
            RequestGate.Release();
        }
    }

    private static decimal? ParseCoordinate(string? value) =>
        decimal.TryParse(value, NumberStyles.Float, CultureInfo.InvariantCulture, out var parsed) ? parsed : null;

    private sealed class NominatimResult
    {
        [JsonPropertyName("display_name")] public string? DisplayName { get; init; }
        [JsonPropertyName("lat")] public string? Latitude { get; init; }
        [JsonPropertyName("lon")] public string? Longitude { get; init; }
    }
}
