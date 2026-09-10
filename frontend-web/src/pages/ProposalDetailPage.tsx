import React, { useState, useEffect, useCallback } from 'react';
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
  Draft:             '#64748B',
  Processing:        '#3B82F6',
  PendingApproval:   '#F59E0B',
  Approved:          '#10B981',
  Rejected:          '#EF4444',
  RevisionRequested: '#8B5CF6',
  Failed:            '#EF4444',
};

const STATUS_LABELS: Record<string, string> = {
  Draft: 'Draft', Processing: 'Processing', PendingApproval: 'Pending Approval',
  Approved: 'Approved', Rejected: 'Rejected', RevisionRequested: 'Revision Requested', Failed: 'Failed',
};

const DECISION_COLORS: Record<string, string> = {
  Approved: '#10B981', Rejected: '#EF4444', RevisionRequested: '#8B5CF6',
};

function fmtLkr(v: number) {
  return `LKR ${v.toLocaleString('en-LK', { maximumFractionDigits: 0 })}`;
}

function parseJson<T>(raw?: string | null): T | null {
  if (!raw) return null;
  try { return JSON.parse(raw) as T; } catch { return null; }
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
  const canSubmit = !needsComment || comment.trim().length > 0;

  return (
    <div className="modal-overlay" id={`modal-${action}`}>
      <div className="modal">
        <h3 className="modal__title">{title}</h3>

        {action === 'approve' && (
          <div className="alert alert--warning" style={{ marginBottom: '16px' }}>
            <strong>⚠ This action will approve the engineering proposal.</strong>
            <br />This cannot be undone. Ensure all technical validations have passed.
          </div>
        )}

        {needsComment && (
          <div className="form-group">
            <label className="form-label">
              Comment <span style={{ color: '#EF4444' }}>*</span>
            </label>
            <textarea
              id={`comment-${action}`}
              className="form-textarea"
              value={comment}
              onChange={e => setComment(e.target.value)}
              placeholder={
                action === 'reject'
                  ? 'Reason for rejection (required)…'
                  : 'Revision instructions for the team (required)…'
              }
              rows={4}
            />
          </div>
        )}

        <div className="modal__actions">
          <button
            className="btn btn-secondary"
            onClick={onCancel}
            disabled={isPending}
            id={`cancel-${action}`}
          >
            Cancel
          </button>
          <button
            className={`btn ${action === 'approve' ? 'btn-success' : action === 'reject' ? 'btn-danger' : 'btn-warning'}`}
            onClick={() => onConfirm(comment)}
            disabled={isPending || !canSubmit}
            id={`confirm-${action}`}
          >
            {isPending ? 'Processing…' : (
              action === 'approve' ? '✓ Confirm Approval' :
              action === 'reject' ? '✕ Confirm Rejection' :
              '↻ Request Revision'
            )}
          </button>
        </div>
      </div>
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

  const validationResult = parseJson<ValidationResult>(proposal?.validationResultJson);
  const guardrailResult = parseJson<GuardrailResult>(proposal?.guardrailResultJson);

  const isPending = proposal?.proposalStatus === 'PendingApproval';
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

  const statusColor = STATUS_COLORS[proposal.proposalStatus] || '#64748B';

  return (
    <div className="page-container">
      {/* Header */}
      <div className="page-header">
        <div>
          <button onClick={() => navigate('/proposals')} className="btn btn-ghost" style={{ marginBottom: '8px' }}>
            ← Back to Proposals
          </button>
          <h1 className="page-title">Engineering Proposal</h1>
          <p className="page-subtitle" style={{ fontFamily: 'monospace', fontSize: '13px' }}>
            ID: {proposal.id}
          </p>
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
          <strong>🚫 Approval blocked because validation failed.</strong>
          {validationResult?.violations?.map((v, i) => <div key={i} style={{ marginTop: '4px', fontSize: '13px' }}>• {v}</div>)}
        </div>
      )}

      {validationResult?.overrideReason && (
        <div className="alert alert--warning" id="ai-override-notice">
          <strong>⚡ AI Override:</strong> {validationResult.overrideReason}
        </div>
      )}

      <div className="detail-grid">
        {/* Customer / Site Summary */}
        <div className="detail-card">
          <h2 className="detail-card__title">📍 Customer & Site</h2>
          <div className="detail-row"><span>Customer</span><strong>{proposal.customerName || '—'}</strong></div>
          <div className="detail-row"><span>Property</span><strong>{proposal.propertyAddress || '—'}</strong></div>
          <div className="detail-row"><span>Survey ID</span><code>{proposal.solarSurveyId}</code></div>
          <div className="detail-row"><span>Workflow</span><code>{proposal.workflowId || '—'}</code></div>
        </div>

        {/* Technical Specs */}
        <div className="detail-card">
          <h2 className="detail-card__title">⚡ Technical Specifications</h2>
          <div className="detail-row"><span>Recommended System</span><strong>{proposal.recommendedKw.toFixed(2)} kW</strong></div>
          <div className="detail-row"><span>Panel Count</span><strong>{proposal.panelCount} panels</strong></div>
          <div className="detail-row"><span>Inverter Size</span><strong>{proposal.inverterSizeKw.toFixed(2)} kW</strong></div>
          <div className="detail-row"><span>Estimated Cost</span><strong style={{ color: '#10B981' }}>{fmtLkr(proposal.estimatedCostLkr)}</strong></div>
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
            <span className={`badge ${proposal.safetyStatus === 'SAFE' ? 'badge--green' : 'badge--yellow'}`}>
              {proposal.safetyStatus}
            </span>
          </div>
          <div className="detail-row">
            <span>Requires Approval</span>
            <span className={`badge ${proposal.requiresApproval ? 'badge--red' : 'badge--green'}`}>
              {proposal.requiresApproval ? 'Yes (Mandatory)' : 'No'}
            </span>
          </div>
        </div>

        {/* AI Recommendation Summary */}
        {(proposal.recommendationSummary || guardrailResult) && (
          <div className="detail-card detail-card--wide">
            <h2 className="detail-card__title">🤖 AI Recommendation Summary</h2>
            {proposal.recommendationSummary && (
              <p style={{ color: '#CBD5E1', marginBottom: '12px', lineHeight: 1.6 }}>{proposal.recommendationSummary}</p>
            )}
            {guardrailResult?.issues && guardrailResult.issues.length > 0 && (
              <>
                <p style={{ color: '#F59E0B', fontWeight: 600, marginBottom: '6px', fontSize: '13px' }}>Detected Issues:</p>
                <ul style={{ color: '#94A3B8', fontSize: '13px', paddingLeft: '20px' }}>
                  {guardrailResult.issues.map((issue, i) => <li key={i} style={{ marginBottom: '4px' }}>{issue}</li>)}
                </ul>
              </>
            )}
            {guardrailResult?.recommendations && guardrailResult.recommendations.length > 0 && (
              <>
                <p style={{ color: '#10B981', fontWeight: 600, marginBottom: '6px', marginTop: '12px', fontSize: '13px' }}>Recommendations:</p>
                <ul style={{ color: '#94A3B8', fontSize: '13px', paddingLeft: '20px' }}>
                  {guardrailResult.recommendations.map((rec, i) => <li key={i} style={{ marginBottom: '4px' }}>{rec}</li>)}
                </ul>
              </>
            )}
          </div>
        )}

        {/* Deterministic Validation */}
        {validationResult && (
          <div className="detail-card detail-card--wide">
            <h2 className="detail-card__title">🔒 Deterministic Validation Result</h2>
            <div style={{ display: 'flex', gap: '12px', marginBottom: '12px' }}>
              <span className={`badge ${validationResult.valid ? 'badge--green' : 'badge--red'}`}>
                {validationResult.valid ? '✓ Valid' : '✕ Invalid'}
              </span>
              <span className={`badge ${validationResult.requiresApproval ? 'badge--yellow' : 'badge--green'}`}>
                {validationResult.requiresApproval ? 'Requires Approval' : 'No Approval Required'}
              </span>
            </div>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px' }}>
              {validationResult.checks.map((c, i) => (
                <span key={i} className={`chip ${c.startsWith('PASS') ? 'chip--green' : 'chip--red'}`}>{c}</span>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Approval Actions */}
      {isPending && (
        <div className="action-bar" id="approval-actions">
          <h2 style={{ color: '#F59E0B', fontWeight: 700, marginBottom: '12px' }}>Engineer Decision</h2>

          {approvalBlocked ? (
            <div className="alert alert--error">
              🚫 Approval blocked because validation failed. Resolve validation issues before approving.
            </div>
          ) : (
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
          )}
        </div>
      )}

      {/* Audit History */}
      {proposal.auditLogs.length > 0 && (
        <div className="detail-card detail-card--wide" style={{ marginTop: '24px' }}>
          <h2 className="detail-card__title">📜 Approval Audit History</h2>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            {proposal.auditLogs.map((log: ApprovalAuditLog) => (
              <div key={log.id} className="audit-entry" id={`audit-${log.id}`}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <span className="badge" style={{
                    backgroundColor: (DECISION_COLORS[log.decision] || '#64748B') + '22',
                    color: DECISION_COLORS[log.decision] || '#64748B',
                    border: `1px solid ${(DECISION_COLORS[log.decision] || '#64748B')}44`
                  }}>
                    {log.decision === 'RevisionRequested' ? 'Revision Requested' : log.decision}
                  </span>
                  <span style={{ color: '#64748B', fontSize: '12px' }}>
                    {new Date(log.timestamp).toLocaleString()}
                  </span>
                </div>
                {log.comment && (
                  <p style={{ color: '#94A3B8', fontSize: '13px', marginTop: '8px', fontStyle: 'italic' }}>
                    "{log.comment}"
                  </p>
                )}
                <p style={{ color: '#64748B', fontSize: '11px', marginTop: '4px' }}>
                  Engineer: {log.userId.slice(0, 8)}…
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
