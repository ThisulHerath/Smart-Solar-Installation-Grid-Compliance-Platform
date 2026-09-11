import React, { useState, useEffect, useCallback } from 'react';
import { Link } from 'react-router-dom';
import { getPendingProposals } from '../services/proposalService';
import { EngineeringProposalSummary } from '../types/ProposalTypes';

function fmtLkr(v: number) {
  return `LKR ${v.toLocaleString('en-LK', { maximumFractionDigits: 0 })}`;
}

export const PendingApprovalsPage: React.FC = () => {
  const [proposals, setProposals] = useState<EngineeringProposalSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      setProposals(await getPendingProposals());
    } catch (e: any) {
      setError(e.message || 'Failed to load pending proposals.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  return (
    <div className="page-container">
      <div className="page-header">
        <div>
          <h1 className="page-title" style={{ color: '#F59E0B' }}>⚠ Pending Approvals</h1>
          <p className="page-subtitle">Engineering proposals awaiting your decision</p>
        </div>
        <button onClick={load} className="btn btn-secondary" disabled={loading}>
          {loading ? 'Refreshing…' : '↻ Refresh'}
        </button>
      </div>

      {error && <div className="alert alert--error"><strong>Error:</strong> {error}</div>}

      {loading ? (
        <div className="loading-state">Loading pending approvals…</div>
      ) : proposals.length === 0 ? (
        <div className="empty-state">
          <div className="empty-state__icon">✅</div>
          <p>No proposals pending approval. All caught up!</p>
        </div>
      ) : (
        <>
          <p style={{ color: '#94A3B8', marginBottom: '20px' }}>
            <strong style={{ color: '#F59E0B' }}>{proposals.length}</strong> proposal{proposals.length !== 1 ? 's' : ''} awaiting engineer decision.
          </p>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            {proposals.map(p => (
              <div key={p.id} className="card card--pending" id={`pending-card-${p.id}`}>
                <div className="card__header">
                  <div style={{ display: 'flex', gap: '12px', alignItems: 'center' }}>
                    <span className="status-badge status-badge--pending">Pending Approval</span>
                    {p.requiresApproval && (
                      <span className="badge badge--red">High-Impact</span>
                    )}
                    <span className={`badge ${p.riskLevel === 'LOW' ? 'badge--green' : p.riskLevel === 'MEDIUM' ? 'badge--yellow' : 'badge--red'}`}>
                      Risk: {p.riskLevel}
                    </span>
                  </div>
                  <span style={{ color: '#64748B', fontSize: '13px' }}>
                    {new Date(p.createdAt).toLocaleDateString()} {new Date(p.createdAt).toLocaleTimeString()}
                  </span>
                </div>

                <div className="card__body">
                  <div className="spec-grid">
                    <div className="spec-item">
                      <span className="spec-label">System Size</span>
                      <span className="spec-value">{p.recommendedKw.toFixed(2)} kW</span>
                    </div>
                    <div className="spec-item">
                      <span className="spec-label">Panels</span>
                      <span className="spec-value">{p.panelCount}</span>
                    </div>
                    <div className="spec-item">
                      <span className="spec-label">Inverter</span>
                      <span className="spec-value">{p.inverterSizeKw.toFixed(2)} kW</span>
                    </div>
                    <div className="spec-item">
                      <span className="spec-label">Estimated Cost</span>
                      <span className="spec-value">{fmtLkr(p.estimatedCostLkr)}</span>
                    </div>
                    <div className="spec-item">
                      <span className="spec-label">Grid Compliance</span>
                      <span className={`spec-value ${p.gridComplianceStatus === 'COMPLIANT' ? 'text-green' : 'text-red'}`}>
                        {p.gridComplianceStatus}
                      </span>
                    </div>
                    <div className="spec-item">
                      <span className="spec-label">Safety Status</span>
                      <span className="spec-value">{p.safetyStatus}</span>
                    </div>
                  </div>
                </div>

                <div className="card__footer">
                  <Link to={`/proposals/${p.id}`} className="btn btn-primary" id={`review-proposal-${p.id}`}>
                    Review &amp; Decide →
                  </Link>
                </div>
              </div>
            ))}
          </div>
        </>
      )}
    </div>
  );
};
