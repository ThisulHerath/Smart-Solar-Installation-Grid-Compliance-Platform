namespace SolarPlatform.Api.Models;

public class SolarSurveyImage
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid SolarSurveyId { get; set; }
    public SurveyImageType ImageType { get; set; }
    public string FileUrl { get; set; } = string.Empty;
    public string FileName { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public SolarSurvey SolarSurvey { get; set; } = null!;
}
