using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Models;

namespace SolarPlatform.Api.Services;

public interface IProposalService
{
    Task<EngineeringProposalDto> CreateAsync(Guid surveyId, Guid requestingUserId, string? notes, CancellationToken ct = default);
    Task<List<EngineeringProposalSummaryDto>> GetAllAsync(CancellationToken ct = default);
    Task<List<EngineeringProposalSummaryDto>> GetPendingAsync(CancellationToken ct = default);
    Task<List<EngineeringProposalSummaryDto>> GetBySurveyAsync(Guid surveyId, Guid requestingUserId, bool isStaff, CancellationToken ct = default);
    Task<EngineeringProposalDto?> GetAsync(Guid proposalId, CancellationToken ct = default);
    Task<EngineeringProposalDto> ApproveAsync(Guid proposalId, Guid engineerUserId, string? comment, CancellationToken ct = default);
    Task<EngineeringProposalDto> RejectAsync(Guid proposalId, Guid engineerUserId, string comment, CancellationToken ct = default);
    Task<EngineeringProposalDto> RequestRevisionAsync(Guid proposalId, Guid engineerUserId, string comment, CancellationToken ct = default);
}
