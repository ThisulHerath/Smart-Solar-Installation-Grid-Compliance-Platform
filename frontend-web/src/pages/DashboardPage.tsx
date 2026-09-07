import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { api } from '../services/api';
import { HealthResponse, WorkflowResult } from '../types/auth';
import { 
  Activity, 
  Database, 
  Cpu, 
  ShieldAlert, 
  CheckCircle2, 
  RefreshCw, 
  Sparkles, 
  Terminal,
  Layers,
  Lock
} from '../components/Icons';

export const DashboardPage: React.FC = () => {
  const { user, hasRole } = useAuth();

  const [health, setHealth] = useState<HealthResponse | null>(null);
  const [healthLoading, setHealthLoading] = useState(false);
  const [healthError, setHealthError] = useState<string | null>(null);

  const [aiObjective, setAiObjective] = useState('Design 10kW residential solar array with CEB grid export and net metering validation');
  const [aiResult, setAiResult] = useState<WorkflowResult | null>(null);
  const [aiLoading, setAiLoading] = useState(false);
  const [aiError, setAiError] = useState<string | null>(null);

  const [adminTestResult, setAdminTestResult] = useState<any>(null);
  const [adminTestError, setAdminTestError] = useState<string | null>(null);
  const [adminLoading, setAdminLoading] = useState(false);

  const [engineerTestResult, setEngineerTestResult] = useState<any>(null);
  const [engineerTestError, setEngineerTestError] = useState<string | null>(null);
  const [engineerLoading, setEngineerLoading] = useState(false);

  const fetchHealth = async () => {
    setHealthLoading(true);
    setHealthError(null);
    try {
      const data = await api.getHealth();
      setHealth(data);
    } catch (err: any) {
      setHealthError(err.message || 'Health probe failed');
    } finally {
      setHealthLoading(false);
    }
  };

  useEffect(() => {
    fetchHealth();
  }, []);

  const handleRunAiWorkflow = async () => {
    if (!aiObjective) return;
    setAiLoading(true);
    setAiError(null);
    try {
      const result = await api.triggerAiWorkflow(aiObjective);
      setAiResult(result);
    } catch (err: any) {
      setAiError(err.message || 'AI workflow execution failed');
    } finally {
      setAiLoading(false);
    }
  };

  const handleTestAdmin = async () => {
    setAdminLoading(true);
    setAdminTestResult(null);
    setAdminTestError(null);
    try {
      const res = await api.testAdminEndpoint();
      setAdminTestResult(res);
    } catch (err: any) {
      setAdminTestError(err.message);
    } finally {
      setAdminLoading(false);
    }
  };

  const handleTestEngineer = async () => {
    setEngineerLoading(true);
    setEngineerTestResult(null);
    setEngineerTestError(null);
    try {
      const res = await api.testEngineerEndpoint();
      setEngineerTestResult(res);
    } catch (err: any) {
      setEngineerTestError(err.message);
    } finally {
      setEngineerLoading(false);
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '28px' }}>
      {/* Welcome Banner */}
      <div className="glass-panel glass-panel-glow" style={{ padding: '28px 32px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '16px' }}>
          <div>
            <div className="badge badge-emerald" style={{ marginBottom: '8px' }}>
              Phase 1 Architectural Foundation
            </div>
            <h1 style={{ fontSize: '1.75rem', marginBottom: '4px' }}>
              Welcome, <span className="gradient-text">{user?.fullName}</span>
            </h1>
            <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
              Authoritative ASP.NET Core API &bull; Neon Managed PostgreSQL &bull; Python FastAPI LangGraph &bull; React Web
            </p>
          </div>

          <button onClick={fetchHealth} disabled={healthLoading} className="btn btn-secondary">
            <RefreshCw size={15} />
            {healthLoading ? 'Checking Services...' : 'Refresh Health Status'}
          </button>
        </div>
      </div>

      {/* Grid: System Health & Role Verification */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(340px, 1fr))', gap: '24px' }}>
        
        {/* Card 1: Live Dependency Status */}
        <div className="glass-panel" style={{ padding: '24px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '18px' }}>
            <Activity size={20} color="var(--solar-emerald)" />
            <h3 style={{ fontSize: '1.1rem' }}>Live Dependency Health</h3>
          </div>

          {healthError ? (
            <div style={{ color: 'var(--solar-danger)', fontSize: '0.875rem' }}>
              ASP.NET Core API is currently unreachable: {healthError}
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 14px', background: 'rgba(255, 255, 255, 0.03)', borderRadius: 'var(--radius-md)' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                  <Database size={18} color="var(--solar-cyan)" />
                  <div>
                    <div style={{ fontSize: '0.85rem', fontWeight: 600 }}>Neon PostgreSQL</div>
                    <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>Managed Cloud Database</div>
                  </div>
                </div>
                <span className={`badge ${health?.database === 'connected' ? 'badge-emerald' : 'badge-amber'}`}>
                  {health?.database || 'Probing...'}
                </span>
              </div>

              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 14px', background: 'rgba(255, 255, 255, 0.03)', borderRadius: 'var(--radius-md)' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                  <Cpu size={18} color="var(--solar-amber)" />
                  <div>
                    <div style={{ fontSize: '0.85rem', fontWeight: 600 }}>Python Agentic AI</div>
                    <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>FastAPI + LangGraph</div>
                  </div>
                </div>
                <span className={`badge ${health?.agenticAi === 'available' ? 'badge-emerald' : 'badge-amber'}`}>
                  {health?.agenticAi || 'Probing...'}
                </span>
              </div>

              <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', borderTop: '1px solid var(--border-color)', paddingTop: '10px' }}>
                Overall Platform Health: <strong style={{ color: 'var(--solar-emerald)' }}>{health?.status?.toUpperCase() || 'CHECKING'}</strong>
              </div>
            </div>
          )}
        </div>

        {/* Card 2: Role Authorization Verification */}
        <div className="glass-panel" style={{ padding: '24px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '18px' }}>
            <Lock size={20} color="var(--solar-amber)" />
            <h3 style={{ fontSize: '1.1rem' }}>Role-Based Access Verification</h3>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            {/* Admin test */}
            <div style={{ border: '1px solid var(--border-color)', padding: '12px', borderRadius: 'var(--radius-md)' }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
                <span style={{ fontSize: '0.85rem', fontWeight: 600 }}>GET /api/admin/test</span>
                <span className={`badge ${hasRole('ADMINISTRATOR') ? 'badge-emerald' : 'badge-danger'}`}>
                  {hasRole('ADMINISTRATOR') ? 'Authorized' : 'Requires ADMIN'}
                </span>
              </div>
              <button 
                onClick={handleTestAdmin} 
                disabled={adminLoading} 
                className="btn btn-secondary" 
                style={{ width: '100%', fontSize: '0.75rem', padding: '6px' }}
              >
                {adminLoading ? 'Verifying...' : 'Test Administrator Access'}
              </button>
              {adminTestResult && (
                <div style={{ color: 'var(--solar-emerald)', fontSize: '0.75rem', marginTop: '6px' }}>
                  ✓ {adminTestResult.message}
                </div>
              )}
              {adminTestError && (
                <div style={{ color: 'var(--solar-danger)', fontSize: '0.75rem', marginTop: '6px' }}>
                  ✗ {adminTestError}
                </div>
              )}
            </div>

            {/* Engineer test */}
            <div style={{ border: '1px solid var(--border-color)', padding: '12px', borderRadius: 'var(--radius-md)' }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
                <span style={{ fontSize: '0.85rem', fontWeight: 600 }}>GET /api/engineer/test</span>
                <span className={`badge ${hasRole('SENIOR_ENGINEER') ? 'badge-emerald' : 'badge-danger'}`}>
                  {hasRole('SENIOR_ENGINEER') ? 'Authorized' : 'Requires ENGINEER'}
                </span>
              </div>
              <button 
                onClick={handleTestEngineer} 
                disabled={engineerLoading} 
                className="btn btn-secondary" 
                style={{ width: '100%', fontSize: '0.75rem', padding: '6px' }}
              >
                {engineerLoading ? 'Verifying...' : 'Test Senior Engineer Access'}
              </button>
              {engineerTestResult && (
                <div style={{ color: 'var(--solar-emerald)', fontSize: '0.75rem', marginTop: '6px' }}>
                  ✓ {engineerTestResult.message}
                </div>
              )}
              {engineerTestError && (
                <div style={{ color: 'var(--solar-danger)', fontSize: '0.75rem', marginTop: '6px' }}>
                  ✗ {engineerTestError}
                </div>
              )}
            </div>
          </div>
        </div>

      </div>

      {/* Section: Agentic AI Workflow Execution Test */}
      <div className="glass-panel" style={{ padding: '28px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '16px' }}>
          <Sparkles size={22} color="var(--solar-emerald)" />
          <div>
            <h3 style={{ fontSize: '1.2rem' }}>ASP.NET Core &rarr; Agentic AI Orchestration</h3>
            <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)' }}>
              Sends objective from React to ASP.NET Core, which internally executes the LangGraph multi-agent workflow
            </p>
          </div>
        </div>

        <div style={{ display: 'flex', gap: '12px', marginBottom: '20px' }}>
          <input
            type="text"
            className="input-field"
            value={aiObjective}
            onChange={(e) => setAiObjective(e.target.value)}
            placeholder="Enter solar assessment objective..."
          />
          <button
            onClick={handleRunAiWorkflow}
            disabled={aiLoading || !aiObjective}
            className="btn btn-primary"
            style={{ whiteSpace: 'nowrap', padding: '0 24px' }}
          >
            {aiLoading ? 'Executing Graph...' : 'Run AI Workflow'}
          </button>
        </div>

        {aiError && (
          <div style={{
            background: 'rgba(239, 68, 68, 0.1)',
            border: '1px solid rgba(239, 68, 68, 0.3)',
            borderRadius: 'var(--radius-md)',
            padding: '12px 16px',
            color: '#f87171',
            fontSize: '0.85rem',
            marginBottom: '16px'
          }}>
            <ShieldAlert size={16} style={{ display: 'inline', marginRight: '6px' }} />
            {aiError}
          </div>
        )}

        {aiResult && (
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '16px' }}>
            {/* Plan & Steps */}
            <div style={{ background: 'rgba(10, 13, 20, 0.7)', padding: '16px', borderRadius: 'var(--radius-md)', border: '1px solid var(--border-color)' }}>
              <div style={{ fontSize: '0.85rem', fontWeight: 700, marginBottom: '10px', display: 'flex', alignItems: 'center', gap: '6px' }}>
                <Layers size={16} color="var(--solar-emerald)" /> Multi-Agent Plan & Steps
              </div>
              <ul style={{ listStyle: 'none', padding: 0, fontSize: '0.8rem', display: 'flex', flexDirection: 'column', gap: '6px' }}>
                {aiResult.plan.map((step, idx) => (
                  <li key={idx} style={{ display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--text-secondary)' }}>
                    <CheckCircle2 size={14} color="var(--solar-emerald)" />
                    {step}
                  </li>
                ))}
              </ul>
              <div style={{ marginTop: '12px', fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                Approval Status: <strong style={{ color: 'var(--solar-amber)' }}>{aiResult.approval_status}</strong>
              </div>
            </div>

            {/* Live Execution Logs */}
            <div style={{ background: 'rgba(10, 13, 20, 0.7)', padding: '16px', borderRadius: 'var(--radius-md)', border: '1px solid var(--border-color)', fontFamily: 'var(--font-mono)' }}>
              <div style={{ fontSize: '0.85rem', fontWeight: 700, marginBottom: '10px', display: 'flex', alignItems: 'center', gap: '6px', fontFamily: 'var(--font-sans)' }}>
                <Terminal size={16} color="var(--solar-cyan)" /> LangGraph Execution Trace
              </div>
              <div style={{ fontSize: '0.75rem', color: '#38bdf8', display: 'flex', flexDirection: 'column', gap: '4px', maxHeight: '180px', overflowY: 'auto' }}>
                {aiResult.execution_logs.map((log, idx) => (
                  <div key={idx}>&gt; {log}</div>
                ))}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
