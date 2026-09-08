import React, { useEffect, useState, useCallback } from 'react';
import { api } from '../services/api';
import { Survey } from '../types/auth';
import { 
  CheckCircle2, 
  XCircle, 
  Clock, 
  AlertTriangle, 
  Layers, 
  FileText, 
  Cpu, 
  RefreshCw,
  Sun,
  ShieldCheck,
  Image as ImageIcon
} from '../components/Icons';

interface SizingResult {
  recommended_kw?: number;
  estimated_panel_count?: number;
  estimated_inverter_kw?: number;
  reason?: string;
  assumptions?: string[];
}

interface ValidationData {
  valid?: boolean;
  checks?: Record<string, boolean>;
}

export const SurveysPage: React.FC = () => {
  const [surveys, setSurveys] = useState<Survey[]>([]);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isRefreshing, setIsRefreshing] = useState(false);

  const fetchSurveys = useCallback(async (isSilent = false) => {
    if (!isSilent) setIsRefreshing(true);
    try {
      const data = await api.getSurveys();
      setSurveys(data);
      if (data.length > 0 && !selectedId) {
        setSelectedId(data[0].id);
      }
      setError(null);
    } catch (err: any) {
      if (!isSilent) {
        setError(err.message || 'Failed to load customer surveys');
      }
    } finally {
      setLoading(false);
      setIsRefreshing(false);
    }
  }, [selectedId]);

  useEffect(() => {
    fetchSurveys();
  }, []);

  // Polling loop for active processing surveys
  useEffect(() => {
    const hasProcessing = surveys.some(
      (s) => s.surveyStatus?.toUpperCase() === 'PROCESSING' || s.surveyStatus?.toUpperCase() === 'SUBMITTED'
    );

    if (!hasProcessing) return;

    const interval = setInterval(() => {
      fetchSurveys(true);
    }, 3000);

    return () => clearInterval(interval);
  }, [surveys, fetchSurveys]);

  const selectedSurvey = surveys.find((s) => s.id === selectedId) || surveys[0];

  const getStatusBadge = (status: string) => {
    const s = status?.toUpperCase() || 'DRAFT';
    switch (s) {
      case 'ANALYSISCOMPLETE':
      case 'ANALYSIS_COMPLETE':
      case 'COMPLETED':
        return <span className="badge badge-emerald"><CheckCircle2 size={12} /> Analysis Complete</span>;
      case 'PROCESSING':
      case 'SUBMITTED':
        return <span className="badge badge-amber"><Clock size={12} /> Processing AI Workflow</span>;
      case 'FAILED':
        return <span className="badge badge-danger"><XCircle size={12} /> Workflow Failed</span>;
      default:
        return <span className="badge" style={{ background: 'rgba(255,255,255,0.1)', color: 'var(--text-secondary)' }}>Draft</span>;
    }
  };

  const parseResultJson = (raw?: string): SizingResult | null => {
    if (!raw) return null;
    try {
      return JSON.parse(raw);
    } catch {
      return null;
    }
  };

  const parseValidationJson = (raw?: string): ValidationData | null => {
    if (!raw) return null;
    try {
      return JSON.parse(raw);
    } catch {
      return null;
    }
  };

  if (loading) {
    return (
      <div className="glass-panel" style={{ padding: '40px', textAlign: 'center' }}>
        <RefreshCw size={24} className="spin" style={{ marginBottom: '12px', color: 'var(--solar-emerald)' }} />
        <div>Loading customer solar surveys...</div>
      </div>
    );
  }

  if (error && surveys.length === 0) {
    return (
      <div className="glass-panel" style={{ padding: '32px', color: 'var(--solar-danger)', textAlign: 'center' }}>
        <AlertTriangle size={28} style={{ marginBottom: '12px' }} />
        <div style={{ fontWeight: 600, fontSize: '1.1rem' }}>Survey Load Error</div>
        <p style={{ marginTop: '8px', color: 'var(--text-secondary)' }}>{error}</p>
        <button onClick={() => fetchSurveys()} className="btn btn-secondary" style={{ marginTop: '16px' }}>
          Retry Loading
        </button>
      </div>
    );
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
      {/* Header */}
      <div className="glass-panel" style={{ padding: '24px 28px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h1 style={{ fontSize: '1.6rem', marginBottom: '4px' }}>Staff Solar Survey Dashboard</h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.88rem' }}>
            Authorized Staff Review &bull; Deterministic Validation &bull; LangGraph Sizing Execution
          </p>
        </div>
        <button onClick={() => fetchSurveys()} disabled={isRefreshing} className="btn btn-secondary" style={{ padding: '8px 16px' }}>
          <RefreshCw size={14} className={isRefreshing ? 'spin' : ''} />
          {isRefreshing ? 'Refreshing...' : 'Refresh List'}
        </button>
      </div>

      {surveys.length === 0 ? (
        <div className="glass-panel" style={{ padding: '40px', textAlign: 'center', color: 'var(--text-secondary)' }}>
          <FileText size={32} style={{ marginBottom: '12px', opacity: 0.5 }} />
          <div>No customer surveys found. Submit a survey from the mobile app to get started.</div>
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: '320px 1fr', gap: '24px' }}>
          {/* Survey List */}
          <div className="glass-panel" style={{ padding: '16px', display: 'flex', flexDirection: 'column', gap: '10px', maxHeight: 'calc(100vh - 200px)', overflowY: 'auto' }}>
            <div style={{ fontSize: '0.85rem', fontWeight: 700, padding: '4px 8px', color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              Submitted Surveys ({surveys.length})
            </div>
            {surveys.map((s) => {
              const isSelected = s.id === selectedSurvey?.id;
              return (
                <div
                  key={s.id}
                  onClick={() => setSelectedId(s.id)}
                  style={{
                    padding: '14px',
                    borderRadius: 'var(--radius-md)',
                    background: isSelected ? 'rgba(16, 185, 129, 0.12)' : 'rgba(255, 255, 255, 0.03)',
                    border: `1px solid ${isSelected ? 'var(--solar-emerald)' : 'var(--border-color)'}`,
                    cursor: 'pointer',
                    transition: 'all 0.2s ease'
                  }}
                >
                  <div style={{ fontWeight: 600, fontSize: '0.92rem', marginBottom: '6px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                    {s.propertyAddress || 'Unnamed Property'}
                  </div>
                  <div style={{ fontSize: '0.78rem', color: 'var(--text-secondary)', marginBottom: '8px' }}>
                    {s.monthlyKwh} kWh/mo &bull; {s.roofAreaSqm} m² &bull; {s.gridType}
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    {getStatusBadge(s.surveyStatus)}
                    <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>
                      {new Date(s.createdAt).toLocaleDateString()}
                    </span>
                  </div>
                </div>
              );
            })}
          </div>

          {/* Survey Detail Panel */}
          {selectedSurvey && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
              {/* Card 1: Customer Input & Specifications */}
              <div className="glass-panel" style={{ padding: '24px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '16px' }}>
                  <div>
                    <h2 style={{ fontSize: '1.25rem', marginBottom: '4px' }}>{selectedSurvey.propertyAddress}</h2>
                    <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                      Survey ID: {selectedSurvey.id} &bull; Customer ID: {selectedSurvey.customerId}
                    </div>
                  </div>
                  {getStatusBadge(selectedSurvey.surveyStatus)}
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '16px', marginTop: '16px' }}>
                  <div style={{ background: 'rgba(255, 255, 255, 0.03)', padding: '12px 16px', borderRadius: 'var(--radius-md)' }}>
                    <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Monthly Consumption</div>
                    <div style={{ fontSize: '1.1rem', fontWeight: 700, color: 'var(--solar-amber)', marginTop: '4px' }}>
                      {selectedSurvey.monthlyKwh} <span style={{ fontSize: '0.8rem', fontWeight: 400 }}>kWh</span>
                    </div>
                  </div>

                  <div style={{ background: 'rgba(255, 255, 255, 0.03)', padding: '12px 16px', borderRadius: 'var(--radius-md)' }}>
                    <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Roof Surface Area</div>
                    <div style={{ fontSize: '1.1rem', fontWeight: 700, color: 'var(--solar-cyan)', marginTop: '4px' }}>
                      {selectedSurvey.roofAreaSqm} <span style={{ fontSize: '0.8rem', fontWeight: 400 }}>m²</span>
                    </div>
                  </div>

                  <div style={{ background: 'rgba(255, 255, 255, 0.03)', padding: '12px 16px', borderRadius: 'var(--radius-md)' }}>
                    <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Grid Phase Type</div>
                    <div style={{ fontSize: '1.1rem', fontWeight: 700, color: 'var(--solar-emerald)', marginTop: '4px' }}>
                      {selectedSurvey.gridType}
                    </div>
                  </div>

                  <div style={{ background: 'rgba(255, 255, 255, 0.03)', padding: '12px 16px', borderRadius: 'var(--radius-md)' }}>
                    <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Roof Orientation & Tilt</div>
                    <div style={{ fontSize: '1.1rem', fontWeight: 600, marginTop: '4px' }}>
                      {selectedSurvey.roofOrientation || 'Unknown'} {selectedSurvey.roofTilt ? `(${selectedSurvey.roofTilt}°)` : ''}
                    </div>
                  </div>
                </div>

                {/* Attached Site Images */}
                {selectedSurvey.images && selectedSurvey.images.length > 0 && (
                  <div style={{ marginTop: '20px', borderTop: '1px solid var(--border-color)', paddingTop: '16px' }}>
                    <div style={{ fontSize: '0.85rem', fontWeight: 600, marginBottom: '10px', display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <ImageIcon size={16} color="var(--solar-cyan)" /> Attached Site Photos ({selectedSurvey.images.length})
                    </div>
                    <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
                      {selectedSurvey.images.map((img) => (
                        <div key={img.id} style={{ background: 'rgba(0,0,0,0.3)', padding: '8px 12px', borderRadius: 'var(--radius-md)', border: '1px solid var(--border-color)', fontSize: '0.8rem' }}>
                          <span className="badge badge-emerald" style={{ marginRight: '8px' }}>{img.imageType}</span>
                          {img.fileName}
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>

              {/* Card 2: AI Workflows, Sizing Recommendation & Validation Results */}
              {selectedSurvey.workflows && selectedSurvey.workflows.length > 0 ? (
                selectedSurvey.workflows.map((wf, idx) => {
                  const sizing = parseResultJson(wf.resultJson);
                  const valData = parseValidationJson(wf.validationJson);
                  const isFailed = wf.status?.toLowerCase() === 'failed' || wf.errorMessage;

                  return (
                    <div key={wf.workflowId || idx} className="glass-panel" style={{ padding: '24px' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '18px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                          <Cpu size={20} color="var(--solar-emerald)" />
                          <h3 style={{ fontSize: '1.1rem' }}>LangGraph Multi-Agent Sizing Execution</h3>
                        </div>
                        <span className={`badge ${wf.status === 'Completed' ? 'badge-emerald' : wf.status === 'Failed' ? 'badge-danger' : 'badge-amber'}`}>
                          Status: {wf.status}
                        </span>
                      </div>

                      {/* Error Display (Safe failure message) */}
                      {isFailed && (
                        <div style={{ background: 'rgba(239, 68, 68, 0.1)', border: '1px solid rgba(239, 68, 68, 0.3)', padding: '14px 18px', borderRadius: 'var(--radius-md)', color: '#f87171', marginBottom: '20px', fontSize: '0.88rem' }}>
                          <div style={{ fontWeight: 700, marginBottom: '4px', display: 'flex', alignItems: 'center', gap: '6px' }}>
                            <AlertTriangle size={16} /> Workflow Execution Notice
                          </div>
                          <div>{wf.errorMessage || 'Solar sizing workflow encountered an error or failed validation checks. No fake recommendations were emitted.'}</div>
                        </div>
                      )}

                      {/* Sizing Recommendation Summary */}
                      {sizing && (
                        <div style={{ background: 'rgba(16, 185, 129, 0.05)', border: '1px solid rgba(16, 185, 129, 0.2)', padding: '20px', borderRadius: 'var(--radius-md)', marginBottom: '20px' }}>
                          <div style={{ fontSize: '0.9rem', fontWeight: 700, color: 'var(--solar-emerald)', marginBottom: '14px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                            <Sun size={18} /> Deterministic Solar Sizing Recommendation
                          </div>
                          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '16px' }}>
                            <div>
                              <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Recommended Array Capacity</div>
                              <div style={{ fontSize: '1.4rem', fontWeight: 800, color: '#ffffff', marginTop: '2px' }}>
                                {sizing.recommended_kw} <span style={{ fontSize: '0.9rem', fontWeight: 500 }}>kW</span>
                              </div>
                            </div>
                            <div>
                              <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Estimated Panel Count</div>
                              <div style={{ fontSize: '1.4rem', fontWeight: 800, color: '#ffffff', marginTop: '2px' }}>
                                {sizing.estimated_panel_count} <span style={{ fontSize: '0.9rem', fontWeight: 500 }}>panels (400W)</span>
                              </div>
                            </div>
                            <div>
                              <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Estimated Inverter Size</div>
                              <div style={{ fontSize: '1.4rem', fontWeight: 800, color: '#ffffff', marginTop: '2px' }}>
                                {sizing.estimated_inverter_kw} <span style={{ fontSize: '0.9rem', fontWeight: 500 }}>kW</span>
                              </div>
                            </div>
                          </div>
                          {sizing.reason && (
                            <div style={{ marginTop: '14px', fontSize: '0.82rem', color: 'var(--text-secondary)', borderTop: '1px solid rgba(255,255,255,0.06)', paddingTop: '10px' }}>
                              <strong>Sizing Rationale:</strong> {sizing.reason}
                            </div>
                          )}
                        </div>
                      )}

                      {/* Deterministic Validation Results */}
                      {valData && valData.checks && (
                        <div style={{ background: 'rgba(255, 255, 255, 0.02)', border: '1px solid var(--border-color)', padding: '18px', borderRadius: 'var(--radius-md)', marginBottom: '20px' }}>
                          <div style={{ fontSize: '0.88rem', fontWeight: 700, marginBottom: '12px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                            <span style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                              <ShieldCheck size={16} color="var(--solar-cyan)" /> Deterministic Validation Checks
                            </span>
                            <span className={`badge ${valData.valid ? 'badge-emerald' : 'badge-danger'}`}>
                              {valData.valid ? 'PASSED ALL CHECKS' : 'VALIDATION FAILED'}
                            </span>
                          </div>
                          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '10px' }}>
                            {Object.entries(valData.checks).map(([checkKey, isPassed]) => (
                              <div key={checkKey} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '8px 12px', background: 'rgba(0,0,0,0.2)', borderRadius: 'var(--radius-sm)', fontSize: '0.78rem' }}>
                                <span style={{ color: 'var(--text-secondary)' }}>{checkKey}</span>
                                {isPassed ? (
                                  <span style={{ color: 'var(--solar-emerald)', fontWeight: 600 }}>✓ Pass</span>
                                ) : (
                                  <span style={{ color: 'var(--solar-danger)', fontWeight: 600 }}>✗ Fail</span>
                                )}
                              </div>
                            ))}
                          </div>
                        </div>
                      )}

                      {/* Execution Steps Trace */}
                      <div style={{ background: 'rgba(10, 13, 20, 0.6)', padding: '16px', borderRadius: 'var(--radius-md)', border: '1px solid var(--border-color)' }}>
                        <div style={{ fontSize: '0.82rem', fontWeight: 700, marginBottom: '10px', display: 'flex', alignItems: 'center', gap: '6px' }}>
                          <Layers size={14} color="var(--solar-emerald)" /> Workflow Execution Pipeline
                        </div>
                        <div style={{ display: 'flex', gap: '16px', flexWrap: 'wrap', fontSize: '0.8rem' }}>
                          {['Planner', 'SolarSizingAgent', 'DeterministicValidator'].map((step, sIdx) => (
                            <div key={step} style={{ display: 'flex', alignItems: 'center', gap: '6px', color: 'var(--text-secondary)' }}>
                              <CheckCircle2 size={14} color="var(--solar-emerald)" />
                              <span>{sIdx + 1}. {step}</span>
                            </div>
                          ))}
                        </div>
                      </div>
                    </div>
                  );
                })
              ) : (
                <div className="glass-panel" style={{ padding: '24px', color: 'var(--text-secondary)' }}>
                  No agent workflows recorded for this survey yet.
                </div>
              )}
            </div>
          )}
        </div>
      )}
    </div>
  );
};
