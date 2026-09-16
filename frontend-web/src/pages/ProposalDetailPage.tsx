import { ValidatedForm } from '../components/ValidatedForm';
import { RecordReference } from '../components/RecordReference';
import React, { useState, useEffect, useCallback } from 'react';
import { WorkflowSummary } from '../components/WorkflowSummary';
import { InspectionPhotoGallery } from '../components/InspectionPhotoGallery';
import { useAuth } from '../context/AuthContext';
import { useParams, useNavigate } from 'react-router-dom';
import {
  getProposal,
  approveProposal,
  rejectProposal,
  reviseProposal,
} from '../services/proposalService';
import { EngineeringProposal, ValidationResult, GuardrailResult, ApprovalAuditLog } from '../types/ProposalTypes';

// ── Helpers ───────────────────────────────────────────────────────────────────

const STATUS_COLORS: Record<string, string> = {
  Draft:             '#60715e',
  Processing:        '#3B82F6',
  PendingApproval:   '#8b580b',
  Approved:          '#287247',
  Rejected:          '#b33838',
  RevisionRequested: '#705193',
  Failed:            '#b33838',
};

const STATUS_LABELS: Record<string, string> = {
  Draft: 'Draft', Processing: 'Processing', PendingApproval: 'Pending Approval',
  Approved: 'Approved', Rejected: 'Rejected', RevisionRequested: 'Revision Requested', Failed: 'Failed',
};

const DECISION_COLORS: Record<string, string> = {
  Approved: '#287247', Rejected: '#b33838', RevisionRequested: '#705193',
};

function fmtLkr(v: number) {
  return `LKR ${v.toLocaleString('en-LK', { maximumFractionDigits: 0 })}`;
}

function parseValidationResult(raw?: string | null): ValidationResult | null {
  if (!raw) return null;
  try {
    const data = typeof raw === 'string' ? JSON.parse(raw) : raw;
    if (!data || typeof data !== 'object') return null;
    return {
      valid: Boolean(data.valid ?? data.Valid ?? false),
      requiresApproval: Boolean(data.requiresApproval ?? data.RequiresApproval ?? false),
      checks: Array.isArray(data.checks) ? data.checks : (Array.isArray(data.Checks) ? data.Checks : []),
      violations: Array.isArray(data.violations) ? data.violations : (Array.isArray(data.Violations) ? data.Violations : []),
      overrideReason: String(data.overrideReason ?? data.OverrideReason ?? ''),
    };
  } catch {
    return null;
  }
}

function parseGuardrailResult(raw?: string | null): GuardrailResult | null {
  if (!raw) return null;
  try {
    const data = typeof raw === 'string' ? JSON.parse(raw) : raw;
    if (!data || typeof data !== 'object') return null;
    return {
      safetyStatus: String(data.safetyStatus ?? data.safety_status ?? data.SafetyStatus ?? ''),
      riskLevel: String(data.riskLevel ?? data.risk_level ?? data.RiskLevel ?? ''),
      requiresApproval: Boolean(data.requiresApproval ?? data.requires_approval ?? data.RequiresApproval ?? false),
      issues: Array.isArray(data.issues) ? data.issues : (Array.isArray(data.Issues) ? data.Issues : []),
      recommendations: Array.isArray(data.recommendations) ? data.recommendations : (Array.isArray(data.Recommendations) ? data.Recommendations : []),
      recommendationSummary: data.recommendationSummary ?? data.recommendation_summary ?? data.RecommendationSummary,
    };
  } catch {
    return null;
  }
}

// ── Modal ─────────────────────────────────────────────────────────────────────

interface ModalProps {
  title: string;
  action: 'approve' | 'reject' | 'revise';
  isPending: boolean;
  onConfirm: (comment: string) => void;
  onCancel: () => void;
}

const ActionModal: React.FC<ModalProps> = ({ title, action, isPending, onConfirm, onCancel }) => {
  const [comment, setComment] = useState('');
  const needsComment = action !== 'approve';


  return (
    <div className="modal-overlay" id={`modal-${action}`}>
      <ValidatedForm onSubmit={e => { e.preventDefault(); onConfirm(comment); }} className="modal proposal-decision" role="dialog" aria-modal="true" aria-labelledby="decision-title" aria-describedby="decision-description">
        <div className="proposal-decision__heading">
          <p className="proposal-decision__eyebrow">SMARTSOLAR · ENGINEERING REVIEW</p>
          <h3 className="modal__title" id="decision-title">{title}</h3>
          <p className="proposal-decision__description" id="decision-description">
            {action === 'revise' ? 'Tell the homeowner what needs to change before this solar proposal can move forward.' :
              action === 'reject' ? 'Explain why this solar proposal cannot proceed. Your reason will be saved in the review history.' :
              'Confirm your review of the system design, site inspection and grid compliance results.'}
          </p>
        </div>

        {action === 'approve' && (
          <div className="alert alert--warning" style={{ marginBottom: '16px' }}>
            <strong>⚠ This action will approve the engineering proposal.</strong>
            <br />This cannot be undone. Ensure all technical validations have passed.
          </div>
        )}

        {needsComment && (
          <div className="form-group">
            <label className="form-label" htmlFor={`comment-${action}`}>
              {action === 'revise' ? 'What needs to be revised?' : 'Reason for rejection'} <span className="proposal-decision__required">Required</span>
            </label>
            <textarea
              id={`comment-${action}`}
              className="form-textarea"
              autoFocus
              required
              value={comment}
              onChange={e => setComment(e.target.value)}
              placeholder={
                action === 'reject'
                  ? 'Reason for rejection (required)…'
                  : 'For example: Update the proposal using the completed site compliance assessment.'
              }
              rows={4}
            />
            <p className="proposal-decision__hint">{action === 'revise' ? 'The homeowner can request an updated proposal after your revision request.' : 'This explanation will help the homeowner understand your decision.'}</p>
          </div>
        )}

        <div className="modal__actions">
          <button
            className="btn btn-secondary"
            type="button" onClick={onCancel}
            disabled={isPending}
            id={`cancel-${action}`}
          >
            Cancel
          </button>
          <button
            className={`btn ${action === 'approve' ? 'btn-success' : action === 'reject' ? 'btn-danger' : 'btn-warning'}`}
            type="submit"
            disabled={isPending}
            id={`confirm-${action}`}
          >
            {isPending ? 'Processing…' : (
              action === 'approve' ? '✓ Confirm Approval' :
              action === 'reject' ? '✕ Confirm Rejection' :
              '↻ Request Revision'
            )}
          </button>
        </div>
      </ValidatedForm>
    </div>
  );
};

// ── Main Component ────────────────────────────────────────────────────────────

export const ProposalDetailPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const [proposal, setProposal] = useState<EngineeringProposal | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [actionLoading, setActionLoading] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);
  const [modal, setModal] = useState<'approve' | 'reject' | 'revise' | null>(null);

  const load = useCallback(async () => {
    if (!id) return;
    setLoading(true);
    setError(null);
    try {
      setProposal(await getProposal(id));
    } catch (e: any) {
      setError(e.message || 'Failed to load proposal.');
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => { load(); }, [load]);

  const validationResult = parseValidationResult(proposal?.validationResultJson);
  const guardrailResult = parseGuardrailResult(proposal?.guardrailResultJson);

  const { user } = useAuth();
  const isEngineeringStaff = Boolean(user?.roles.some(role => ['SENIOR_ENGINEER', 'ADMINISTRATOR'].includes(role)));
  const isPending = proposal?.proposalStatus === 'PendingApproval' && isEngineeringStaff;
  const missingCompliance = !proposal?.gridComplianceStatus || proposal.gridComplianceStatus.toUpperCase() === 'UNKNOWN';
  const validationPassed = validationResult ? validationResult.valid || validationResult.requiresApproval : true;
  const approvalBlocked = !validationPassed;

  async function handleAction(action: 'approve' | 'reject' | 'revise', comment: string) {
    if (!id) return;
    setActionLoading(true);
    setActionError(null);
    try {
      let updated: EngineeringProposal;
      if (action === 'approve') updated = await approveProposal(id, { comment });
      else if (action === 'reject') updated = await rejectProposal(id, { comment });
      else updated = await reviseProposal(id, { comment });
      setProposal(updated);
      setModal(null);
    } catch (e: any) {
      setActionError(e.message || 'Action failed.');
      setModal(null);
    } finally {
      setActionLoading(false);
    }
  }

  // ── Render ─────────────────────────────────────────────────────────────────

  if (loading) return <div className="page-container"><div className="loading-state">Loading proposal…</div></div>;
  if (error) return <div className="page-container"><div className="alert alert--error">{error}</div></div>;
  if (!proposal) return <div className="page-container"><div className="alert alert--error">Proposal not found.</div></div>;

  const statusColor = STATUS_COLORS[proposal.proposalStatus] || '#60715e';

  return (
    <div className="page-container">
      {/* Header */}
      <div className="page-header">
        <div>
          <button onClick={() => navigate('/proposals')} className="btn btn-ghost" style={{ marginBottom: '8px' }}>
            ← Back to Proposals
          </button>
          <h1 className="page-title">Engineering Proposal</h1>
          <div className="page-subtitle" style={{ fontFamily: 'monospace', fontSize: '13px' }}>
            <RecordReference label="Proposal reference" value={proposal.id} /><RecordReference label="Survey reference" value={proposal.solarSurveyId} />
          </div>
        </div>
        <span className="status-badge" style={{ backgroundColor: statusColor + '22', color: statusColor, border: `1px solid ${statusColor}44`, padding: '8px 16px', fontSize: '14px', fontWeight: 700 }}>
          {STATUS_LABELS[proposal.proposalStatus] ?? proposal.proposalStatus}
        </span>
      </div>

      {actionError && (
        <div className="alert alert--error" style={{ marginBottom: '16px' }}>
          <strong>Action failed:</strong> {actionError}
        </div>
      )}

      {/* Validation Block */}
      {approvalBlocked && (
        <div className="alert alert--error" id="approval-blocked-notice">
          <strong>This proposal needs an update before approval.</strong>
          {validationResult?.violations?.map((v, i) => <div key={i} style={{ marginTop: '4px', fontSize: '13px' }}>• {v}</div>)}
        </div>
      )}

      {validationResult?.overrideReason && (
        <div className="alert alert--warning" id="ai-override-notice">
          <strong>Additional review required:</strong> {validationResult.overrideReason}
        </div>
      )}

      <div className="detail-grid">
        {/* Customer / Site Summary */}
        <div className="detail-card">
          <h2 className="detail-card__title">📍 Customer & Site</h2>
          <div className="detail-row"><span>Customer</span><strong>{proposal.customerName || '—'}</strong></div>
          <div className="detail-row"><span>Property</span><strong>{proposal.propertyAddress || '—'}</strong></div>

        </div>

        {/* Technical Specs */}

        <div className="detail-card">
          <h2 className="detail-card__title">⚡ Technical Specifications</h2>
          <div className="detail-row"><span>Recommended System</span><strong>{proposal.recommendedKw.toFixed(2)} kW</strong></div>
          <div className="detail-row"><span>Panel Count</span><strong>{proposal.panelCount} panels</strong></div>
          <div className="detail-row"><span>Inverter Size</span><strong>{proposal.inverterSizeKw.toFixed(2)} kW</strong></div>
          <div className="detail-row"><span>Estimated Cost</span><strong style={{ color: '#287247' }}>{fmtLkr(proposal.estimatedCostLkr)}</strong></div>
        </div>

        {/* Compliance & Safety */}
        <div className="detail-card">
          <h2 className="detail-card__title">🛡 Compliance & Safety</h2>
          <div className="detail-row">
            <span>Grid Compliance</span>
            <span className={`badge ${proposal.gridComplianceStatus === 'COMPLIANT' ? 'badge--green' : 'badge--red'}`}>
              {proposal.gridComplianceStatus}
            </span>
          </div>
          <div className="detail-row">
            <span>Risk Level</span>
            <span className={`badge ${proposal.riskLevel === 'LOW' ? 'badge--green' : proposal.riskLevel === 'MEDIUM' ? 'badge--yellow' : 'badge--red'}`}>
              {proposal.riskLevel}
            </span>
          </div>
          <div className="detail-row">
            <span>Safety Status</span>
            <span className={`badge ${!missingCompliance && proposal.safetyStatus === 'SAFE' ? 'badge--green' : 'badge--yellow'}`}>
              {missingCompliance ? 'Awaiting assessment' : proposal.safetyStatus}
            </span>
          </div>
          <div className="detail-row">
            <span>Engineer review</span>
            <span className="badge badge--yellow">
              {STATUS_LABELS[proposal.proposalStatus] ?? proposal.proposalStatus}
            </span>
          </div>
        </div>

        {/* AI Recommendation Summary */}
        {(proposal.recommendationSummary || guardrailResult) && (
          <div className="detail-card detail-card--wide">
            <h2 className="detail-card__title">Proposal guidance</h2>
            {(proposal.recommendationSummary || missingCompliance) && (
              <p style={{ color: '#4f6352', marginBottom: '12px', lineHeight: 1.6 }}>{missingCompliance ? 'This proposal was prepared without a confirmed site compliance result. Request an updated proposal after the inspection is complete.' : proposal.recommendationSummary}</p>
            )}
            <p className="proposal-guidance-note">Prepared with automated sizing and safety checks. An authorized engineer reviews the proposal before it can proceed.</p>

            {!missingCompliance && guardrailResult?.issues && guardrailResult.issues.length > 0 && (
              <>
                <p style={{ color: '#8b580b', fontWeight: 600, marginBottom: '6px', fontSize: '13px' }}>Detected Issues:</p>
                <ul style={{ color: '#5f705a', fontSize: '13px', paddingLeft: '20px' }}>
                  {guardrailResult.issues.map((issue, i) => <li key={i} style={{ marginBottom: '4px' }}>{issue}</li>)}
                </ul>
              </>
            )}
            {!missingCompliance && guardrailResult?.recommendations && guardrailResult.recommendations.length > 0 && (
              <>
                <p style={{ color: '#287247', fontWeight: 600, marginBottom: '6px', marginTop: '12px', fontSize: '13px' }}>Recommendations:</p>
                <ul style={{ color: '#5f705a', fontSize: '13px', paddingLeft: '20px' }}>
                  {guardrailResult.recommendations.map((rec, i) => <li key={i} style={{ marginBottom: '4px' }}>{rec}</li>)}
                </ul>
              </>
            )}
          </div>
        )}

        {/* Detailed evidence remains available to engineering staff without dominating the proposal. */}
        {isEngineeringStaff && (
          <details className="detail-card detail-card--wide proposal-review-details">
            <summary>Engineering review details</summary>
            <p className="proposal-guidance-note">Supporting checks and workflow records for the engineering team. These automated results do not grant approval.</p>
            {validationResult && <>
              <h3>Automated checks</h3>
              <p>{validationResult.valid ? 'Checks passed. The engineer’s decision is recorded separately.' : 'Some checks need attention before approval.'}</p>
              <ul className="proposal-check-list">{(validationResult.checks ?? []).map((check, i) => {
                const [result, name] = check.split(':');
                const labels: Record<string, string> = {
                  recommended_kw_positive: 'System capacity provided', panel_count_positive: 'Panel quantity provided',
                  inverter_size_positive: 'Inverter capacity provided', cost_positive: 'Cost estimate provided',
                  compliance_assessment_required: 'Completed site compliance assessment', kw_threshold: 'System capacity review threshold',
                  compliance_status: 'Grid compliance review',
                };
                return <li key={i}><span>{labels[name] || (name || check).replace(/_/g, ' ')}</span><strong>{result === 'PASS' ? 'Passed' : result === 'FAIL' ? 'Needs attention' : 'Review required'}</strong></li>;
              })}</ul>
              <details className="proposal-technical-record"><summary>Technical check codes</summary><ul>{(validationResult.checks ?? []).map((check, i) => <li key={i}><code>{check}</code></li>)}</ul></details>
            </>}
            <WorkflowSummary surveyId={proposal.solarSurveyId} />
            <p className="proposal-guidance-note">Proposal record: {proposal.id} · Survey record: {proposal.solarSurveyId}</p>
          </details>
        )}
      </div>

      {/* Approval Actions */}
      {isEngineeringStaff && <InspectionPhotoGallery surveyId={proposal.solarSurveyId} />}
      {isPending && (
        <div className="action-bar" id="approval-actions">
          <h2 style={{ color: '#8b580b', fontWeight: 700, marginBottom: '12px' }}>Engineer Decision</h2>

          {approvalBlocked && (
            <div className="alert alert--error">
              Approval is blocked. Request revision so the homeowner can generate an updated proposal using the completed inspection, or reject this proposal.
            </div>
          )}
            <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
              <button
                className="btn btn-success"
                id="btn-approve"
                onClick={() => setModal('approve')}
                disabled={actionLoading || approvalBlocked}
              >
                ✓ Approve Proposal
              </button>
              <button
                className="btn btn-danger"
                id="btn-reject"
                onClick={() => setModal('reject')}
                disabled={actionLoading}
              >
                ✕ Reject Proposal
              </button>
              <button
                className="btn btn-warning"
                id="btn-revise"
                onClick={() => setModal('revise')}
                disabled={actionLoading}
              >
                ↻ Request Revision
              </button>
            </div>
        </div>
      )}

      {/* Audit History */}
      {(proposal.auditLogs ?? []).length > 0 && (
        <div className="detail-card detail-card--wide" style={{ marginTop: '24px' }}>
          <h2 className="detail-card__title">Review history</h2>
          <p className="proposal-guidance-note">Decisions and feedback recorded during the review of this proposal.</p>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            {(proposal.auditLogs ?? []).map((log: ApprovalAuditLog) => (
              <div key={log.id} className="audit-entry" id={`audit-${log.id}`}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <span className="badge" style={{
                    backgroundColor: (DECISION_COLORS[log.decision] || '#60715e') + '22',
                    color: DECISION_COLORS[log.decision] || '#60715e',
                    border: `1px solid ${(DECISION_COLORS[log.decision] || '#60715e')}44`
                  }}>
                    {log.decision === 'RevisionRequested' ? 'Revision Requested' : log.decision}
                  </span>
                  <span style={{ color: '#60715e', fontSize: '12px' }}>
                    {new Date(log.timestamp).toLocaleString()}
                  </span>
                </div>
                {log.comment && (
                  <p style={{ color: '#5f705a', fontSize: '13px', marginTop: '8px', fontStyle: 'italic' }}>
                    "{log.comment}"
                  </p>
                )}
                <p style={{ color: '#60715e', fontSize: '11px', marginTop: '4px' }}>
                  Recorded by an authorized reviewer
                </p>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Action Modals */}
      {modal === 'approve' && (
        <ActionModal
          title="Approve Engineering Proposal"
          action="approve"
          isPending={actionLoading}
          onConfirm={comment => handleAction('approve', comment)}
          onCancel={() => setModal(null)}
        />
      )}
      {modal === 'reject' && (
        <ActionModal
          title="Reject Engineering Proposal"
          action="reject"
          isPending={actionLoading}
          onConfirm={comment => handleAction('reject', comment)}
          onCancel={() => setModal(null)}
        />
      )}
      {modal === 'revise' && (
        <ActionModal
          title="Request Proposal Revision"
          action="revise"
          isPending={actionLoading}
          onConfirm={comment => handleAction('revise', comment)}
          onCancel={() => setModal(null)}
        />
      )}
    </div>
  );
};
