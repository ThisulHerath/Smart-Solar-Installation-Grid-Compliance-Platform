namespace SolarPlatform.Api.Models;

public class SupportMessage
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid ConversationId { get; set; }
    public Guid SenderId { get; set; }
    public string Body { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ReadAt { get; set; }

    public SupportConversation Conversation { get; set; } = null!;
    public User Sender { get; set; } = null!;
}
