using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Hosting;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.Extensions.Logging;
using SolarPlatform.Api.Authentication;
using SolarPlatform.Api.Data;
using SolarPlatform.Api.Models;

namespace SolarPlatform.Tests;

public class InventoryApiTests
{
    private sealed class Factory : WebApplicationFactory<Program>
    {
        protected override IHost CreateHost(IHostBuilder builder)
        {
            builder.ConfigureHostConfiguration(config => config.AddInMemoryCollection(new Dictionary<string, string?> {
                ["Jwt:Key"] = "integration-test-key-only-at-least-thirty-two-characters", ["Jwt:Issuer"] = "tests", ["Jwt:Audience"] = "tests" }));
            return base.CreateHost(builder);
        }
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.UseEnvironment("Testing");
            builder.ConfigureAppConfiguration((_, config) => config.AddInMemoryCollection(new Dictionary<string, string?> {
                ["Jwt:Key"] = "integration-test-key-only-at-least-thirty-two-characters", ["Jwt:Issuer"] = "tests", ["Jwt:Audience"] = "tests" }));
            builder.ConfigureServices(services => {
                services.AddDataProtection().UseEphemeralDataProtectionProvider();
                services.AddLogging(logging => logging.ClearProviders());
                services.RemoveAll<DbContextOptions<AppDbContext>>();
                services.AddDbContext<AppDbContext>(options => options.UseInMemoryDatabase("inventory-api-" + GetHashCode()));
            });
        }
        public HttpClient Client(string? role = null, Guid? userId = null)
        {
            var client = CreateClient();
            if (role != null)
            {
                using var scope = Services.CreateScope();
                var token = scope.ServiceProvider.GetRequiredService<IJwtTokenService>().GenerateToken(new User { Id = userId ?? Guid.NewGuid(), Email = "test@example.invalid", FullName = "Test" }, new List<string> { role }).Token;
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
            }
            return client;
        }
    }
    [Theory]
    [InlineData(null, HttpStatusCode.Unauthorized)]
    [InlineData("HOMEOWNER", HttpStatusCode.Forbidden)]
    [InlineData("FIELD_TECHNICIAN", HttpStatusCode.Forbidden)]
    [InlineData("SENIOR_ENGINEER", HttpStatusCode.OK)]
    [InlineData("INVENTORY_OFFICER", HttpStatusCode.OK)]
    [InlineData("ADMINISTRATOR", HttpStatusCode.OK)]
    public async Task ReadPolicyIsEnforcedByHttpPipeline(string? role, HttpStatusCode expected)
    {
        using var factory = new Factory(); using var client = factory.Client(role);
        Assert.Equal(expected, (await client.GetAsync("/api/inventory")).StatusCode);
    }
    [Theory]
    [InlineData("HOMEOWNER")]
    [InlineData("SENIOR_ENGINEER")]
    public async Task NonInventoryStaffCannotReserve(string role)
    {
        using var factory = new Factory(); using var client = factory.Client(role);
        Assert.Equal(HttpStatusCode.Forbidden, (await client.PostAsJsonAsync("/api/inventory/reserve", new { quoteId = Guid.NewGuid() })).StatusCode);
    }
    [Fact]
    public async Task HomeownerCannotReadAnotherOwnersEquipment()
    {
        using var factory = new Factory(); using var owner = factory.Client("HOMEOWNER");
        Guid proposalId;
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var profile = new CustomerProfile { UserId = Guid.NewGuid() };
            var survey = new SolarSurvey { Customer = profile };
            var proposal = new EngineeringProposal { SolarSurvey = survey }; proposalId = proposal.Id;
            db.Add(proposal); await db.SaveChangesAsync();
        }
        Assert.Equal(HttpStatusCode.NotFound, (await owner.GetAsync($"/api/inventory/proposals/{proposalId}/equipment")).StatusCode);
        using var anonymous = factory.Client();
        Assert.Equal(HttpStatusCode.Unauthorized, (await anonymous.GetAsync($"/api/inventory/proposals/{proposalId}/equipment")).StatusCode);
    }
}
