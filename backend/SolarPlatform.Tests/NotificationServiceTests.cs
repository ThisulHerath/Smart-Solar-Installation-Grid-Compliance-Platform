using Microsoft.EntityFrameworkCore;
using SolarPlatform.Api.Data;
using SolarPlatform.Api.Models;
using SolarPlatform.Api.Services;

namespace SolarPlatform.Tests;

public class NotificationServiceTests
{
    [Fact]
    public async Task Notifications_AreScopedToRecipient_AndCanBeMarkedRead()
    {
        await using var db = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);
        var recipient = new User { Email = "recipient@test.local", FullName = "Recipient", PasswordHash = "x" };
        var other = new User { Email = "other-notify@test.local", FullName = "Other", PasswordHash = "x" };
        db.Users.AddRange(recipient, other);
        await db.SaveChangesAsync();
        var service = new NotificationService(db);
        await service.NotifyUserAsync(recipient.Id, "TEST", "New work", "Open this work item.", "/work", "Work", Guid.NewGuid());

        var notification = Assert.Single(await service.GetForUserAsync(recipient.Id));
        Assert.Empty(await service.GetForUserAsync(other.Id));
        Assert.Equal(1, await service.GetUnreadCountAsync(recipient.Id));
        Assert.True(await service.MarkReadAsync(recipient.Id, notification.Id));
        Assert.Equal(0, await service.GetUnreadCountAsync(recipient.Id));
        Assert.False(await service.MarkReadAsync(other.Id, notification.Id));
    }
}
