namespace SolarPlatform.Api.DTOs;

public record CreateConversationRequest(Guid SurveyId);
public record SendMessageRequest(string Body);

public record ConversationDto(
    Guid Id,
    Guid SolarSurveyId,
    string PropertyAddress,
    Guid OtherParticipantId,
    string OtherParticipantName,
    string? LastMessage,
    DateTime LastMessageAt,
    int UnreadCount);

public record ChatMessageDto(
    Guid Id,
    Guid ConversationId,
    Guid SenderId,
    string SenderName,
    string Body,
    DateTime CreatedAt,
    DateTime? ReadAt,
    bool IsMine);
