using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Models;

namespace SolarPlatform.Api.Services;

public interface IFieldJobService
{
    Task<IReadOnlyList<FieldJobResponseDto>> GetJobsForTechnicianAsync(Guid technicianId, FieldJobStatus? status = null);
    Task<IReadOnlyList<FieldJobResponseDto>> GetAllJobsAsync(FieldJobStatus? status = null);
    Task<FieldJobResponseDto?> GetJobByIdAsync(Guid jobId, Guid? technicianId = null);
    Task<FieldJobResponseDto> CreateOrAssignJobAsync(CreateFieldJobDto dto);
    Task<FieldJobResponseDto?> AssignJobAsync(Guid jobId, AssignFieldJobDto dto);
    Task<FieldJobResponseDto?> UpdateJobStatusAsync(Guid jobId, Guid technicianId, FieldJobStatus newStatus);
    Task<SiteInspectionResponseDto?> CheckInAsync(Guid jobId, Guid technicianId, CheckInDto dto);
    Task<SiteInspectionResponseDto?> SaveInspectionDraftAsync(Guid jobId, Guid technicianId, SaveSiteInspectionDto dto);
    Task<SiteInspectionResponseDto?> SubmitInspectionAsync(Guid jobId, Guid technicianId);
    Task<SiteTelemetryDto?> RecordTelemetryAsync(Guid jobId, Guid technicianId, RecordTelemetryDto dto);
    Task<SitePhotoDto?> UploadPhotoAsync(Guid jobId, Guid technicianId, SitePhotoType photoType, Stream fileStream, string fileName);
    Task<ComplianceAssessmentDto?> TriggerComplianceEvaluationAsync(Guid jobId);
    Task<ComplianceAssessmentDto?> GetComplianceAssessmentAsync(Guid jobId);
}
