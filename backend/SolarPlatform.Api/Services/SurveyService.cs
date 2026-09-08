using System.Security.Claims;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using SolarPlatform.Api.Data;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Integrations;
using SolarPlatform.Api.Models;

namespace SolarPlatform.Api.Services;

public interface ISurveyService
{
    Task<ProfileDto> GetProfileAsync(Guid userId);
    Task<ProfileDto> UpdateProfileAsync(Guid userId, UpdateProfileRequestDto request);
    Task<SurveyDto> CreateAsync(Guid userId, SurveyRequestDto request);
    Task<IReadOnlyList<SurveyDto>> GetMineAsync(Guid userId);
    Task<IReadOnlyList<SurveyDto>> GetAllAsync();
    Task<SurveyDto?> GetAsync(Guid userId, Guid surveyId, bool staffAccess = false);
    Task<SurveyDto?> UpdateAsync(Guid userId, Guid surveyId, SurveyRequestDto request);
    Task<SurveyDto?> SubmitAsync(Guid userId, Guid surveyId);
    Task<SurveyDto?> AddImageAsync(Guid userId, Guid surveyId, SurveyImageType imageType, string fileUrl, string fileName);
}

public class SurveyService : ISurveyService
{
    private readonly AppDbContext _db;
    private readonly IAgenticAiService _agenticAi;
    public SurveyService(AppDbContext db, IAgenticAiService agenticAi) { _db = db; _agenticAi = agenticAi; }

    public async Task<ProfileDto> GetProfileAsync(Guid userId)
    {
        var profile = await GetOrCreateProfileAsync(userId);
        return ToProfile(profile);
    }

    public async Task<ProfileDto> UpdateProfileAsync(Guid userId, UpdateProfileRequestDto request)
    {
        var profile = await GetOrCreateProfileAsync(userId);
        profile.FullName = request.FullName.Trim();
        profile.PhoneNumber = request.PhoneNumber?.Trim();
        profile.Address = request.Address?.Trim();
        profile.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return ToProfile(profile);
    }

    public async Task<SurveyDto> CreateAsync(Guid userId, SurveyRequestDto request)
    {
        ValidateRequest(request);
        var profile = await GetOrCreateProfileAsync(userId);
        var survey = new SolarSurvey { CustomerId = profile.Id };
        Apply(survey, request);
        _db.SolarSurveys.Add(survey);
        await _db.SaveChangesAsync();
        return ToDto(survey);
    }

    public async Task<IReadOnlyList<SurveyDto>> GetMineAsync(Guid userId)
    {
        var profile = await GetOrCreateProfileAsync(userId);
        var surveys = await Query().Where(s => s.CustomerId == profile.Id).OrderByDescending(s => s.CreatedAt).ToListAsync();
        return surveys.Select(ToDto).ToList();
    }

    public async Task<IReadOnlyList<SurveyDto>> GetAllAsync()
    {
        var surveys = await Query().OrderByDescending(s => s.CreatedAt).ToListAsync();
        return surveys.Select(ToDto).ToList();
    }

    public async Task<SurveyDto?> GetAsync(Guid userId, Guid surveyId, bool staffAccess = false)
    {
        var query = Query().Where(s => s.Id == surveyId);
        if (!staffAccess)
        {
            var profile = await GetOrCreateProfileAsync(userId);
            query = query.Where(s => s.CustomerId == profile.Id);
        }
        var survey = await query.SingleOrDefaultAsync();
        return survey == null ? null : ToDto(survey);
    }

    public async Task<SurveyDto?> UpdateAsync(Guid userId, Guid surveyId, SurveyRequestDto request)
    {
        ValidateRequest(request);
        var profile = await GetOrCreateProfileAsync(userId);
        var survey = await _db.SolarSurveys.SingleOrDefaultAsync(s => s.Id == surveyId && s.CustomerId == profile.Id);
        if (survey == null) return null;
        if (survey.SurveyStatus != SurveyStatus.Draft) throw new InvalidOperationException("Only draft surveys can be edited.");
        Apply(survey, request);
        survey.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return await GetAsync(userId, surveyId);
    }

    public async Task<SurveyDto?> SubmitAsync(Guid userId, Guid surveyId)
    {
        var profile = await GetOrCreateProfileAsync(userId);
        var survey = await _db.SolarSurveys.Include(s => s.Images).Include(s => s.Workflows).SingleOrDefaultAsync(s => s.Id == surveyId && s.CustomerId == profile.Id);
        if (survey == null) return null;
        if (survey.SurveyStatus != SurveyStatus.Draft) throw new InvalidOperationException("Only draft surveys can be submitted.");
        SurveyStatusTransition.Move(survey, SurveyStatus.Submitted);
        var workflow = new AgentWorkflow { SolarSurveyId = survey.Id, Objective = "Preliminary solar system sizing", Status = WorkflowStatus.Processing, StartedAt = DateTime.UtcNow };
        // Explicitly mark the independently keyed workflow as new. Adding a non-empty GUID
        // through a tracked collection can otherwise be interpreted as an update by EF Core.
        _db.AgentWorkflows.Add(workflow);
        SurveyStatusTransition.Move(survey, SurveyStatus.Processing);
        await _db.SaveChangesAsync();
        var result = await _agenticAi.ExecuteSolarSizingAsync(new { workflow_id = workflow.WorkflowId, customer_id = survey.CustomerId.ToString(), monthly_kwh = survey.MonthlyKwh, roof_area_sqm = survey.RoofAreaSqm, grid_type = survey.GridType.ToString(), property_address = survey.PropertyAddress });
        workflow.ResultJson = result.Recommendation?.GetRawText();
        workflow.ValidationJson = result.ValidationResults?.GetRawText();
        workflow.ErrorMessage = result.Errors.Count == 0 ? null : string.Join("; ", result.Errors);
        var completedAt = DateTime.UtcNow;
        foreach (var log in result.ExecutionLogs)
        {
            var startedAt = log.StartedAt ?? workflow.StartedAt ?? completedAt;
            var logCompletedAt = log.CompletedAt ?? completedAt;
            _db.AgentExecutionLogs.Add(new AgentExecutionLog
            {
                AgentWorkflowId = workflow.Id, AgentName = log.AgentName, StepName = log.StepName,
                Status = log.Status, StartedAt = startedAt, CompletedAt = logCompletedAt,
                DurationMs = Math.Max(0, (long)(logCompletedAt - startedAt).TotalMilliseconds),
                OutputSummary = log.OutputSummary, ValidationResult = log.ValidationResult?.GetRawText(),
                ErrorMessage = log.ErrorMessage, RetryCount = log.RetryCount
            });
        }
        workflow.Status = result.Status == "completed" ? WorkflowStatus.Completed : WorkflowStatus.Failed;
        workflow.CompletedAt = completedAt;
        workflow.UpdatedAt = DateTime.UtcNow;
        SurveyStatusTransition.Move(survey, result.Status == "completed" ? SurveyStatus.AnalysisComplete : SurveyStatus.Failed);
        await _db.SaveChangesAsync();
        return ToDto(survey);
    }

    public async Task<SurveyDto?> AddImageAsync(Guid userId, Guid surveyId, SurveyImageType imageType, string fileUrl, string fileName)
    {
        var profile = await GetOrCreateProfileAsync(userId);
        var survey = await _db.SolarSurveys.SingleOrDefaultAsync(s => s.Id == surveyId && s.CustomerId == profile.Id);
        if (survey == null) return null;
        if (survey.SurveyStatus != SurveyStatus.Draft) throw new InvalidOperationException("Images can only be attached to draft surveys.");
        _db.SolarSurveyImages.Add(new SolarSurveyImage { SolarSurveyId = surveyId, ImageType = imageType, FileUrl = fileUrl, FileName = fileName });
        await _db.SaveChangesAsync();
        return await GetAsync(userId, surveyId);
    }

    private IQueryable<SolarSurvey> Query() => _db.SolarSurveys.Include(s => s.Images).Include(s => s.Workflows).AsNoTracking();
    private async Task<CustomerProfile> GetOrCreateProfileAsync(Guid userId)
    {
        var profile = await _db.CustomerProfiles.SingleOrDefaultAsync(p => p.UserId == userId);
        if (profile != null) return profile;
        var user = await _db.Users.FindAsync(userId) ?? throw new KeyNotFoundException("Authenticated user was not found.");
        profile = new CustomerProfile { UserId = userId, FullName = user.FullName, PhoneNumber = user.PhoneNumber };
        _db.CustomerProfiles.Add(profile);
        await _db.SaveChangesAsync();
        return profile;
    }
    private static void ValidateRequest(SurveyRequestDto request)
    {
        if (request.MonthlyKwh <= 0) throw new ArgumentException("Monthly electricity usage must be greater than zero.");
        if (request.RoofAreaSqm <= 0 || request.RoofAreaSqm > 100000) throw new ArgumentException("Roof area must be within a reasonable positive range.");
        if (request.GridType == GridType.Unknown) throw new ArgumentException("A supported grid type is required.");
        if ((request.Latitude.HasValue && !request.Longitude.HasValue) || (!request.Latitude.HasValue && request.Longitude.HasValue)) throw new ArgumentException("Latitude and longitude must be provided together.");
    }
    private static void Apply(SolarSurvey survey, SurveyRequestDto request)
    {
        survey.MonthlyKwh = request.MonthlyKwh; survey.RoofAreaSqm = request.RoofAreaSqm; survey.GridType = request.GridType;
        survey.RoofOrientation = request.RoofOrientation; survey.RoofTilt = request.RoofTilt; survey.PropertyAddress = request.PropertyAddress.Trim();
        survey.Latitude = request.Latitude; survey.Longitude = request.Longitude; survey.Notes = request.Notes?.Trim();
    }
    private static ProfileDto ToProfile(CustomerProfile p) => new(p.Id, p.FullName, p.PhoneNumber, p.Address);
    private static SurveyDto ToDto(SolarSurvey s) => new(s.Id, s.CustomerId, s.MonthlyKwh, s.RoofAreaSqm, s.GridType, s.RoofOrientation, s.RoofTilt, s.PropertyAddress, s.Latitude, s.Longitude, s.SurveyStatus, s.Notes, s.CreatedAt, s.UpdatedAt, s.Images.Select(i => new SurveyImageDto(i.Id, i.ImageType, i.FileUrl, i.FileName)).ToList(), s.Workflows.Select(w => new WorkflowDto(w.WorkflowId, w.Status, w.ResultJson, w.ValidationJson, w.ErrorMessage, w.StartedAt, w.CompletedAt)).ToList());
}
