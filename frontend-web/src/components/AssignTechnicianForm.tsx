import { ValidatedForm } from './ValidatedForm';
import { useEffect, useState } from 'react';
import { api } from '../services/api';
import { FieldJob, Survey } from '../types/auth';

export function AssignTechnicianForm({ onAssigned, onCancel }: {
  onAssigned: (job: FieldJob) => void; onCancel: () => void;
}) {
  const [surveys, setSurveys] = useState<Survey[]>([]);
  const [technicians, setTechnicians] = useState<{ id: string; fullName: string; email: string }[]>([]);
  const [surveyId, setSurveyId] = useState(''), [technicianId, setTechnicianId] = useState('');
  const [priority, setPriority] = useState('Medium'), [scheduledAt, setScheduledAt] = useState('');
  const [loading, setLoading] = useState(true), [saving, setSaving] = useState(false);
  const [error, setError] = useState(''), [attempt, setAttempt] = useState(0);
  useEffect(() => {
    let active = true;
    setLoading(true); setError('');
    Promise.all([api.getSurveys(), api.getTechnicians()]).then(([s, t]) => {
      if (active) { setSurveys(s); setTechnicians(t); }
    }).catch(e => { if (active) setError(e.message); })
      .finally(() => { if (active) setLoading(false); });
    return () => { active = false; };
  }, [attempt]);

  return <section className="glass-panel" aria-labelledby="assignment-heading" style={{ padding: 24 }}>
    <p className="eyebrow">PLAN A SITE VISIT</p>
    <h2 id="assignment-heading">Assign a technician</h2>
    <p style={{ color: 'var(--text-secondary)', marginBottom: 20 }}>Choose a customer survey and the technician who will inspect the site.</p>
    {error && <div role="alert" style={{ color: 'var(--solar-danger)', marginBottom: 12 }}>{error}</div>}
    {loading ? <p role="status">Loading surveys and technicians…</p> :
      <ValidatedForm onSubmit={async e => {
        e.preventDefault(); if (saving) return;
        setSaving(true); setError('');
        try {
          const job = await api.createFieldJob({ solarSurveyId: surveyId, technicianId, priority,
            ...(scheduledAt ? { scheduledAt: new Date(scheduledAt).toISOString() } : {}) });
          onAssigned(job);
        } catch (e) { setError((e as Error).message); }
        finally { setSaving(false); }
      }}>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(min(100%, 240px), 1fr))', gap: 16 }}>
          <label>Customer survey<select className="input-field" required value={surveyId} disabled={saving} onChange={e => setSurveyId(e.target.value)}>
            <option value="">Select a survey</option>
            {surveys.map(s => <option key={s.id} value={s.id}>{s.propertyAddress} · {s.monthlyKwh} kWh · {s.surveyStatus}</option>)}
          </select></label>
          <label>Technician<select className="input-field" required value={technicianId} disabled={saving} onChange={e => setTechnicianId(e.target.value)}>
            <option value="">Select a technician</option>
            {technicians.map(t => <option key={t.id} value={t.id}>{t.fullName} · {t.email}</option>)}
          </select></label>
          <label>Priority<select className="input-field" value={priority} disabled={saving} onChange={e => setPriority(e.target.value)}>
            {['Low', 'Medium', 'High', 'Urgent'].map(p => <option key={p}>{p}</option>)}
          </select></label>
          <label>Visit date and time (optional)<input className="input-field" type="datetime-local" value={scheduledAt} disabled={saving} onChange={e => setScheduledAt(e.target.value)} /></label>
        </div>
        {!surveys.length && <p>Create a customer survey before assigning a site visit.</p>}
        {!technicians.length && <p>No active field technicians are available.</p>}
        <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap', marginTop: 20 }}>
          <button className="btn btn-primary" type="submit" disabled={saving}>{saving ? 'Assigning…' : 'Assign site visit'}</button>
          <button className="btn btn-secondary" type="button" disabled={saving} onClick={onCancel}>Cancel</button>
          {error && <button className="btn btn-secondary" type="button" disabled={saving} onClick={() => setAttempt(x => x + 1)}>Reload options</button>}
        </div>
      </ValidatedForm>}
  </section>;
}
