namespace SolarPlatform.Api.Models;

public class SupportConversation
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid SolarSurveyId { get; set; }
    public Guid HomeownerId { get; set; }
    public Guid TechnicianId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime LastMessageAt { get; set; } = DateTime.UtcNow;

    public SolarSurvey SolarSurvey { get; set; } = null!;
    public User Homeowner { get; set; } = null!;
    public User Technician { get; set; } = null!;
    public ICollection<SupportMessage> Messages { get; set; } = new List<SupportMessage>();
}
