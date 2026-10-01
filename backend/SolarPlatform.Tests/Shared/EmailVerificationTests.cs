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
using SolarPlatform.Api.Authentication;
using SolarPlatform.Api.Data;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Models;
using SolarPlatform.Api.Services;

namespace SolarPlatform.Tests;

public class EmailVerificationTests
{
    private class TestClock : TimeProvider
    {
        public DateTimeOffset Time = DateTimeOffset.UtcNow;
        public override DateTimeOffset GetUtcNow() => Time;
    }
    private class Mailbox : IOtpEmailSender
    {
        public string Code = "";
        public bool Fail;
        public Task SendAsync(string email, string code, string purpose) { if (Fail) throw new EmailDeliveryException(); Code = code; return Task.CompletedTask; }
    }
    private sealed class Factory : WebApplicationFactory<Program>
    {
        public readonly Mailbox Mail = new();
        public readonly TestClock Clock = new();
        private static readonly Dictionary<string, string?> Settings = new() {
            ["Jwt:Key"] = "otp-integration-test-key-at-least-thirty-two-characters", ["Jwt:Issuer"] = "otp-tests", ["Jwt:Audience"] = "otp-tests" };
        protected override IHost CreateHost(IHostBuilder builder) { builder.ConfigureHostConfiguration(c => c.AddInMemoryCollection(Settings)); return base.CreateHost(builder); }
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.UseEnvironment("Testing");
            builder.ConfigureAppConfiguration((_, c) => c.AddInMemoryCollection(Settings));
            builder.ConfigureServices(services => {
                services.RemoveAll<DbContextOptions<AppDbContext>>();
                services.AddDbContext<AppDbContext>(o => o.UseInMemoryDatabase("otp-" + GetHashCode()));
                services.RemoveAll<IOtpEmailSender>(); services.AddSingleton<IOtpEmailSender>(Mail);
                services.RemoveAll<TimeProvider>(); services.AddSingleton<TimeProvider>(Clock);
            });
        }
        public async Task<EmailChallengeResponse> Request(HttpClient client, string email = "owner@example.invalid")
        {
            var response = await client.PostAsJsonAsync("/api/auth/register/request-otp", new { email, password = "A long passphrase!123", fullName = "Solar Owner", role = "ADMINISTRATOR" });
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            var json = await response.Content.ReadAsStringAsync(); Assert.DoesNotContain(Mail.Code, json);
            return (await response.Content.ReadFromJsonAsync<EmailChallengeResponse>())!;
        }
        public async Task<AuthResponseDto> Register(HttpClient client)
        {
            var challenge = await Request(client);
            var response = await client.PostAsJsonAsync("/api/auth/register", new { challengeId = challenge.ChallengeId, code = Mail.Code });
            response.EnsureSuccessStatusCode();
            var auth = (await response.Content.ReadFromJsonAsync<AuthResponseDto>())!;
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", auth.Token);
            return auth;
        }
    }

    [Fact]
    public async Task RegistrationRequiresCodeCreatesOnlyHomeownerAndPreventsReplay()
    {
        using var f = new Factory(); using var c = f.CreateClient();
        var challenge = await f.Request(c);
        using (var scope = f.Services.CreateScope()) {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            Assert.False(await db.Users.AnyAsync(u => u.Email == "owner@example.invalid"));
            var stored = await db.EmailChallenges.SingleAsync(); Assert.NotEqual(f.Mail.Code, stored.CodeHash); Assert.DoesNotContain("A long", stored.PasswordHash!);
        }
        Assert.Equal(HttpStatusCode.Unauthorized, (await c.PostAsJsonAsync("/api/auth/login", new { email = "owner@example.invalid", password = "A long passphrase!123" })).StatusCode);
        var code = f.Mail.Code;
        var result = await c.PostAsJsonAsync("/api/auth/register", new { challengeId = challenge.ChallengeId, code });
        Assert.Equal(HttpStatusCode.OK, result.StatusCode);
        var auth = (await result.Content.ReadFromJsonAsync<AuthResponseDto>())!;
        Assert.Equal(new[] { "HOMEOWNER" }, auth.User.Roles);
        Assert.Equal(HttpStatusCode.BadRequest, (await c.PostAsJsonAsync("/api/auth/register", new { challengeId = challenge.ChallengeId, code })).StatusCode);
        using var finalScope = f.Services.CreateScope(); var finalDb = finalScope.ServiceProvider.GetRequiredService<AppDbContext>();
        Assert.Null((await finalDb.EmailChallenges.SingleAsync()).PasswordHash);
        Assert.NotNull((await finalDb.Users.SingleAsync(u => u.Id == auth.User.Id)).EmailVerifiedAt);
    }

    [Fact]
    public async Task OldRegistrationBodyCannotBypassVerification()
    {
        using var f = new Factory(); using var c = f.CreateClient();
        Assert.Equal(HttpStatusCode.BadRequest, (await c.PostAsJsonAsync("/api/auth/register", new { email = "bypass@example.invalid", fullName = "Bypass", password = "A long passphrase!123" })).StatusCode);
    }

    [Theory]
    [InlineData(true)] [InlineData(false)]
    public async Task ExpiredOrFiveIncorrectCodesCannotBeUsed(bool expired)
    {
        using var f = new Factory(); using var c = f.CreateClient(); var challenge = await f.Request(c); var code = f.Mail.Code;
        if (expired) f.Clock.Time = f.Clock.Time.AddMinutes(11);
        else for (var i = 0; i < 5; i++) Assert.Equal(HttpStatusCode.BadRequest, (await c.PostAsJsonAsync("/api/auth/register", new { challengeId = challenge.ChallengeId, code = code == "000000" ? "111111" : "000000" })).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await c.PostAsJsonAsync("/api/auth/register", new { challengeId = challenge.ChallengeId, code })).StatusCode);
    }

    [Fact]
    public async Task ResendThrottlesAndInvalidatesPreviousCode()
    {
        using var f = new Factory(); using var c = f.CreateClient(); var old = await f.Request(c); var oldCode = f.Mail.Code;
        var body = new { email = "owner@example.invalid", password = "A long passphrase!123", fullName = "Owner" };
        Assert.Equal(HttpStatusCode.TooManyRequests, (await c.PostAsJsonAsync("/api/auth/register/request-otp", body)).StatusCode);
        f.Clock.Time = f.Clock.Time.AddSeconds(61); await f.Request(c);
        Assert.Equal(HttpStatusCode.BadRequest, (await c.PostAsJsonAsync("/api/auth/register", new { challengeId = old.ChallengeId, code = oldCode })).StatusCode);
    }

    [Fact]
    public async Task MailFailureCreatesNoAccountAndNoUsableChallenge()
    {
        using var f = new Factory(); using var c = f.CreateClient(); f.Mail.Fail = true;
        Assert.Equal(HttpStatusCode.ServiceUnavailable, (await c.PostAsJsonAsync("/api/auth/register/request-otp", new { email = "owner@example.invalid", password = "A long passphrase!123", fullName = "Owner" })).StatusCode);
        using var scope = f.Services.CreateScope(); var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        Assert.False(await db.Users.AnyAsync(u => u.Email == "owner@example.invalid"));
        Assert.NotNull((await db.EmailChallenges.SingleAsync()).ConsumedAt);
    }

    [Fact]
    public async Task PasswordChangeRequiresCorrectPurposeAndRevokesOldSessions()
    {
        using var f = new Factory(); using var c = f.CreateClient(); await f.Register(c); f.Clock.Time = f.Clock.Time.AddSeconds(61);
        var response = await c.PostAsJsonAsync("/api/auth/password/request-otp", new { newPassword = "My newer passphrase!123" }); response.EnsureSuccessStatusCode();
        var challenge = (await response.Content.ReadFromJsonAsync<EmailChallengeResponse>())!;
        var confirmation = new { challengeId = challenge.ChallengeId, code = f.Mail.Code };
        Assert.Equal(HttpStatusCode.BadRequest, (await c.PostAsJsonAsync("/api/auth/account-deletion/confirm", confirmation)).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await c.GetAsync("/api/auth/me")).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await c.PostAsJsonAsync("/api/auth/password/confirm", confirmation)).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await c.GetAsync("/api/auth/me")).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await c.PostAsJsonAsync("/api/auth/login", new { email = "owner@example.invalid", password = "A long passphrase!123" })).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await c.PostAsJsonAsync("/api/auth/login", new { email = "owner@example.invalid", password = "My newer passphrase!123" })).StatusCode);
    }

    [Fact]
    public async Task DeletionIsBoundToOwnerAndPreservesAuditLinkedRecords()
    {
        using var f = new Factory(); using var c = f.CreateClient(); var auth = await f.Register(c); f.Clock.Time = f.Clock.Time.AddSeconds(61);
        using (var scope = f.Services.CreateScope()) {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.CustomerProfiles.Add(new CustomerProfile { UserId = auth.User.Id, FullName = "Solar Owner", Address = "Test address", PhoneNumber = "+94770000000" }); await db.SaveChangesAsync();
        }
        var response = await c.PostAsJsonAsync("/api/auth/account-deletion/request-otp", new {}); response.EnsureSuccessStatusCode();
        var challenge = (await response.Content.ReadFromJsonAsync<EmailChallengeResponse>())!;
        var body = new { challengeId = challenge.ChallengeId, code = f.Mail.Code };
        using var stranger = f.CreateClient(); var otherChallenge = await f.Request(stranger, "stranger@example.invalid");
        var other = (await (await stranger.PostAsJsonAsync("/api/auth/register", new { challengeId = otherChallenge.ChallengeId, code = f.Mail.Code })).Content.ReadFromJsonAsync<AuthResponseDto>())!;
        stranger.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", other.Token);
        Assert.Equal(HttpStatusCode.BadRequest, (await stranger.PostAsJsonAsync("/api/auth/account-deletion/confirm", body)).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await c.PostAsJsonAsync("/api/auth/account-deletion/confirm", body)).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await c.GetAsync("/api/auth/me")).StatusCode);
        using var finalScope = f.Services.CreateScope(); var finalDb = finalScope.ServiceProvider.GetRequiredService<AppDbContext>();
        var user = await finalDb.Users.SingleAsync(u => u.Id == auth.User.Id); Assert.False(user.IsActive); Assert.EndsWith("@account.invalid", user.Email);
        var profile = await finalDb.CustomerProfiles.SingleAsync(p => p.UserId == auth.User.Id); Assert.Null(profile.Address); Assert.Equal("Deleted account", profile.FullName);
    }
}
