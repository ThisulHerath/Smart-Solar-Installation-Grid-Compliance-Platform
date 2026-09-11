using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using SolarPlatform.Api.Data;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Integrations;
using SolarPlatform.Api.Models;

namespace SolarPlatform.Api.Services;

/// <summary>
/// Implements the full engineering proposal lifecycle:
/// creation (Draft→Processing→PendingApproval),
/// transactional approval/rejection/revision (all status transitions enforced).
/// </summary>
public class ProposalService : IProposalService
{
    // Pricing constants (LKR) for cost estimation
    private const decimal PanelUnitPriceLkr = 80_000m;    // per panel
    private const decimal InverterPricePerKwLkr = 150_000m; // per kW

    private readonly AppDbContext _db;
    private readonly IAgenticAiService _ai;
    private readonly ILogger<ProposalService> _logger;

    public ProposalService(AppDbContext db, IAgenticAiService ai, ILogger<ProposalService> logger)
    {
        _db = db;
        _ai = ai;
        _logger = logger;
    }

    // ─── Creation ─────────────────────────────────────────────────────────────

    public async Task<EngineeringProposalDto> CreateAsync(
        Guid surveyId, Guid requestingUserId, string? notes, CancellationToken ct = default)
    {
        // 1. Load survey with customer and latest completed workflow/compliance
        var survey = await _db.SolarSurveys
            .Include(s => s.Customer)
            .FirstOrDefaultAsync(s => s.Id == surveyId, ct)
            ?? throw new ArgumentException($"Solar survey {surveyId} not found.");

        // Verify survey belongs to the requesting homeowner (or is staff)
        if (survey.CustomerId != requestingUserId)
        {
            // Check if the requesting user is indeed the homeowner profile owner
            var customerProfile = await _db.CustomerProfiles
                .FirstOrDefaultAsync(cp => cp.UserId == requestingUserId, ct);
            if (customerProfile == null || customerProfile.Id != survey.CustomerId)
                throw new UnauthorizedAccessException("You do not have permission to create a proposal for this survey.");
        }

        // 2. Find the latest compliance assessment via site inspection ← field job ← survey
        var compliance = await _db.ComplianceAssessments
            .Include(c => c.SiteInspection)
                .ThenInclude(si => si.FieldJob)
            .Where(c => c.SiteInspection.FieldJob.SolarSurveyId == surveyId)
            .OrderByDescending(c => c.CreatedAt)
            .FirstOrDefaultAsync(ct);

        var siteInspection = compliance?.SiteInspection;

        // 3. Compute technical values from survey sizing result (latest workflow)
        var sizingWorkflow = await _db.AgentWorkflows
            .Where(w => w.SolarSurveyId == surveyId && w.Status == WorkflowStatus.Completed)
            .OrderByDescending(w => w.CompletedAt)
            .FirstOrDefaultAsync(ct);

        decimal recommendedKw = 0m;
        int panelCount = 0;
        decimal inverterSizeKw = 0m;

        if (sizingWorkflow?.ResultJson != null)
        {
            try
            {
                var result = JsonDocument.Parse(sizingWorkflow.ResultJson);
                if (result.RootElement.TryGetProperty("recommended_kw", out var kw))
                    recommendedKw = (decimal)kw.GetDouble();
                if (result.RootElement.TryGetProperty("estimated_panel_count", out var panels))
                    panelCount = panels.GetInt32();
                if (result.RootElement.TryGetProperty("estimated_inverter_kw", out var inv))
                    inverterSizeKw = (decimal)inv.GetDouble();
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Could not parse sizing workflow result JSON for survey {SurveyId}.", surveyId);
            }
        }

        // Fallback sizing from survey data if no workflow result
        if (recommendedKw == 0)
        {
            recommendedKw = Math.Round((decimal)survey.MonthlyKwh / 120m, 2);
            panelCount = Math.Max(1, (int)Math.Round(recommendedKw * 1000 / 400));
            inverterSizeKw = recommendedKw;
        }

        var estimatedCost = (panelCount * PanelUnitPriceLkr) + (inverterSizeKw * InverterPricePerKwLkr);
        var complianceStatus = compliance?.ComplianceStatus ?? "UNKNOWN";
        var riskLevel = compliance?.RiskLevel ?? "UNKNOWN";

        // 4. Create proposal in Draft state
        var workflowId = $"wf-prop-{Guid.NewGuid().ToString("N")[..8]}";
        var proposal = new EngineeringProposal
        {
            SolarSurveyId = surveyId,
            WorkflowId = workflowId,
            RecommendedKw = recommendedKw,
            PanelCount = panelCount,
            InverterSizeKw = inverterSizeKw,
            EstimatedCostLkr = estimatedCost,
            GridComplianceStatus = complianceStatus,
            RiskLevel = riskLevel,
            SafetyStatus = "PENDING",
            ProposalStatus = ProposalStatus.Draft,
            EngineerNotes = notes
        };

        _db.EngineeringProposals.Add(proposal);
        await _db.SaveChangesAsync(ct);
        AddLifecycleEvent(proposal, ProposalLifecycleEvent.PROPOSAL_CREATED, "Proposal created from completed survey.");

        // 5. Transition to Processing → call SafetyGuardrailAgent
        ProposalStatusTransition.ValidateTransition(proposal.ProposalStatus, ProposalStatus.Processing);
        proposal.ProposalStatus = ProposalStatus.Processing;
        proposal.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(ct);

        // 6. Call SafetyGuardrailAgent (fail-safe: defaults to REQUIRES_APPROVAL if AI unavailable)
        AddLifecycleEvent(proposal, ProposalLifecycleEvent.GUARDRAIL_STARTED, "Guardrail evaluation started.");
        var guardrailRequest = new
        {
            proposal_id = proposal.Id.ToString(),
            workflow_id = workflowId,
            recommended_kw = (double)recommendedKw,
            panel_count = panelCount,
            inverter_size_kw = (double)inverterSizeKw,
            estimated_cost_lkr = (double)estimatedCost,
            grid_compliance_status = complianceStatus,
            risk_level = riskLevel,
            grid_type = survey.GridType.ToString(),
            monthly_kwh = (double)survey.MonthlyKwh,
            roof_area_sqm = (double)survey.RoofAreaSqm,
            safety_notes = siteInspection?.SafetyNotes,
            compliance_notes = compliance?.ComplianceNotes
        };

        var guardrailResult = await _ai.EvaluateGuardrailAsync(guardrailRequest, ct);

        proposal.SafetyStatus = guardrailResult?.SafetyStatus ?? "REQUIRES_APPROVAL";
        proposal.GuardrailResultJson = guardrailResult != null
            ? JsonSerializer.Serialize(guardrailResult)
            : null;

        // 7. Deterministic validation — OVERRIDES AI if rules trigger approval requirement
        var validationResult = RunDeterministicValidation(
            recommendedKw, panelCount, inverterSizeKw, estimatedCost,
            complianceStatus, guardrailResult?.RequiresApproval ?? true);

        proposal.RequiresApproval = validationResult.RequiresApproval;
        proposal.ValidationResultJson = JsonSerializer.Serialize(validationResult);
        AddLifecycleEvent(proposal, ProposalLifecycleEvent.VALIDATION_COMPLETED, validationResult.Valid ? "Deterministic validation passed." : "Deterministic validation failed.");
        if (validationResult.RequiresApproval)
            AddLifecycleEvent(proposal, ProposalLifecycleEvent.APPROVAL_REQUIRED, "Senior staff approval is required.");
        else if (!validationResult.Valid)
            AddLifecycleEvent(proposal, ProposalLifecycleEvent.APPROVAL_BLOCKED, "Proposal validation blocked approval.");
        proposal.RecommendationSummary = guardrailResult?.RecommendationSummary
            ?? $"Solar system of {recommendedKw}kW ({panelCount} panels) proposed for {survey.PropertyAddress}.";

        // 8. Transition to PendingApproval (always — high-impact rule)
        ProposalStatusTransition.ValidateTransition(proposal.ProposalStatus, ProposalStatus.PendingApproval);
        proposal.ProposalStatus = ProposalStatus.PendingApproval;
        proposal.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(ct);

        _logger.LogInformation(
            "Engineering proposal {ProposalId} created for survey {SurveyId}. Status: {Status}, RequiresApproval: {Req}",
            proposal.Id, surveyId, proposal.ProposalStatus, proposal.RequiresApproval);

        return await BuildDtoAsync(proposal.Id, null, true, ct) ?? throw new InvalidOperationException("Proposal not found after creation.");
    }

    // ─── Deterministic Validator (authoritative — overrides AI) ──────────────

    private static ProposalValidationResultDto RunDeterministicValidation(
        decimal recommendedKw, int panelCount, decimal inverterSizeKw,
        decimal estimatedCostLkr, string complianceStatus, bool aiSaysRequiresApproval)
    {
        var violations = new List<string>();
        var checks = new List<string>();
        string overrideReason = string.Empty;

        // Required field checks
        if (recommendedKw <= 0) { violations.Add("recommendedKw must be > 0."); checks.Add("FAIL:recommended_kw_positive"); }
        else checks.Add("PASS:recommended_kw_positive");

        if (panelCount <= 0) { violations.Add("panelCount must be > 0."); checks.Add("FAIL:panel_count_positive"); }
        else checks.Add("PASS:panel_count_positive");

        if (inverterSizeKw <= 0) { violations.Add("inverterSizeKw must be > 0."); checks.Add("FAIL:inverter_size_positive"); }
        else checks.Add("PASS:inverter_size_positive");

        if (estimatedCostLkr <= 0) { violations.Add("estimatedCostLkr must be > 0."); checks.Add("FAIL:cost_positive"); }
        else checks.Add("PASS:cost_positive");

        // High-impact approval rules (deterministic, cannot be overridden by AI)
        bool requiresApprovalByRule = false;
        var approvalReasons = new List<string>();

        if (recommendedKw > 10.0m)
        {
            requiresApprovalByRule = true;
            approvalReasons.Add($"recommendedKw ({recommendedKw}kW) > 10kW threshold — approval mandatory.");
            checks.Add("TRIGGER:kw_threshold");
        }
        else checks.Add("PASS:kw_threshold");

        var nonCompliantStatuses = new[] { "NON_COMPLIANT", "CONDITIONAL" };
        if (nonCompliantStatuses.Contains(complianceStatus, StringComparer.OrdinalIgnoreCase))
        {
            requiresApprovalByRule = true;
            approvalReasons.Add($"Grid compliance status '{complianceStatus}' — approval mandatory.");
            checks.Add("TRIGGER:compliance_status");
        }
        else checks.Add("PASS:compliance_status");

        // AI override: if AI says no approval needed but deterministic rule says yes
        if (!aiSaysRequiresApproval && requiresApprovalByRule)
        {
            overrideReason = "Deterministic validator overrode AI: high-impact rule triggered approval requirement.";
        }

        bool finalRequiresApproval = requiresApprovalByRule || aiSaysRequiresApproval;

        return new ProposalValidationResultDto(
            Valid: violations.Count == 0,
            RequiresApproval: finalRequiresApproval,
            Checks: checks,
            Violations: violations.Concat(approvalReasons).ToList(),
            OverrideReason: overrideReason
        );
    }

    // ─── Queries ──────────────────────────────────────────────────────────────

    public async Task<List<EngineeringProposalSummaryDto>> GetAllAsync(CancellationToken ct = default)
        => await _db.EngineeringProposals
            .OrderByDescending(p => p.CreatedAt)
            .Select(p => ToSummaryDto(p))
            .ToListAsync(ct);

    public async Task<List<EngineeringProposalSummaryDto>> GetPendingAsync(CancellationToken ct = default)
        => await _db.EngineeringProposals
            .Where(p => p.ProposalStatus == ProposalStatus.PendingApproval)
            .OrderByDescending(p => p.CreatedAt)
            .Select(p => ToSummaryDto(p))
            .ToListAsync(ct);

    public async Task<List<EngineeringProposalSummaryDto>> GetBySurveyAsync(
        Guid surveyId, Guid requestingUserId, bool isStaff, CancellationToken ct = default)
    {
        var query = _db.EngineeringProposals
            .Where(p => p.SolarSurveyId == surveyId);

        if (!isStaff)
        {
            // Only return if the survey belongs to this homeowner's customer profile
            query = query.Where(p => p.SolarSurvey.Customer.UserId == requestingUserId);
        }

        return await query
            .OrderByDescending(p => p.CreatedAt)
            .Select(p => ToSummaryDto(p))
            .ToListAsync(ct);
    }

    public async Task<EngineeringProposalDto?> GetAsync(Guid proposalId, Guid requestingUserId, bool isStaff, CancellationToken ct = default)
        => await BuildDtoAsync(proposalId, requestingUserId, isStaff, ct);

    // ─── Approve (transactional) ──────────────────────────────────────────────

    public async Task<EngineeringProposalDto> ApproveAsync(
        Guid proposalId, Guid engineerUserId, string? comment, CancellationToken ct = default)
    {
        var approvalBlocked = false;
        await using var transaction = await _db.Database.BeginTransactionAsync(ct);
        try
        {
            var proposal = await _db.EngineeringProposals
                .Include(p => p.AuditLogs)
                .FirstOrDefaultAsync(p => p.Id == proposalId, ct)
                ?? throw new ArgumentException($"Proposal {proposalId} not found.");

            // Step 1: Verify status is PENDING_APPROVAL
            if (proposal.ProposalStatus != ProposalStatus.PendingApproval)
                throw new InvalidOperationException(
                    $"Proposal cannot be approved from status '{proposal.ProposalStatus}'. Only PENDING_APPROVAL proposals can be approved.");

            // Step 2: Re-run deterministic validation
            var reValidation = RunDeterministicValidation(
                proposal.RecommendedKw, proposal.PanelCount, proposal.InverterSizeKw,
                proposal.EstimatedCostLkr, proposal.GridComplianceStatus, proposal.RequiresApproval);

            if (!reValidation.Valid)
            {
                approvalBlocked = true;
                throw new InvalidOperationException(
                    $"Approval blocked: deterministic validation failed. Violations: {string.Join("; ", reValidation.Violations)}");
            }

            // Step 3: Validate state transition
            ProposalStatusTransition.ValidateTransition(proposal.ProposalStatus, ProposalStatus.Approved);

            // Step 4: Update proposal status
            proposal.ProposalStatus = ProposalStatus.Approved;
            proposal.UpdatedAt = DateTime.UtcNow;
            proposal.ValidationResultJson = JsonSerializer.Serialize(reValidation);

            // Step 5: Write audit log
            var auditLog = new ApprovalAuditLog
            {
                EngineeringProposalId = proposalId,
                WorkflowId = proposal.WorkflowId,
                UserId = engineerUserId,
                Decision = ApprovalDecision.Approved,
                Comment = comment,
                Timestamp = DateTime.UtcNow
            };
            _db.ApprovalAuditLogs.Add(auditLog);
            AddLifecycleEvent(proposal, ProposalLifecycleEvent.APPROVED, comment);

            // Step 6: Commit
            await _db.SaveChangesAsync(ct);
            await transaction.CommitAsync(ct);

            _logger.LogInformation("Proposal {ProposalId} APPROVED by engineer {UserId}.", proposalId, engineerUserId);
            return await BuildDtoAsync(proposalId, null, true, ct) ?? throw new InvalidOperationException("Proposal not found after approval.");
        }
        catch
        {
            await transaction.RollbackAsync(ct);
            if (approvalBlocked)
            {
                // Persist a blocked approval after the decision transaction is rolled back.
                var blockedProposal = await _db.EngineeringProposals.FirstOrDefaultAsync(p => p.Id == proposalId, ct);
                if (blockedProposal != null)
                {
                    _db.ProposalLifecycleAuditEvents.Add(new ProposalLifecycleAuditEvent
                    {
                        EngineeringProposalId = proposalId,
                        WorkflowId = blockedProposal.WorkflowId,
                        Event = ProposalLifecycleEvent.APPROVAL_BLOCKED,
                        Details = "Approval blocked by deterministic validation.",
                        Timestamp = DateTime.UtcNow
                    });
                    await _db.SaveChangesAsync(ct);
                }
            }
            throw;
        }
    }

    // ─── Reject ───────────────────────────────────────────────────────────────

    public async Task<EngineeringProposalDto> RejectAsync(
        Guid proposalId, Guid engineerUserId, string comment, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(comment))
            throw new ArgumentException("A comment is required when rejecting a proposal.");

        await using var transaction = await _db.Database.BeginTransactionAsync(ct);
        try
        {
            var proposal = await _db.EngineeringProposals
                .FirstOrDefaultAsync(p => p.Id == proposalId, ct)
                ?? throw new ArgumentException($"Proposal {proposalId} not found.");

            ProposalStatusTransition.ValidateTransition(proposal.ProposalStatus, ProposalStatus.Rejected);

            proposal.ProposalStatus = ProposalStatus.Rejected;
            proposal.UpdatedAt = DateTime.UtcNow;

            _db.ApprovalAuditLogs.Add(new ApprovalAuditLog
            {
                EngineeringProposalId = proposalId,
                WorkflowId = proposal.WorkflowId,
                UserId = engineerUserId,
                Decision = ApprovalDecision.Rejected,
                Comment = comment,
                Timestamp = DateTime.UtcNow
            });
            AddLifecycleEvent(proposal, ProposalLifecycleEvent.REJECTED, comment);

            await _db.SaveChangesAsync(ct);
            await transaction.CommitAsync(ct);

            _logger.LogInformation("Proposal {ProposalId} REJECTED by engineer {UserId}.", proposalId, engineerUserId);
            return await BuildDtoAsync(proposalId, null, true, ct) ?? throw new InvalidOperationException("Proposal not found after rejection.");
        }
        catch
        {
            await transaction.RollbackAsync(ct);
            throw;
        }
    }

    // ─── Request Revision ─────────────────────────────────────────────────────

    public async Task<EngineeringProposalDto> RequestRevisionAsync(
        Guid proposalId, Guid engineerUserId, string comment, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(comment))
            throw new ArgumentException("A comment is required when requesting a revision.");

        await using var transaction = await _db.Database.BeginTransactionAsync(ct);
        try
        {
            var proposal = await _db.EngineeringProposals
                .FirstOrDefaultAsync(p => p.Id == proposalId, ct)
                ?? throw new ArgumentException($"Proposal {proposalId} not found.");

            ProposalStatusTransition.ValidateTransition(proposal.ProposalStatus, ProposalStatus.RevisionRequested);

            proposal.ProposalStatus = ProposalStatus.RevisionRequested;
            proposal.UpdatedAt = DateTime.UtcNow;

            _db.ApprovalAuditLogs.Add(new ApprovalAuditLog
            {
                EngineeringProposalId = proposalId,
                WorkflowId = proposal.WorkflowId,
                UserId = engineerUserId,
                Decision = ApprovalDecision.RevisionRequested,
                Comment = comment,
                Timestamp = DateTime.UtcNow
            });
            AddLifecycleEvent(proposal, ProposalLifecycleEvent.REVISION_REQUESTED, comment);

            await _db.SaveChangesAsync(ct);
            await transaction.CommitAsync(ct);

            _logger.LogInformation("Proposal {ProposalId} REVISION REQUESTED by engineer {UserId}.", proposalId, engineerUserId);
            return await BuildDtoAsync(proposalId, null, true, ct) ?? throw new InvalidOperationException("Proposal not found after revision request.");
        }
        catch
        {
            await transaction.RollbackAsync(ct);
            throw;
        }
    }

    // ─── DTO Mapping ──────────────────────────────────────────────────────────

    private async Task<EngineeringProposalDto?> BuildDtoAsync(Guid proposalId, Guid? requestingUserId, bool isStaff, CancellationToken ct)
    {
        var query = _db.EngineeringProposals
            .Include(x => x.AuditLogs)
            .Include(x => x.SolarSurvey)
                .ThenInclude(s => s.Customer)
            .AsQueryable();

        if (!isStaff && requestingUserId.HasValue)
            query = query.Where(x => x.SolarSurvey.Customer.UserId == requestingUserId.Value);

        var p = await query
            .Include(x => x.LifecycleEvents)
            .Include(x => x.SolarSurvey)
                .ThenInclude(s => s.Customer)
            .FirstOrDefaultAsync(x => x.Id == proposalId, ct);

        if (p == null) return null;
        return ToDetailDto(p);
    }

    private static EngineeringProposalSummaryDto ToSummaryDto(EngineeringProposal p) => new(
        p.Id, p.SolarSurveyId, p.WorkflowId, p.RecommendedKw, p.PanelCount,
        p.InverterSizeKw, p.EstimatedCostLkr, p.GridComplianceStatus, p.RiskLevel,
        p.SafetyStatus, p.ProposalStatus.ToString(), p.RequiresApproval, p.CreatedAt, p.UpdatedAt
    );

    private static EngineeringProposalDto ToDetailDto(EngineeringProposal p) => new(
        p.Id, p.SolarSurveyId, p.WorkflowId,
        p.RecommendedKw, p.PanelCount, p.InverterSizeKw, p.EstimatedCostLkr,
        p.GridComplianceStatus, p.RiskLevel, p.SafetyStatus,
        p.ProposalStatus.ToString(), p.RequiresApproval,
        p.RecommendationSummary, p.EngineerNotes,
        p.GuardrailResultJson, p.ValidationResultJson,
        p.CreatedAt, p.UpdatedAt,
        p.AuditLogs.OrderBy(a => a.Timestamp).Select(a => new ApprovalAuditLogDto(
            a.Id, a.Decision.ToString(), a.Comment, a.UserId, a.WorkflowId, a.Timestamp
        )).ToList(),
        p.LifecycleEvents.OrderBy(a => a.Timestamp).Select(a => new ProposalLifecycleAuditEventDto(
            a.Id, a.Event.ToString(), a.Details, a.WorkflowId, a.Timestamp
        )).ToList(),
        p.SolarSurvey?.Customer?.FullName,
        p.SolarSurvey?.PropertyAddress
    );

    private void AddLifecycleEvent(EngineeringProposal proposal, ProposalLifecycleEvent eventType, string? details)
    {
        _db.ProposalLifecycleAuditEvents.Add(new ProposalLifecycleAuditEvent
        {
            EngineeringProposalId = proposal.Id,
            WorkflowId = proposal.WorkflowId,
            Event = eventType,
            Details = details,
            Timestamp = DateTime.UtcNow
        });
    }
}
