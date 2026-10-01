namespace SolarPlatform.Api.DTOs;

public record NotificationDto(
    Guid Id,
    string Type,
    string Title,
    string Message,
    string? ActionUrl,
    string? EntityType,
    Guid? EntityId,
    bool IsRead,
    DateTime? ReadAt,
    DateTime CreatedAt);

public record NotificationCountDto(int Count);
