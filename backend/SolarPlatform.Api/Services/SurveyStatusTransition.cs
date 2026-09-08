using SolarPlatform.Api.Models;

namespace SolarPlatform.Api.Services;

/// <summary>Defines the small, explicit lifecycle used by survey processing.</summary>
public static class SurveyStatusTransition
{
    public static void EnsureAllowed(SurveyStatus from, SurveyStatus to)
    {
        var allowed = (from, to) switch
        {
            (SurveyStatus.Draft, SurveyStatus.Submitted) => true,
            (SurveyStatus.Submitted, SurveyStatus.Processing) => true,
            (SurveyStatus.Processing, SurveyStatus.AnalysisComplete) => true,
            (SurveyStatus.Processing, SurveyStatus.Failed) => true,
            _ => false
        };

        if (!allowed)
            throw new InvalidOperationException($"Survey status transition from {from} to {to} is not allowed.");
    }

    public static void Move(SolarSurvey survey, SurveyStatus target)
    {
        EnsureAllowed(survey.SurveyStatus, target);
        survey.SurveyStatus = target;
        survey.UpdatedAt = DateTime.UtcNow;
    }
}
