using System.Net;
using System.Net.Mail;
using System.Net.Http.Json;

namespace SolarPlatform.Api.Services;

public interface IOtpEmailSender
{
    Task SendAsync(string email, string code, string purpose);
}

public class OtpEmailSender(
    IConfiguration configuration,
    ILogger<OtpEmailSender> logger,
    IHttpClientFactory httpClientFactory) : IOtpEmailSender
{
    public async Task SendAsync(string email, string code, string purpose)
    {
        string? Setting(string name)
        {
            var value = Environment.GetEnvironmentVariable(name) ?? configuration[name];
            return string.IsNullOrWhiteSpace(value) ? null : value.Trim();
        }
        var provider = Setting("EMAIL_PROVIDER")?.ToLowerInvariant() ?? "smtp";
        if (provider is not ("smtp" or "brevo" or "brevo-api")) throw new EmailDeliveryException();
        var subject = $"Smart Solar — {purpose} verification";
        var body = $"Your Smart Solar verification code is: {code}\n\nUse this code to confirm {purpose}. It expires in 10 minutes and works once.\n\nNever share this code. If you did not request this action, ignore this email. Your account has not been changed.";

        if (provider == "brevo-api")
        {
            var apiKey = Setting("BREVO_API_KEY");
            var senderEmail = Setting("BREVO_FROM_EMAIL");
            if (string.IsNullOrWhiteSpace(apiKey) || string.IsNullOrWhiteSpace(senderEmail))
                throw new EmailDeliveryException();

            try
            {
                var client = httpClientFactory.CreateClient(nameof(OtpEmailSender));
                using var request = new HttpRequestMessage(HttpMethod.Post, "https://api.brevo.com/v3/smtp/email");
                request.Headers.Add("api-key", apiKey);
                request.Content = JsonContent.Create(new
                {
                    sender = new { name = "Smart Solar Sri Lanka", email = senderEmail },
                    to = new[] { new { email } },
                    subject,
                    textContent = body
                });
                using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(20));
                using var response = await client.SendAsync(request, timeout.Token);
                if (!response.IsSuccessStatusCode)
                {
                    logger.LogWarning("Brevo email delivery failed with HTTP status {StatusCode}.", (int)response.StatusCode);
                    throw new EmailDeliveryException();
                }
                return;
            }
            catch (Exception ex) when (ex is HttpRequestException or OperationCanceledException or InvalidOperationException)
            {
                logger.LogWarning("Brevo email delivery failed ({ErrorType}).", ex.GetType().Name);
                throw new EmailDeliveryException();
            }
        }

        var brevo = provider == "brevo";
        // Separate credentials prevent accidentally submitting a Gmail password to another provider.
        var username = Setting(brevo ? "BREVO_SMTP_LOGIN" : "SMTP_USERNAME");
        var password = Setting(brevo ? "BREVO_SMTP_KEY" : "SMTP_PASSWORD");
        var sender = brevo ? Setting("BREVO_FROM_EMAIL") : Setting("SMTP_FROM_EMAIL") ?? username;
        var host = brevo ? "smtp-relay.brevo.com" : Setting("SMTP_HOST") ?? "smtp.gmail.com";
        var smtpPort = brevo ? 587 : int.TryParse(Setting("SMTP_PORT"), out var port) ? port : 587;
        if (string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(password) || string.IsNullOrWhiteSpace(sender))
            throw new EmailDeliveryException();
        try
        {
            using var client = new SmtpClient(host, smtpPort)
            {
                EnableSsl = true,
                UseDefaultCredentials = false,
                Credentials = new NetworkCredential(username, password)
            };
            using var message = new MailMessage
            {
                From = new MailAddress(sender, "Smart Solar Sri Lanka"),
                Subject = subject,
                Body = body
            };
            message.To.Add(new MailAddress(email));
            using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(20));
            await client.SendMailAsync(message, timeout.Token);
        }
        catch (Exception ex) when (ex is SmtpException or OperationCanceledException or FormatException or InvalidOperationException)
        {
            // SMTP exceptions can contain addresses and server responses. Keep them out of application logs.
            logger.LogWarning("OTP email delivery failed ({ErrorType}).", ex.GetType().Name);
            throw new EmailDeliveryException();
        }
    }
}

public class EmailDeliveryException() : Exception("Verification email is temporarily unavailable. Please try again later.");
public class OtpLimitException() : Exception("Please wait before requesting another code. You can request up to five codes per hour.");
