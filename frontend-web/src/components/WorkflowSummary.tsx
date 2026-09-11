import { useEffect, useState } from 'react';

export function WorkflowSummary({ surveyId }: { surveyId: string }) {
  const [data, setData] = useState<{ workflowId: string; objective: string; status: string; approvalStatus: string; finalOutcome: string; plan?: string[]; completedSteps: string[]; errors: string[] } | null>(null);
  const [error, setError] = useState('');
  useEffect(() => {
    let cancelled = false;
    fetch(`${import.meta.env.VITE_API_BASE_URL || 'http://localhost:5116'}/api/workflows/surveys/${surveyId}`, { headers: { Authorization: `Bearer ${localStorage.getItem('smartsolar_token')}` } })
      .then(async response => { if (!response.ok) throw new Error('Workflow history unavailable.'); return response.json(); })
      .then(result => { if (!cancelled) setData(result); }).catch(e => { if (!cancelled) setError(e.message); });
    return () => { cancelled = true; };
  }, [surveyId]);
  return <section className="glass-panel" style={{ padding: 24 }}><h2>Installation workflow</h2>{error ? <p role="alert">{error}</p> : !data ? <p>Loading workflow…</p> : <>
    <p>{data.objective}</p><p>Status: <strong>{data.status}</strong> · Approval: {data.approvalStatus}</p>
    <details><summary>Plan and delegated responsibilities</summary>{data.plan?.length ? <ol>{data.plan.map((step, i) => <li key={i}>{step}</li>)}</ol> : <p>This older survey has no saved plan. New survey submissions persist the plan.</p>}</details>
    <p>Completed: {data.completedSteps.join(' → ') || 'No completed stages yet'}</p><p>{data.finalOutcome}</p>{data.errors.map((error, i) => <p role="alert" key={i}>{error}</p>)}
    <small>Workflow reference: {data.workflowId}</small>
  </>}</section>;
}
