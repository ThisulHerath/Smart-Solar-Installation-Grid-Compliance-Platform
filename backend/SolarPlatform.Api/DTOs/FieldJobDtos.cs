using SolarPlatform.Api.Models;

namespace SolarPlatform.Api.DTOs;

public record FieldJobResponseDto(
    Guid Id,
    Guid SolarSurveyId,
    Guid TechnicianId,
    string TechnicianName,
    string CustomerName,
    string CustomerPhone,
    string PropertyAddress,
    decimal MonthlyKwh,
    decimal RoofAreaSqm,
    decimal? Latitude,
    decimal? Longitude,
    FieldJobStatus Status,
    FieldJobPriority Priority,
    DateTime AssignedAt,
    DateTime? ScheduledAt,
    DateTime CreatedAt,
    DateTime UpdatedAt,
    bool HasInspection,
    InspectionStatus? InspectionStatus,
    ComplianceAssessmentDto? Compliance
);

public record CreateFieldJobDto(
    Guid SolarSurveyId,
    Guid TechnicianId,
    DateTime? ScheduledAt,
    FieldJobPriority Priority = FieldJobPriority.Medium
);

public record AssignFieldJobDto(
    Guid TechnicianId,
    DateTime? ScheduledAt,
    FieldJobPriority Priority = FieldJobPriority.Medium
);

public record UpdateJobStatusDto(
    FieldJobStatus NewStatus,
    string? Reason = null
);

public record CheckInDto(
    decimal Latitude,
    decimal Longitude
);

public record SaveSiteInspectionDto(
    decimal? RoofAreaMeasuredSqm,
    RoofOrientation RoofOrientation,
    decimal? RoofTilt,
    GridType GridTypeObserved,
    int? PhaseCount,
    decimal? MainBreakerRating,
    bool? InverterLocationSuitable,
    string? SafetyNotes,
    string? TechnicianNotes
);

public record SiteInspectionResponseDto(
    Guid Id,
    Guid FieldJobId,
    decimal? CheckInLatitude,
    decimal? CheckInLongitude,
    DateTime? CheckInAt,
    decimal? RoofAreaMeasuredSqm,
    RoofOrientation RoofOrientation,
    decimal? RoofTilt,
    GridType GridTypeObserved,
    int? PhaseCount,
    decimal? MainBreakerRating,
    bool? InverterLocationSuitable,
    string? SafetyNotes,
    string? TechnicianNotes,
    InspectionStatus InspectionStatus,
    DateTime CreatedAt,
    DateTime UpdatedAt,
    List<SiteTelemetryDto> Telemetry,
    List<SitePhotoDto> Photos,
    ComplianceAssessmentDto? ComplianceAssessment
);

public record RecordTelemetryDto(
    MeasurementType MeasurementType,
    decimal MeasurementValue,
    string Unit
);

public record SiteTelemetryDto(
    Guid Id,
    Guid SiteInspectionId,
    MeasurementType MeasurementType,
    decimal MeasurementValue,
    string Unit,
    DateTime RecordedAt
);

public record SitePhotoDto(
    Guid Id,
    Guid SiteInspectionId,
    SitePhotoType PhotoType,
    string FileUrl,
    string FileName,
    DateTime CreatedAt
);
