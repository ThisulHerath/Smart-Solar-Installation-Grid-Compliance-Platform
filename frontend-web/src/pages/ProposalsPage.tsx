import React, { useState, useEffect, useCallback } from 'react';
import { Link } from 'react-router-dom';
import { getProposals } from '../services/proposalService';
import { EngineeringProposalSummary, ProposalStatus } from '../types/ProposalTypes';

const STATUS_COLORS: Record<string, string> = {
  Draft:             'status-badge--draft',
  Processing:        'status-badge--processing',
  PendingApproval:   'status-badge--pending',
  Approved:          'status-badge--approved',
  Rejected:          'status-badge--rejected',
  RevisionRequested: 'status-badge--revision',
  Failed:            'status-badge--failed',
};

const STATUS_LABELS: Record<string, string> = {
  Draft:             'Draft',
  Processing:        'Processing',
  PendingApproval:   'Pending Approval',
  Approved:          'Approved',
  Rejected:          'Rejected',
  RevisionRequested: 'Revision Requested',
  Failed:            'Failed',
};

function fmtLkr(v: number) {
  return `LKR ${v.toLocaleString('en-LK', { maximumFractionDigits: 0 })}`;
}

export const ProposalsPage: React.FC = () => {
  const [proposals, setProposals] = useState<EngineeringProposalSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<ProposalStatus | 'All'>('All');

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await getProposals();
      setProposals(data);
    } catch (e: any) {
      setError(e.message || 'Failed to load proposals.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  const displayed = filter === 'All'
    ? proposals
    : proposals.filter(p => p.proposalStatus === filter);

  const pendingCount = proposals.filter(p => p.proposalStatus === 'PendingApproval').length;

  return (
    <div className="page-container">
      <div className="page-header">
        <div>
          <h1 className="page-title">Engineering Proposals</h1>
          <p className="page-subtitle">All solar installation proposals across the platform</p>
        </div>
        <div style={{ display: 'flex', gap: '12px', alignItems: 'center' }}>
          {pendingCount > 0 && (
            <Link to="/proposals/pending" className="btn btn-warning" style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <span>⚠</span> {pendingCount} Pending Approval{pendingCount > 1 ? 's' : ''}
            </Link>
          )}
          <button onClick={load} className="btn btn-secondary" disabled={loading}>
            {loading ? 'Refreshing…' : '↻ Refresh'}
          </button>
        </div>
      </div>

      {/* Filters */}
      <div className="filter-bar">
        {(['All', 'PendingApproval', 'Approved', 'Rejected', 'RevisionRequested', 'Processing', 'Draft'] as const).map(s => (
          <button
            key={s}
            onClick={() => setFilter(s)}
            className={`filter-chip ${filter === s ? 'filter-chip--active' : ''}`}
          >
            {s === 'All' ? 'All' : (STATUS_LABELS[s] ?? s)}
          </button>
        ))}
      </div>

      {error && (
        <div className="alert alert--error">
          <strong>Error:</strong> {error}
        </div>
      )}

      {loading ? (
        <div className="loading-state">Loading proposals…</div>
      ) : displayed.length === 0 ? (
        <div className="empty-state">
          <div className="empty-state__icon">📋</div>
          <p>No proposals found{filter !== 'All' ? ` with status "${STATUS_LABELS[filter] ?? filter}"` : ''}.</p>
        </div>
      ) : (
        <div className="data-table-wrapper">
          <table className="data-table" id="proposals-table">
            <thead>
              <tr>
                <th>Status</th>
                <th>Customer</th>
                <th>System Size</th>
                <th>Panels</th>
                <th>Inverter</th>
                <th>Est. Cost</th>
                <th>Grid Compliance</th>
                <th>Risk</th>
                <th>Created</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {displayed.map(p => (
                <tr key={p.id}>
                  <td>
                    <span className={`status-badge ${STATUS_COLORS[p.proposalStatus] || ''}`}>
                      {STATUS_LABELS[p.proposalStatus] ?? p.proposalStatus}
                    </span>
                  </td>
                  <td>{p.solarSurveyId.slice(0, 8)}…</td>
                  <td>{p.recommendedKw.toFixed(2)} kW</td>
                  <td>{p.panelCount}</td>
                  <td>{p.inverterSizeKw.toFixed(2)} kW</td>
                  <td>{fmtLkr(p.estimatedCostLkr)}</td>
                  <td>
                    <span className={`badge ${p.gridComplianceStatus === 'COMPLIANT' ? 'badge--green' : 'badge--red'}`}>
                      {p.gridComplianceStatus}
                    </span>
                  </td>
                  <td>
                    <span className={`badge ${p.riskLevel === 'LOW' ? 'badge--green' : p.riskLevel === 'MEDIUM' ? 'badge--yellow' : 'badge--red'}`}>
                      {p.riskLevel}
                    </span>
                  </td>
                  <td>{new Date(p.createdAt).toLocaleDateString()}</td>
                  <td>
                    <Link to={`/proposals/${p.id}`} className="btn btn-sm btn-primary" id={`view-proposal-${p.id}`}>
                      View →
                    </Link>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
};
