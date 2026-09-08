using System.ComponentModel.DataAnnotations;
using SolarPlatform.Api.Models;

namespace SolarPlatform.Api.DTOs;

public record ProfileDto(Guid Id, string FullName, string? PhoneNumber, string? Address);
public class UpdateProfileRequestDto
{
    [Required, StringLength(255)] public string FullName { get; set; } = string.Empty;
    [StringLength(50)] public string? PhoneNumber { get; set; }
    [StringLength(500)] public string? Address { get; set; }
}
public class SurveyRequestDto
{
    [Range(0.01, 100000)] public decimal MonthlyKwh { get; set; }
    [Range(1, 100000)] public decimal RoofAreaSqm { get; set; }
    [EnumDataType(typeof(GridType))] public GridType GridType { get; set; }
    public RoofOrientation RoofOrientation { get; set; } = RoofOrientation.Unknown;
    [Range(0, 90)] public decimal? RoofTilt { get; set; }
    [Required, StringLength(500)] public string PropertyAddress { get; set; } = string.Empty;
    [Range(-90, 90)] public decimal? Latitude { get; set; }
    [Range(-180, 180)] public decimal? Longitude { get; set; }
    [StringLength(2000)] public string? Notes { get; set; }
}
public record SurveyImageDto(Guid Id, SurveyImageType ImageType, string FileUrl, string FileName);
public record WorkflowDto(string WorkflowId, WorkflowStatus Status, string? ResultJson, string? ValidationJson, string? ErrorMessage, DateTime? StartedAt, DateTime? CompletedAt);
public record SurveyDto(Guid Id, Guid CustomerId, decimal MonthlyKwh, decimal RoofAreaSqm, GridType GridType, RoofOrientation RoofOrientation, decimal? RoofTilt, string PropertyAddress, decimal? Latitude, decimal? Longitude, SurveyStatus SurveyStatus, string? Notes, DateTime CreatedAt, DateTime UpdatedAt, IReadOnlyList<SurveyImageDto> Images, IReadOnlyList<WorkflowDto> Workflows);
