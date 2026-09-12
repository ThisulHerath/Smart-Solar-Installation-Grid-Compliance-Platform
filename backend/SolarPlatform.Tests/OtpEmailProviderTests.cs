using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using SolarPlatform.Api.Services;

namespace SolarPlatform.Tests;

public class OtpEmailProviderTests
{
    [Theory]
    [InlineData("brevo")]
    [InlineData("unknown-provider")]
    public async Task MissingProviderCredentialsNeverFallBackToGmail(string provider)
    {
        var config = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?> {
            ["EMAIL_PROVIDER"] = provider,
            ["SMTP_USERNAME"] = "test@example.invalid",
            ["SMTP_PASSWORD"] = "not-a-real-secret",
            ["SMTP_HOST"] = "must-not-connect.invalid"
        }).Build();
        var sender = new OtpEmailSender(config, NullLogger<OtpEmailSender>.Instance);
        await Assert.ThrowsAsync<EmailDeliveryException>(() => sender.SendAsync("recipient@example.invalid", "123456", "registration"));
    }
}
