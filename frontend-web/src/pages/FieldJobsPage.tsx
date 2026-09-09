import React, { useEffect, useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { api } from '../services/api';
import { FieldJob } from '../types/auth';
import {
  CheckCircle2,
  XCircle,
  Clock,
  AlertTriangle,
  RefreshCw,
  MapPin,
  ShieldCheck,
  User as UserIcon,
  Zap,
  ArrowRight
} from '../components/Icons';

export const FieldJobsPage: React.FC = () => {
  const navigate = useNavigate();
  const [jobs, setJobs] = useState<FieldJob[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [searchQuery, setSearchQuery] = useState('');
  const [isRefreshing, setIsRefreshing] = useState(false);

  const fetchJobs = useCallback(async (isSilent = false) => {
    if (!isSilent) setIsRefreshing(true);
    try {
      const data = await api.getFieldJobs(statusFilter === 'ALL' ? undefined : statusFilter);
      setJobs(data);
      setError(null);
    } catch (err: any) {
      if (!isSilent) setError(err.message || 'Failed to load field jobs.');
    } finally {
      setLoading(false);
      setIsRefreshing(false);
    }
  }, [statusFilter]);

  useEffect(() => {
    fetchJobs();
  }, [fetchJobs]);

  const getStatusBadge = (status: string) => {
    const s = status?.toUpperCase() || 'ASSIGNED';
    switch (s) {
      case 'COMPLIANCECOMPLETE':
      case 'COMPLIANCE_COMPLETE':
        return <span className="badge badge-emerald"><CheckCircle2 size={12} /> Compliance Complete</span>;
      case 'COMPLIANCEPROCESSING':
      case 'COMPLIANCE_PROCESSING':
        return <span className="badge badge-amber"><Clock size={12} /> Compliance Checking</span>;
      case 'SUBMITTED':
        return <span className="badge badge-cyan"><CheckCircle2 size={12} /> Inspection Submitted</span>;
      case 'INPROGRESS':
      case 'IN_PROGRESS':
        return <span className="badge badge-amber"><Clock size={12} /> In Progress (On Site)</span>;
      case 'ACCEPTED':
        return <span className="badge" style={{ background: 'rgba(59, 130, 246, 0.15)', color: '#60a5fa' }}>Accepted</span>;
      case 'FAILED':
        return <span className="badge badge-danger"><XCircle size={12} /> Non-Compliant / Failed</span>;
      default:
        return <span className="badge" style={{ background: 'rgba(255,255,255,0.08)', color: 'var(--text-secondary)' }}>Assigned</span>;
    }
  };

  const filteredJobs = jobs.filter(j => {
    if (!searchQuery) return true;
    const q = searchQuery.toLowerCase();
    return (
      j.customerName.toLowerCase().includes(q) ||
      j.propertyAddress.toLowerCase().includes(q) ||
      j.technicianName.toLowerCase().includes(q) ||
      j.status.toLowerCase().includes(q)
    );
  });

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
      {/* Header */}
      <div className="glass-panel" style={{ padding: '24px 28px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h1 style={{ fontSize: '1.6rem', marginBottom: '4px' }}>Field Technician Operations & Compliance</h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.88rem' }}>
            Technician Site Dispatches &bull; GPS Check-in &bull; Electrical Telemetry &bull; Grid Compliance Engine
          </p>
        </div>
        <button onClick={() => fetchJobs()} disabled={isRefreshing} className="btn btn-secondary" style={{ padding: '8px 16px' }}>
          <RefreshCw size={14} className={isRefreshing ? 'spin' : ''} />
          {isRefreshing ? 'Refreshing...' : 'Refresh Jobs'}
        </button>
      </div>

      {/* Filters and Search */}
      <div className="glass-panel" style={{ padding: '16px 20px', display: 'flex', gap: '16px', flexWrap: 'wrap', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
          {['ALL', 'Assigned', 'InProgress', 'Submitted', 'ComplianceComplete', 'Failed'].map(status => (
            <button
              key={status}
              onClick={() => setStatusFilter(status)}
              className={statusFilter === status ? 'btn btn-primary' : 'btn btn-secondary'}
              style={{ padding: '6px 14px', fontSize: '0.8rem' }}
            >
              {status === 'ALL' ? 'All Jobs' : status}
            </button>
          ))}
        </div>

        <input
          type="text"
          placeholder="Search by customer, address, technician..."
          value={searchQuery}
          onChange={e => setSearchQuery(e.target.value)}
          style={{
            background: 'rgba(255,255,255,0.05)',
            border: '1px solid var(--border-color)',
            borderRadius: 'var(--radius-sm)',
            padding: '8px 14px',
            color: '#fff',
            fontSize: '0.85rem',
            minWidth: '280px'
          }}
        />
      </div>

      {/* Main List */}
      {loading ? (
        <div className="glass-panel" style={{ padding: '40px', textAlign: 'center' }}>
          <RefreshCw size={24} className="spin" style={{ marginBottom: '12px', color: 'var(--solar-emerald)' }} />
          <div>Loading field technician jobs...</div>
        </div>
      ) : error ? (
        <div className="glass-panel" style={{ padding: '32px', color: 'var(--solar-danger)', textAlign: 'center' }}>
          <AlertTriangle size={28} style={{ marginBottom: '12px' }} />
          <div style={{ fontWeight: 600, fontSize: '1.1rem' }}>Failed to Load Jobs</div>
          <p style={{ marginTop: '8px', color: 'var(--text-secondary)' }}>{error}</p>
        </div>
      ) : filteredJobs.length === 0 ? (
        <div className="glass-panel" style={{ padding: '40px', textAlign: 'center', color: 'var(--text-secondary)' }}>
          <Zap size={32} style={{ marginBottom: '12px', opacity: 0.5 }} />
          <div>No field jobs found matching the selected filter.</div>
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(360px, 1fr))', gap: '20px' }}>
          {filteredJobs.map(job => (
            <div
              key={job.id}
              className="glass-panel"
              style={{
                padding: '20px',
                display: 'flex',
                flexDirection: 'column',
                justifyContent: 'space-between',
                transition: 'transform 0.2s ease, border-color 0.2s ease',
                cursor: 'pointer'
              }}
              onClick={() => navigate(`/field-jobs/${job.id}`)}
            >
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '12px' }}>
                  <div style={{ fontWeight: 700, fontSize: '1.05rem', color: '#fff' }}>
                    {job.customerName}
                  </div>
                  {getStatusBadge(job.status)}
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '0.82rem', color: 'var(--text-secondary)', marginBottom: '10px' }}>
                  <MapPin size={14} color="var(--solar-cyan)" />
                  <span style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{job.propertyAddress}</span>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', margin: '14px 0', background: 'rgba(255,255,255,0.02)', padding: '10px 12px', borderRadius: 'var(--radius-sm)' }}>
                  <div>
                    <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>Assigned Technician</div>
                    <div style={{ fontSize: '0.85rem', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '4px', marginTop: '2px' }}>
                      <UserIcon size={12} color="var(--solar-emerald)" /> {job.technicianName}
                    </div>
                  </div>
                  <div>
                    <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>Priority & System Size</div>
                    <div style={{ fontSize: '0.85rem', fontWeight: 600, color: 'var(--solar-amber)', marginTop: '2px' }}>
                      {job.priority} &bull; {job.monthlyKwh} kWh
                    </div>
                  </div>
                </div>

                {job.compliance && (
                  <div style={{
                    padding: '8px 12px',
                    borderRadius: 'var(--radius-sm)',
                    background: job.compliance.gridCompliant ? 'rgba(16, 185, 129, 0.1)' : 'rgba(239, 68, 68, 0.1)',
                    border: `1px solid ${job.compliance.gridCompliant ? 'rgba(16, 185, 129, 0.3)' : 'rgba(239, 68, 68, 0.3)'}`,
                    fontSize: '0.78rem',
                    marginBottom: '10px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between'
                  }}>
                    <span style={{ display: 'flex', alignItems: 'center', gap: '6px', fontWeight: 600, color: job.compliance.gridCompliant ? 'var(--solar-emerald)' : '#f87171' }}>
                      <ShieldCheck size={14} /> {job.compliance.complianceStatus}
                    </span>
                    <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>Risk: {job.compliance.riskLevel}</span>
                  </div>
                )}
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '12px', borderTop: '1px solid var(--border-color)', paddingTop: '10px' }}>
                <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>
                  Assigned: {new Date(job.assignedAt).toLocaleDateString()}
                </span>
                <span style={{ fontSize: '0.8rem', fontWeight: 600, color: 'var(--solar-emerald)', display: 'flex', alignItems: 'center', gap: '4px' }}>
                  View Inspection <ArrowRight size={14} />
                </span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
