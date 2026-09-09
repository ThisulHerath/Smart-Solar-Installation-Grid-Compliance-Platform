using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using SolarPlatform.Api.Data;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Integrations;
using SolarPlatform.Api.Models;

namespace SolarPlatform.Api.Services;

public class FieldJobService : IFieldJobService
{
    private readonly AppDbContext _db;
    private readonly IAgenticAiService _agenticAi;
    private readonly IFileStorageService _fileStorage;
    private readonly ILogger<FieldJobService> _logger;

    public FieldJobService(
        AppDbContext db,
        IAgenticAiService agenticAi,
        IFileStorageService fileStorage,
        ILogger<FieldJobService> logger)
    {
        _db = db;
        _agenticAi = agenticAi;
        _fileStorage = fileStorage;
        _logger = logger;
    }

    public async Task<IReadOnlyList<FieldJobResponseDto>> GetJobsForTechnicianAsync(Guid technicianId, FieldJobStatus? status = null)
    {
        var query = _db.FieldJobs
            .Include(j => j.SolarSurvey).ThenInclude(s => s.Customer)
            .Include(j => j.Technician)
            .Include(j => j.Inspection).ThenInclude(i => i!.ComplianceAssessment)
            .Where(j => j.TechnicianId == technicianId);

        if (status.HasValue)
        {
            query = query.Where(j => j.Status == status.Value);
        }

        var jobs = await query.OrderByDescending(j => j.CreatedAt).ToListAsync();
        return jobs.Select(ToDto).ToList();
    }

    public async Task<IReadOnlyList<FieldJobResponseDto>> GetAllJobsAsync(FieldJobStatus? status = null)
    {
        var query = _db.FieldJobs
            .Include(j => j.SolarSurvey).ThenInclude(s => s.Customer)
            .Include(j => j.Technician)
            .Include(j => j.Inspection).ThenInclude(i => i!.ComplianceAssessment)
            .AsNoTracking();

        if (status.HasValue)
        {
            query = query.Where(j => j.Status == status.Value);
        }

        var jobs = await query.OrderByDescending(j => j.CreatedAt).ToListAsync();
        return jobs.Select(ToDto).ToList();
    }

    public async Task<FieldJobResponseDto?> GetJobByIdAsync(Guid jobId, Guid? technicianId = null)
    {
        var query = _db.FieldJobs
            .Include(j => j.SolarSurvey).ThenInclude(s => s.Customer)
            .Include(j => j.Technician)
            .Include(j => j.Inspection).ThenInclude(i => i!.Telemetry)
            .Include(j => j.Inspection).ThenInclude(i => i!.Photos)
            .Include(j => j.Inspection).ThenInclude(i => i!.ComplianceAssessment)
            .Where(j => j.Id == jobId);

        if (technicianId.HasValue)
        {
            query = query.Where(j => j.TechnicianId == technicianId.Value);
        }

        var job = await query.FirstOrDefaultAsync();
        return job == null ? null : ToDto(job);
    }

    public async Task<FieldJobResponseDto> CreateOrAssignJobAsync(CreateFieldJobDto dto)
    {
        var survey = await _db.SolarSurveys
            .Include(s => s.Customer)
            .FirstOrDefaultAsync(s => s.Id == dto.SolarSurveyId)
            ?? throw new KeyNotFoundException($"Solar survey {dto.SolarSurveyId} not found.");

        var tech = await _db.Users.FindAsync(dto.TechnicianId)
            ?? throw new KeyNotFoundException($"Technician user {dto.TechnicianId} not found.");

        var job = new FieldJob
        {
            SolarSurveyId = dto.SolarSurveyId,
            TechnicianId = dto.TechnicianId,
            ScheduledAt = dto.ScheduledAt,
            Priority = dto.Priority,
            Status = FieldJobStatus.Assigned,
            AssignedAt = DateTime.UtcNow
        };

        _db.FieldJobs.Add(job);
        await _db.SaveChangesAsync();

        return await GetJobByIdAsync(job.Id) ?? throw new InvalidOperationException("Failed to retrieve created job.");
    }

    public async Task<FieldJobResponseDto?> AssignJobAsync(Guid jobId, AssignFieldJobDto dto)
    {
        var job = await _db.FieldJobs.FindAsync(jobId);
        if (job == null) return null;

        var tech = await _db.Users.FindAsync(dto.TechnicianId)
            ?? throw new KeyNotFoundException($"Technician user {dto.TechnicianId} not found.");

        job.TechnicianId = dto.TechnicianId;
        job.ScheduledAt = dto.ScheduledAt;
        job.Priority = dto.Priority;
        job.AssignedAt = DateTime.UtcNow;
        job.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        return await GetJobByIdAsync(jobId);
    }

    public async Task<FieldJobResponseDto?> UpdateJobStatusAsync(Guid jobId, Guid technicianId, FieldJobStatus newStatus)
    {
        var job = await _db.FieldJobs.FirstOrDefaultAsync(j => j.Id == jobId && j.TechnicianId == technicianId);
        if (job == null) return null;

        FieldJobStatusTransition.ValidateTransition(job.Status, newStatus);
        job.Status = newStatus;
        job.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        return await GetJobByIdAsync(jobId);
    }

    public async Task<SiteInspectionResponseDto?> CheckInAsync(Guid jobId, Guid technicianId, CheckInDto dto)
    {
        var job = await _db.FieldJobs
            .Include(j => j.Inspection)
            .FirstOrDefaultAsync(j => j.Id == jobId && j.TechnicianId == technicianId);

        if (job == null) return null;

        var inspection = job.Inspection;
        if (inspection == null)
        {
            inspection = new SiteInspection
            {
                FieldJobId = jobId,
                CheckInLatitude = dto.Latitude,
                CheckInLongitude = dto.Longitude,
                CheckInAt = DateTime.UtcNow,
                InspectionStatus = InspectionStatus.Draft
            };
            _db.SiteInspections.Add(inspection);
        }
        else
        {
            inspection.CheckInLatitude = dto.Latitude;
            inspection.CheckInLongitude = dto.Longitude;
            inspection.CheckInAt = DateTime.UtcNow;
            inspection.UpdatedAt = DateTime.UtcNow;
        }

        // Advance job to InProgress if currently Accepted or Assigned
        if (job.Status == FieldJobStatus.Assigned || job.Status == FieldJobStatus.Accepted)
        {
            job.Status = FieldJobStatus.InProgress;
            job.UpdatedAt = DateTime.UtcNow;
        }

        await _db.SaveChangesAsync();
        return await GetInspectionDtoAsync(inspection.Id);
    }

    public async Task<SiteInspectionResponseDto?> SaveInspectionDraftAsync(Guid jobId, Guid technicianId, SaveSiteInspectionDto dto)
    {
        var job = await _db.FieldJobs
            .Include(j => j.Inspection)
            .FirstOrDefaultAsync(j => j.Id == jobId && j.TechnicianId == technicianId);

        if (job == null) return null;

        var inspection = job.Inspection;
        if (inspection == null)
        {
            inspection = new SiteInspection
            {
                FieldJobId = jobId,
                InspectionStatus = InspectionStatus.Draft
            };
            _db.SiteInspections.Add(inspection);
        }

        inspection.RoofAreaMeasuredSqm = dto.RoofAreaMeasuredSqm;
        inspection.RoofOrientation = dto.RoofOrientation;
        inspection.RoofTilt = dto.RoofTilt;
        inspection.GridTypeObserved = dto.GridTypeObserved;
        inspection.PhaseCount = dto.PhaseCount;
        inspection.MainBreakerRating = dto.MainBreakerRating;
        inspection.InverterLocationSuitable = dto.InverterLocationSuitable;
        inspection.SafetyNotes = dto.SafetyNotes?.Trim();
        inspection.TechnicianNotes = dto.TechnicianNotes?.Trim();
        inspection.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        return await GetInspectionDtoAsync(inspection.Id);
    }

    public async Task<SiteTelemetryDto?> RecordTelemetryAsync(Guid jobId, Guid technicianId, RecordTelemetryDto dto)
    {
        var job = await _db.FieldJobs
            .Include(j => j.Inspection)
            .FirstOrDefaultAsync(j => j.Id == jobId && j.TechnicianId == technicianId);

        if (job == null) return null;

        var inspection = job.Inspection;
        if (inspection == null)
        {
            inspection = new SiteInspection
            {
                FieldJobId = jobId,
                InspectionStatus = InspectionStatus.Draft
            };
            _db.SiteInspections.Add(inspection);
            await _db.SaveChangesAsync();
        }

        var telemetry = new SiteTelemetry
        {
            SiteInspectionId = inspection.Id,
            MeasurementType = dto.MeasurementType,
            MeasurementValue = dto.MeasurementValue,
            Unit = dto.Unit,
            RecordedAt = DateTime.UtcNow
        };

        _db.SiteTelemetry.Add(telemetry);
        await _db.SaveChangesAsync();

        return new SiteTelemetryDto(
            telemetry.Id,
            telemetry.SiteInspectionId,
            telemetry.MeasurementType,
            telemetry.MeasurementValue,
            telemetry.Unit,
            telemetry.RecordedAt
        );
    }

    public async Task<SitePhotoDto?> UploadPhotoAsync(Guid jobId, Guid technicianId, SitePhotoType photoType, Stream fileStream, string fileName)
    {
        var job = await _db.FieldJobs
            .Include(j => j.Inspection)
            .FirstOrDefaultAsync(j => j.Id == jobId && j.TechnicianId == technicianId);

        if (job == null) return null;

        var inspection = job.Inspection;
        if (inspection == null)
        {
            inspection = new SiteInspection
            {
                FieldJobId = jobId,
                InspectionStatus = InspectionStatus.Draft
            };
            _db.SiteInspections.Add(inspection);
            await _db.SaveChangesAsync();
        }

        var fileUrl = await _fileStorage.SaveFileAsync(fileStream, fileName, "site-photos");

        var photo = new SitePhoto
        {
            SiteInspectionId = inspection.Id,
            PhotoType = photoType,
            FileUrl = fileUrl,
            FileName = fileName,
            CreatedAt = DateTime.UtcNow
        };

        _db.SitePhotos.Add(photo);
        await _db.SaveChangesAsync();

        return new SitePhotoDto(
            photo.Id,
            photo.SiteInspectionId,
            photo.PhotoType,
            photo.FileUrl,
            photo.FileName,
            photo.CreatedAt
        );
    }

    public async Task<SiteInspectionResponseDto?> SubmitInspectionAsync(Guid jobId, Guid technicianId)
    {
        var job = await _db.FieldJobs
            .Include(j => j.SolarSurvey)
            .Include(j => j.Inspection).ThenInclude(i => i!.Telemetry)
            .Include(j => j.Inspection).ThenInclude(i => i!.Photos)
            .Include(j => j.Inspection).ThenInclude(i => i!.ComplianceAssessment)
            .FirstOrDefaultAsync(j => j.Id == jobId && j.TechnicianId == technicianId);

        if (job == null || job.Inspection == null) return null;

        var inspection = job.Inspection;
        inspection.InspectionStatus = InspectionStatus.Submitted;
        inspection.UpdatedAt = DateTime.UtcNow;

        FieldJobStatusTransition.ValidateTransition(job.Status, FieldJobStatus.Submitted);
        job.Status = FieldJobStatus.Submitted;
        job.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        // Run compliance evaluation
        await TriggerComplianceEvaluationAsync(jobId);

        return await GetInspectionDtoAsync(inspection.Id);
    }

    public async Task<ComplianceAssessmentDto?> TriggerComplianceEvaluationAsync(Guid jobId)
    {
        var job = await _db.FieldJobs
            .Include(j => j.SolarSurvey)
            .Include(j => j.Inspection).ThenInclude(i => i!.Telemetry)
            .Include(j => j.Inspection).ThenInclude(i => i!.ComplianceAssessment)
            .FirstOrDefaultAsync(j => j.Id == jobId);

        if (job?.Inspection == null) return null;

        var inspection = job.Inspection;

        // Set status to ComplianceProcessing
        job.Status = FieldJobStatus.ComplianceProcessing;
        job.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        // Extract telemetry
        var voc = inspection.Telemetry.FirstOrDefault(t => t.MeasurementType == MeasurementType.Voc)?.MeasurementValue;
        var isc = inspection.Telemetry.FirstOrDefault(t => t.MeasurementType == MeasurementType.Isc)?.MeasurementValue;
        var vmp = inspection.Telemetry.FirstOrDefault(t => t.MeasurementType == MeasurementType.Vmp)?.MeasurementValue;
        var imp = inspection.Telemetry.FirstOrDefault(t => t.MeasurementType == MeasurementType.Imp)?.MeasurementValue;
        var irradiance = inspection.Telemetry.FirstOrDefault(t => t.MeasurementType == MeasurementType.Irradiance)?.MeasurementValue;
        var temperature = inspection.Telemetry.FirstOrDefault(t => t.MeasurementType == MeasurementType.Temperature)?.MeasurementValue;
        var gridVoltage = inspection.Telemetry.FirstOrDefault(t => t.MeasurementType == MeasurementType.GridVoltage)?.MeasurementValue;
        var gridFrequency = inspection.Telemetry.FirstOrDefault(t => t.MeasurementType == MeasurementType.GridFrequency)?.MeasurementValue;

        var complianceRequest = new EvaluateComplianceRequestDto(
            InspectionId: inspection.Id,
            FieldJobId: job.Id,
            GridType: inspection.GridTypeObserved.ToString(),
            PhaseCount: inspection.PhaseCount,
            MainBreakerRating: inspection.MainBreakerRating,
            InverterLocationSuitable: inspection.InverterLocationSuitable,
            RoofAreaSqm: inspection.RoofAreaMeasuredSqm ?? job.SolarSurvey.RoofAreaSqm,
            RoofTilt: inspection.RoofTilt,
            RoofOrientation: inspection.RoofOrientation.ToString(),
            Voc: voc,
            Isc: isc,
            Vmp: vmp,
            Imp: imp,
            Irradiance: irradiance,
            Temperature: temperature,
            GridVoltage: gridVoltage,
            GridFrequency: gridFrequency,
            SafetyNotes: inspection.SafetyNotes,
            TechnicianNotes: inspection.TechnicianNotes
        );

        EvaluateComplianceResponseDto? aiResult = null;
        try
        {
            aiResult = await _agenticAi.ExecuteComplianceEvaluationAsync(complianceRequest);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Agentic AI compliance call failed, using deterministic local evaluation.");
        }

        // If AI returned a result, use it; otherwise fallback to deterministic local evaluator
        var assessment = inspection.ComplianceAssessment;
        if (assessment == null)
        {
            assessment = new ComplianceAssessment
            {
                SiteInspectionId = inspection.Id
            };
            _db.ComplianceAssessments.Add(assessment);
        }

        if (aiResult != null)
        {
            assessment.WorkflowId = aiResult.WorkflowId;
            assessment.GridCompliant = aiResult.GridCompliant;
            assessment.ComplianceStatus = aiResult.ComplianceStatus;
            assessment.RiskLevel = aiResult.RiskLevel;
            assessment.ValidationStatus = aiResult.ValidationStatus;
            assessment.ComplianceNotes = string.Join("; ", aiResult.Violations.Concat(aiResult.Recommendations));
            assessment.UpdatedAt = DateTime.UtcNow;

            job.Status = aiResult.GridCompliant ? FieldJobStatus.ComplianceComplete : FieldJobStatus.Failed;
        }
        else
        {
            // Deterministic local compliance evaluation fallback
            var violations = new List<string>();
            var recommendations = new List<string>();

            // Voltage check (230V +/- 6% for single phase, 400V +/- 6% for three phase)
            if (gridVoltage.HasValue)
            {
                var targetV = inspection.GridTypeObserved == GridType.ThreePhase ? 400m : 230m;
                var minV = targetV * 0.94m;
                var maxV = targetV * 1.06m;
                if (gridVoltage.Value < minV || gridVoltage.Value > maxV)
                {
                    violations.Add($"Grid voltage {gridVoltage.Value}V is outside acceptable range ({minV:F1}V - {maxV:F1}V).");
                }
            }

            // Frequency check (50Hz +/- 1% -> 49.5 - 50.5Hz)
            if (gridFrequency.HasValue)
            {
                if (gridFrequency.Value < 49.5m || gridFrequency.Value > 50.5m)
                {
                    violations.Add($"Grid frequency {gridFrequency.Value}Hz is outside standard tolerances (49.5Hz - 50.5Hz).");
                }
            }

            // Inverter suitability
            if (inspection.InverterLocationSuitable == false)
            {
                violations.Add("Technician identified inverter location as unsuitable for thermal dissipation and safety.");
            }

            bool compliant = violations.Count == 0;
            string risk = compliant ? "Low" : (violations.Count > 1 ? "High" : "Medium");

            assessment.WorkflowId = $"local-comp-{Guid.NewGuid().ToString()[..8]}";
            assessment.GridCompliant = compliant;
            assessment.ComplianceStatus = compliant ? "Compliant" : "Non-Compliant";
            assessment.RiskLevel = risk;
            assessment.ValidationStatus = "DeterministicValidated";
            assessment.ComplianceNotes = violations.Count > 0
                ? $"Violations: {string.Join("; ", violations)}"
                : "All electrical telemetry and physical site parameters comply with grid standards.";
            assessment.UpdatedAt = DateTime.UtcNow;

            job.Status = compliant ? FieldJobStatus.ComplianceComplete : FieldJobStatus.Failed;
        }

        job.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        return new ComplianceAssessmentDto(
            assessment.Id,
            assessment.SiteInspectionId,
            assessment.WorkflowId,
            assessment.GridCompliant,
            assessment.ComplianceStatus,
            assessment.RiskLevel,
            assessment.ComplianceNotes,
            assessment.ValidationStatus,
            assessment.CreatedAt,
            assessment.UpdatedAt
        );
    }

    public async Task<ComplianceAssessmentDto?> GetComplianceAssessmentAsync(Guid jobId)
    {
        var job = await _db.FieldJobs
            .Include(j => j.Inspection).ThenInclude(i => i!.ComplianceAssessment)
            .FirstOrDefaultAsync(j => j.Id == jobId);

        var assessment = job?.Inspection?.ComplianceAssessment;
        if (assessment == null) return null;

        return new ComplianceAssessmentDto(
            assessment.Id,
            assessment.SiteInspectionId,
            assessment.WorkflowId,
            assessment.GridCompliant,
            assessment.ComplianceStatus,
            assessment.RiskLevel,
            assessment.ComplianceNotes,
            assessment.ValidationStatus,
            assessment.CreatedAt,
            assessment.UpdatedAt
        );
    }

    private async Task<SiteInspectionResponseDto?> GetInspectionDtoAsync(Guid inspectionId)
    {
        var inspection = await _db.SiteInspections
            .Include(i => i.Telemetry)
            .Include(i => i.Photos)
            .Include(i => i.ComplianceAssessment)
            .FirstOrDefaultAsync(i => i.Id == inspectionId);

        if (inspection == null) return null;

        return new SiteInspectionResponseDto(
            inspection.Id,
            inspection.FieldJobId,
            inspection.CheckInLatitude,
            inspection.CheckInLongitude,
            inspection.CheckInAt,
            inspection.RoofAreaMeasuredSqm,
            inspection.RoofOrientation,
            inspection.RoofTilt,
            inspection.GridTypeObserved,
            inspection.PhaseCount,
            inspection.MainBreakerRating,
            inspection.InverterLocationSuitable,
            inspection.SafetyNotes,
            inspection.TechnicianNotes,
            inspection.InspectionStatus,
            inspection.CreatedAt,
            inspection.UpdatedAt,
            inspection.Telemetry.Select(t => new SiteTelemetryDto(t.Id, t.SiteInspectionId, t.MeasurementType, t.MeasurementValue, t.Unit, t.RecordedAt)).ToList(),
            inspection.Photos.Select(p => new SitePhotoDto(p.Id, p.SiteInspectionId, p.PhotoType, p.FileUrl, p.FileName, p.CreatedAt)).ToList(),
            inspection.ComplianceAssessment == null ? null : new ComplianceAssessmentDto(
                inspection.ComplianceAssessment.Id,
                inspection.ComplianceAssessment.SiteInspectionId,
                inspection.ComplianceAssessment.WorkflowId,
                inspection.ComplianceAssessment.GridCompliant,
                inspection.ComplianceAssessment.ComplianceStatus,
                inspection.ComplianceAssessment.RiskLevel,
                inspection.ComplianceAssessment.ComplianceNotes,
                inspection.ComplianceAssessment.ValidationStatus,
                inspection.ComplianceAssessment.CreatedAt,
                inspection.ComplianceAssessment.UpdatedAt
            )
        );
    }

    private static FieldJobResponseDto ToDto(FieldJob j)
    {
        return new FieldJobResponseDto(
            j.Id,
            j.SolarSurveyId,
            j.TechnicianId,
            j.Technician?.FullName ?? "Unassigned",
            j.SolarSurvey?.Customer?.FullName ?? "Unknown Customer",
            j.SolarSurvey?.Customer?.PhoneNumber ?? string.Empty,
            j.SolarSurvey?.PropertyAddress ?? string.Empty,
            j.SolarSurvey?.MonthlyKwh ?? 0,
            j.SolarSurvey?.RoofAreaSqm ?? 0,
            j.SolarSurvey?.Latitude,
            j.SolarSurvey?.Longitude,
            j.Status,
            j.Priority,
            j.AssignedAt,
            j.ScheduledAt,
            j.CreatedAt,
            j.UpdatedAt,
            j.Inspection != null,
            j.Inspection?.InspectionStatus,
            j.Inspection?.ComplianceAssessment == null ? null : new ComplianceAssessmentDto(
                j.Inspection.ComplianceAssessment.Id,
                j.Inspection.ComplianceAssessment.SiteInspectionId,
                j.Inspection.ComplianceAssessment.WorkflowId,
                j.Inspection.ComplianceAssessment.GridCompliant,
                j.Inspection.ComplianceAssessment.ComplianceStatus,
                j.Inspection.ComplianceAssessment.RiskLevel,
                j.Inspection.ComplianceAssessment.ComplianceNotes,
                j.Inspection.ComplianceAssessment.ValidationStatus,
                j.Inspection.ComplianceAssessment.CreatedAt,
                j.Inspection.ComplianceAssessment.UpdatedAt
            )
        );
    }
}
