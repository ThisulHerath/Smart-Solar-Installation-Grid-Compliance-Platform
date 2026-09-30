using Microsoft.EntityFrameworkCore;
using SolarPlatform.Api.Data;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Models;

namespace SolarPlatform.Api.Services;

public interface INotificationService
{
    Task NotifyRoleAsync(string role, string type, string title, string message, string? actionUrl = null, string? entityType = null, Guid? entityId = null);
    Task NotifyUserAsync(Guid userId, string type, string title, string message, string? actionUrl = null, string? entityType = null, Guid? entityId = null);
    Task<IReadOnlyList<NotificationDto>> GetForUserAsync(Guid userId, bool unreadOnly = false, int limit = 50);
    Task<int> GetUnreadCountAsync(Guid userId);
    Task<bool> MarkReadAsync(Guid userId, Guid notificationId);
    Task<int> MarkAllReadAsync(Guid userId);
}

public class NotificationService : INotificationService
{
    private readonly AppDbContext _db;
    public NotificationService(AppDbContext db) => _db = db;

    public async Task NotifyRoleAsync(string role, string type, string title, string message, string? actionUrl = null, string? entityType = null, Guid? entityId = null)
    {
        var userIds = await _db.Users.AsNoTracking()
            .Where(user => user.IsActive && user.UserRoles.Any(userRole => userRole.Role.Name == role))
            .Select(user => user.Id)
            .ToListAsync();
        if (userIds.Count == 0) return;
        _db.UserNotifications.AddRange(userIds.Select(userId => Create(userId, type, title, message, actionUrl, entityType, entityId)));
        await _db.SaveChangesAsync();
    }

    public async Task NotifyUserAsync(Guid userId, string type, string title, string message, string? actionUrl = null, string? entityType = null, Guid? entityId = null)
    {
        if (!await _db.Users.AsNoTracking().AnyAsync(user => user.Id == userId && user.IsActive)) return;
        _db.UserNotifications.Add(Create(userId, type, title, message, actionUrl, entityType, entityId));
        await _db.SaveChangesAsync();
    }

    public async Task<IReadOnlyList<NotificationDto>> GetForUserAsync(Guid userId, bool unreadOnly = false, int limit = 50)
    {
        var query = _db.UserNotifications.AsNoTracking().Where(item => item.UserId == userId);
        if (unreadOnly) query = query.Where(item => !item.IsRead);
        return await query.OrderByDescending(item => item.CreatedAt).Take(Math.Clamp(limit, 1, 100))
            .Select(item => new NotificationDto(item.Id, item.Type, item.Title, item.Message, item.ActionUrl, item.EntityType, item.EntityId, item.IsRead, item.ReadAt, item.CreatedAt))
            .ToListAsync();
    }

    public Task<int> GetUnreadCountAsync(Guid userId) =>
        _db.UserNotifications.CountAsync(item => item.UserId == userId && !item.IsRead);

    public async Task<bool> MarkReadAsync(Guid userId, Guid notificationId)
    {
        var item = await _db.UserNotifications.FirstOrDefaultAsync(value => value.Id == notificationId && value.UserId == userId);
        if (item == null) return false;
        if (!item.IsRead) { item.IsRead = true; item.ReadAt = DateTime.UtcNow; await _db.SaveChangesAsync(); }
        return true;
    }

    public async Task<int> MarkAllReadAsync(Guid userId)
    {
        var items = await _db.UserNotifications.Where(item => item.UserId == userId && !item.IsRead).ToListAsync();
        var now = DateTime.UtcNow;
        foreach (var item in items) { item.IsRead = true; item.ReadAt = now; }
        if (items.Count > 0) await _db.SaveChangesAsync();
        return items.Count;
    }

    private static UserNotification Create(Guid userId, string type, string title, string message, string? actionUrl, string? entityType, Guid? entityId) =>
        new() { UserId = userId, Type = type, Title = title, Message = message, ActionUrl = actionUrl, EntityType = entityType, EntityId = entityId };

}
