import React, { useEffect, useState } from 'react';
import { api } from '../services/api';
import { Survey } from '../types/auth';

export const SurveysPage: React.FC = () => {
  const [surveys, setSurveys] = useState<Survey[]>([]);
  const [selected, setSelected] = useState<Survey | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => { api.getSurveys().then(setSurveys).catch(e => setError(e.message)).finally(() => setLoading(false)); }, []);

  if (loading) return <div className="glass-panel" style={{ padding: 28 }}>Loading customer surveys...</div>;
  if (error) return <div className="glass-panel" style={{ padding: 28, color: 'var(--solar-danger)' }}>{error}</div>;
  return <div style={{ display: 'grid', gap: 20 }}>
    <div><h1>Customer Surveys</h1><p style={{ color: 'var(--text-secondary)' }}>Inspect submitted survey data and deterministic sizing results.</p></div>
    {surveys.length === 0 ? <div className="glass-panel" style={{ padding: 28 }}>No surveys have been submitted.</div> : <div style={{ display: 'grid', gap: 10 }}>
      {surveys.map(survey => <button key={survey.id} onClick={() => setSelected(survey)} className="glass-panel" style={{ padding: 18, textAlign: 'left', color: 'inherit', cursor: 'pointer' }}>
        <strong>{survey.propertyAddress}</strong><div style={{ color: 'var(--text-secondary)', marginTop: 6 }}>{survey.monthlyKwh} kWh/month · {survey.roofAreaSqm} m² roof · <span className="badge badge-emerald">{survey.surveyStatus}</span></div>
      </button>)}
    </div>}
    {selected && <div className="glass-panel" style={{ padding: 24 }}><h2>Survey Details</h2><p>Grid: {selected.gridType} · Orientation: {selected.roofOrientation}</p>{selected.workflows.map(workflow => <div key={workflow.workflowId} style={{ marginTop: 16 }}><strong>Workflow: {workflow.status}</strong><pre style={{ whiteSpace: 'pre-wrap', marginTop: 8 }}>{workflow.resultJson || workflow.errorMessage || 'No result recorded.'}</pre><pre style={{ whiteSpace: 'pre-wrap' }}>{workflow.validationJson}</pre></div>)}</div>}
  </div>;
};