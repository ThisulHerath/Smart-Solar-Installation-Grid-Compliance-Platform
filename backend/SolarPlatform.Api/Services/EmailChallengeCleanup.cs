using Microsoft.EntityFrameworkCore;
using SolarPlatform.Api.Data;

namespace SolarPlatform.Api.Services;

// Short retention keeps pending registration details out of long-lived application data.
public class EmailChallengeCleanup(IServiceScopeFactory scopes, ILogger<EmailChallengeCleanup> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(TimeSpan.FromMinutes(15));
        while (await timer.WaitForNextTickAsync(stoppingToken))
        {
            try
            {
                using var scope = scopes.CreateScope();
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
                var now = DateTime.UtcNow;
                var stale = await db.EmailChallenges.Where(c => c.CreatedAt < now.AddHours(-24) ||
                    (c.ExpiresAt < now && c.PasswordHash != null)).Take(1000).ToListAsync(stoppingToken);
                foreach (var row in stale)
                {
                    if (row.CreatedAt < now.AddHours(-24)) db.EmailChallenges.Remove(row);
                    else { row.PasswordHash = null; row.FullName = null; row.PhoneNumber = null; row.CodeHash = ""; row.ConsumedAt = now; row.Revision = Guid.NewGuid(); }
                }
                await db.SaveChangesAsync(stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested) { break; }
            catch (Exception ex) { logger.LogWarning("Email challenge cleanup will retry ({ErrorType}).", ex.GetType().Name); }
        }
    }
}
