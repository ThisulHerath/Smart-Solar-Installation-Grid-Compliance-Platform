import React, { useEffect, useState, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { api } from '../services/api';
import { FieldJob } from '../types/auth';
import {
  ArrowLeft,
  CheckCircle2,
  XCircle,
  Clock,
  AlertTriangle,
  RefreshCw,
  ShieldCheck,
  User as UserIcon,
  Cpu
} from '../components/Icons';

export const FieldJobDetailPage: React.FC = () => {
  const { jobId } = useParams<{ jobId: string }>();
  const navigate = useNavigate();

  const [job, setJob] = useState<FieldJob | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [evaluating, setEvaluating] = useState(false);
  const [evaluationMsg, setEvaluationMsg] = useState<string | null>(null);

  const fetchJob = useCallback(async () => {
    if (!jobId) return;
    try {
      setLoading(true);
      const data = await api.getFieldJob(jobId);
      setJob(data);
      setError(null);
    } catch (err: any) {
      setError(err.message || 'Failed to load field job details.');
    } finally {
      setLoading(false);
    }
  }, [jobId]);

  useEffect(() => {
    fetchJob();
  }, [fetchJob]);

  const handleEvaluateCompliance = async () => {
    if (!jobId) return;
    try {
      setEvaluating(true);
      setEvaluationMsg(null);
      await api.evaluateJobCompliance(jobId);
      setEvaluationMsg('Compliance evaluation completed successfully.');
      await fetchJob();
    } catch (err: any) {
      setEvaluationMsg(`Evaluation failed: ${err.message}`);
    } finally {
      setEvaluating(false);
    }
  };

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

  if (loading) {
    return (
      <div className="glass-panel" style={{ padding: '40px', textAlign: 'center' }}>
        <RefreshCw size={24} className="spin" style={{ marginBottom: '12px', color: 'var(--solar-emerald)' }} />
        <div>Loading site inspection and compliance data...</div>
      </div>
    );
  }

  if (error || !job) {
    return (
      <div className="glass-panel" style={{ padding: '32px', color: 'var(--solar-danger)', textAlign: 'center' }}>
        <AlertTriangle size={28} style={{ marginBottom: '12px' }} />
        <div style={{ fontWeight: 600, fontSize: '1.1rem' }}>Job Details Error</div>
        <p style={{ marginTop: '8px', color: 'var(--text-secondary)' }}>{error || 'Field job not found.'}</p>
        <button onClick={() => navigate('/field-jobs')} className="btn btn-secondary" style={{ marginTop: '16px' }}>
          <ArrowLeft size={14} /> Back to Field Jobs
        </button>
      </div>
    );
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
      {/* Back button and Top Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button onClick={() => navigate('/field-jobs')} className="btn btn-secondary" style={{ padding: '8px 14px' }}>
          <ArrowLeft size={14} /> Back to Field Jobs
        </button>

        <div style={{ display: 'flex', gap: '12px', alignItems: 'center' }}>
          <button
            onClick={handleEvaluateCompliance}
            disabled={evaluating}
            className="btn btn-primary"
            style={{ padding: '8px 16px', display: 'flex', alignItems: 'center', gap: '6px' }}
          >
            <Cpu size={14} />
            {evaluating ? 'Evaluating Compliance...' : 'Trigger Compliance Evaluation'}
          </button>
        </div>
      </div>

      {evaluationMsg && (
        <div className="glass-panel" style={{
          padding: '12px 18px',
          color: evaluationMsg.includes('failed') ? 'var(--solar-danger)' : 'var(--solar-emerald)',
          background: evaluationMsg.includes('failed') ? 'rgba(239, 68, 68, 0.1)' : 'rgba(16, 185, 129, 0.1)',
          display: 'flex',
          alignItems: 'center',
          gap: '8px',
          fontSize: '0.88rem'
        }}>
          {evaluationMsg.includes('failed') ? <AlertTriangle size={16} /> : <CheckCircle2 size={16} />}
          {evaluationMsg}
        </div>
      )}

      {/* Main Job Overview Card */}
      <div className="glass-panel" style={{ padding: '24px 28px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '18px' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '6px' }}>
              <h1 style={{ fontSize: '1.4rem' }}>{job.propertyAddress}</h1>
              {getStatusBadge(job.status)}
            </div>
            <p style={{ color: 'var(--text-secondary)', fontSize: '0.85rem' }}>
              Job ID: {job.id} &bull; Survey ID: {job.solarSurveyId} &bull; Assigned: {new Date(job.assignedAt).toLocaleString()}
            </p>
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '16px' }}>
          <div style={{ background: 'rgba(255, 255, 255, 0.03)', padding: '14px 16px', borderRadius: 'var(--radius-md)' }}>
            <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Customer Details</div>
            <div style={{ fontSize: '1rem', fontWeight: 700, color: '#fff', marginTop: '4px' }}>
              {job.customerName}
            </div>
            <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', marginTop: '2px' }}>
              {job.customerPhone || 'No phone provided'}
            </div>
          </div>

          <div style={{ background: 'rgba(255, 255, 255, 0.03)', padding: '14px 16px', borderRadius: 'var(--radius-md)' }}>
            <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Assigned Field Technician</div>
            <div style={{ fontSize: '1rem', fontWeight: 700, color: 'var(--solar-emerald)', marginTop: '4px', display: 'flex', alignItems: 'center', gap: '6px' }}>
              <UserIcon size={16} /> {job.technicianName}
            </div>
            <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', marginTop: '2px' }}>
              Priority: {job.priority}
            </div>
          </div>

          <div style={{ background: 'rgba(255, 255, 255, 0.03)', padding: '14px 16px', borderRadius: 'var(--radius-md)' }}>
            <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>System Usage & Roof Area</div>
            <div style={{ fontSize: '1.1rem', fontWeight: 700, color: 'var(--solar-amber)', marginTop: '4px' }}>
              {job.monthlyKwh} <span style={{ fontSize: '0.8rem', fontWeight: 400 }}>kWh/mo</span>
            </div>
            <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', marginTop: '2px' }}>
              Roof Area: {job.roofAreaSqm} m²
            </div>
          </div>
        </div>
      </div>

      {/* Compliance Assessment Section */}
      {job.compliance ? (
        <div className="glass-panel" style={{ padding: '24px 28px', borderLeft: `4px solid ${job.compliance.gridCompliant ? 'var(--solar-emerald)' : '#ef4444'}` }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
              <ShieldCheck size={22} color={job.compliance.gridCompliant ? 'var(--solar-emerald)' : '#ef4444'} />
              <h2 style={{ fontSize: '1.25rem' }}>CEB / LECO Grid Compliance Assessment</h2>
            </div>
            <div style={{ display: 'flex', gap: '8px' }}>
              <span className={`badge ${job.compliance.gridCompliant ? 'badge-emerald' : 'badge-danger'}`}>
                {job.compliance.complianceStatus}
              </span>
              <span className="badge" style={{ background: 'rgba(255,255,255,0.08)' }}>
                Risk: {job.compliance.riskLevel}
              </span>
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '14px', marginBottom: '16px' }}>
            <div style={{ background: 'rgba(0,0,0,0.2)', padding: '12px 14px', borderRadius: 'var(--radius-sm)' }}>
              <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Workflow ID</div>
              <div style={{ fontSize: '0.88rem', fontWeight: 600, marginTop: '2px' }}>{job.compliance.workflowId || 'N/A'}</div>
            </div>
            <div style={{ background: 'rgba(0,0,0,0.2)', padding: '12px 14px', borderRadius: 'var(--radius-sm)' }}>
              <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Validation Status</div>
              <div style={{ fontSize: '0.88rem', fontWeight: 600, color: 'var(--solar-cyan)', marginTop: '2px' }}>
                {job.compliance.validationStatus || 'PASSED'}
              </div>
            </div>
            <div style={{ background: 'rgba(0,0,0,0.2)', padding: '12px 14px', borderRadius: 'var(--radius-sm)' }}>
              <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Evaluated Timestamp</div>
              <div style={{ fontSize: '0.88rem', marginTop: '2px' }}>{new Date(job.compliance.updatedAt).toLocaleString()}</div>
            </div>
          </div>

          {job.compliance.complianceNotes && (
            <div style={{ background: 'rgba(255,255,255,0.02)', padding: '14px 16px', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-color)' }}>
              <div style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase', marginBottom: '6px' }}>
                Compliance Engineering Findings & Directives
              </div>
              <p style={{ fontSize: '0.88rem', lineHeight: '1.5', color: '#e2e8f0', margin: 0 }}>
                {job.compliance.complianceNotes}
              </p>
            </div>
          )}
        </div>
      ) : (
        <div className="glass-panel" style={{ padding: '24px', textAlign: 'center', color: 'var(--text-secondary)' }}>
          <ShieldCheck size={28} style={{ marginBottom: '8px', opacity: 0.5 }} />
          <div>No compliance evaluation run yet. The technician must submit on-site telemetry or staff can trigger evaluation above.</div>
        </div>
      )}
    </div>
  );
};
