import { useEffect, useState } from 'react';
import { CheckCircle2, ClipboardList, Clock3, ShieldCheck, TriangleAlert } from 'lucide-react';

import '../styles/proposal-detail-polish.css';

type WorkflowData = {
  workflowId: string;
  objective: string;
  status: string;
  approvalStatus: string;
  finalOutcome: string;
  plan?: string[];
  completedSteps: string[];
  errors: string[];
};

const labels: Record<string, string> = {
  SolarSizingAgent: 'Solar sizing',
  GridComplianceAgent: 'Grid compliance',
  SafetyGuardrailAgent: 'Safety review',
  HumanApproval: 'Engineering approval',
  EquipmentPricingAgent: 'Equipment pricing',
  InventoryReservation: 'Stock reservation',
};

function displayLabel(value: string) {
  return labels[value] ?? value.replace(/([a-z])([A-Z])/g, '$1 $2').replace(/_/g, ' ');
}

export function WorkflowSummary({ surveyId }: { surveyId: string }) {
  const [data, setData] = useState<WorkflowData | null>(null);
  const [error, setError] = useState('');

  useEffect(() => {
    let cancelled = false;
    fetch(`${import.meta.env.VITE_API_BASE_URL || 'http://localhost:5116'}/api/workflows/surveys/${surveyId}`, {
      headers: { Authorization: `Bearer ${localStorage.getItem('smartsolar_token')}` },
    })
      .then(async response => {
        if (!response.ok) throw new Error('Workflow history unavailable.');
        return response.json();
      })
      .then(result => { if (!cancelled) setData(result); })
      .catch(requestError => { if (!cancelled) setError(requestError.message); });
    return () => { cancelled = true; };
  }, [surveyId]);

  if (error) return <section className="workflow-summary workflow-summary--error" role="alert"><TriangleAlert size={18} /><span>{error}</span></section>;
  if (!data) return <section className="workflow-summary workflow-summary--loading"><Clock3 size={18} /><span>Loading workflow</span></section>;

  return (
    <section className="workflow-summary">
      <header className="workflow-summary__header">
        <span className="workflow-summary__icon"><ClipboardList size={20} /></span>
        <div>
          <p className="workflow-summary__eyebrow">Project workflow</p>
          <h2>Installation workflow</h2>
        </div>
        <div className="workflow-summary__statuses">
          <span className="workflow-status workflow-status--active">{displayLabel(data.status)}</span>
          <span className="workflow-status">{displayLabel(data.approvalStatus)}</span>
        </div>
      </header>

      <p className="workflow-summary__objective">{data.objective}</p>

      <div className="workflow-summary__body">
        <div className="workflow-summary__plan">
          <h3>Installation plan</h3>
          {data.plan?.length ? (
            <ol>{data.plan.map((step, index) => <li key={`${index}-${step}`}><span>{String(index + 1).padStart(2, '0')}</span><p>{step}</p></li>)}</ol>
          ) : <p className="workflow-summary__empty">A plan will appear once the assessment is completed.</p>}
        </div>

        <aside className="workflow-summary__progress">
          <h3>Progress</h3>
          {data.completedSteps.length ? (
            <ul>{data.completedSteps.map(step => <li key={step}><CheckCircle2 size={16} /><span>{displayLabel(step)}</span></li>)}</ul>
          ) : <p className="workflow-summary__empty">No stages completed yet.</p>}
          <div className="workflow-summary__outcome"><ShieldCheck size={17} /><span>{data.finalOutcome}</span></div>
        </aside>
      </div>

      {data.errors.length > 0 && <div className="workflow-summary__errors" role="alert">{data.errors.map(item => <p key={item}><TriangleAlert size={15} />{item}</p>)}</div>}
      <footer>Workflow reference <code>{data.workflowId}</code></footer>
    </section>
  );
}
