using SolarPlatform.Api.DTOs;

namespace SolarPlatform.Api.Integrations;

public interface IEquipmentPricingClient
{
    Task<PricingResult> PriceAsync(object payload, CancellationToken ct);
}

public class EquipmentPricingClient(HttpClient http, IConfiguration configuration) : IEquipmentPricingClient
{
    public async Task<PricingResult> PriceAsync(object payload, CancellationToken ct)
    {
        var key = Environment.GetEnvironmentVariable("AGENTIC_AI_INTERNAL_KEY") ?? configuration["AgenticAi:InternalKey"];
        if (string.IsNullOrWhiteSpace(key)) throw new InvalidOperationException("Pricing service authentication is not configured.");
        using var request = new HttpRequestMessage(HttpMethod.Post, "/workflow/equipment-pricing") { Content = JsonContent.Create(payload) };
        request.Headers.Add("X-Internal-Key", key);
        using var response = await http.SendAsync(request, ct);
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<PricingResult>(cancellationToken: ct)
            ?? throw new InvalidOperationException("Empty pricing response.");
    }
}
