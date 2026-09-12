import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { Survey } from '../types/auth';
import { api } from '../services/api';
import '../styles/account.css';

async function request(path: string, body?: unknown) {
  const response = await fetch(`${import.meta.env.VITE_API_BASE_URL || 'http://localhost:5116'}/api/${path}`, {
    method: body === undefined ? 'GET' : 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${localStorage.getItem('smartsolar_token')}` },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(data.message || 'Unable to complete this request. Please try again.');
  return data;
}

export function HomeownerWorkspace() {
  const [surveys, setSurveys] = useState<Survey[]>([]), [loading, setLoading] = useState(true), [busy, setBusy] = useState(false), [error, setError] = useState('');
  const [showForm, setShowForm] = useState(false), [address, setAddress] = useState(''), [kwh, setKwh] = useState(''), [area, setArea] = useState(''), [grid, setGrid] = useState('SinglePhase');
  const [proposals, setProposals] = useState<Record<string, { id: string; proposalStatus: string }[]>>({});
  const load = async () => {
    const rows = await api.getSurveys(); setSurveys(rows);
    const entries = await Promise.all(rows.map(async row => [row.id, await request(`proposals/survey/${row.id}`)] as const));
    setProposals(Object.fromEntries(entries));
  };
  useEffect(() => { load().catch(e => setError(e.message)).finally(() => setLoading(false)); }, []);
  const act = async (fn: () => Promise<void>) => { setError(''); setBusy(true); try { await fn(); await load(); } catch (e) { setError(e instanceof Error ? e.message : 'Unable to complete this request.'); } finally { setBusy(false); } };
  return <section className="account-page" style={{ width: '100%' }}><div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 16, flexWrap: 'wrap' }}><div><h2>My solar projects</h2><p className="field-help">Plan your rooftop installation and follow its engineering review.</p></div><button className="btn btn-primary" onClick={() => setShowForm(!showForm)} disabled={busy}>{showForm ? 'Close form' : 'Start a solar assessment'}</button></div>
    {error && <p className="account-error" role="alert">{error}</p>}
    {showForm && <form className="glass-panel account-card account-form" onSubmit={e => { e.preventDefault(); void act(async () => {
      await request('surveys', { monthlyKwh: Number(kwh), roofAreaSqm: Number(area), gridType: grid, propertyAddress: address, roofOrientation: 'Unknown' });
      setShowForm(false); setAddress(''); setKwh(''); setArea('');
    }); }}><h3>Tell us about your home</h3><label htmlFor="site-address">Property address</label><input id="site-address" className="input-field" required maxLength={500} value={address} onChange={e => setAddress(e.target.value)} disabled={busy} />
      <label htmlFor="monthly-use">Monthly electricity use (kWh)</label><input id="monthly-use" className="input-field" type="number" min="0.01" max="100000" step="0.01" required value={kwh} onChange={e => setKwh(e.target.value)} disabled={busy} />
      <label htmlFor="roof-area">Available roof area (m²)</label><input id="roof-area" className="input-field" type="number" min="1" max="100000" step="0.01" required value={area} onChange={e => setArea(e.target.value)} disabled={busy} />
      <label htmlFor="grid-type">Electricity connection</label><select id="grid-type" className="input-field" value={grid} onChange={e => setGrid(e.target.value)} disabled={busy}><option value="SinglePhase">Single phase</option><option value="ThreePhase">Three phase</option></select>
      <p className="field-help">Use your electricity bill and an approximate usable roof area. A site inspection will verify these details.</p><button className="btn btn-primary" disabled={busy}>{busy ? 'Saving…' : 'Save assessment draft'}</button></form>}
    {loading ? <p role="status">Loading your projects…</p> : !surveys.length ? <section className="glass-panel account-card"><h3>Your solar journey starts here</h3><p>Create your first assessment using your electricity bill and roof area. You can add site photos using the mobile app.</p><Link to="/account">Manage your account</Link></section> : surveys.map(survey => <article className="glass-panel account-card" key={survey.id}><span className="badge badge-emerald">{survey.surveyStatus.replace(/([a-z])([A-Z])/g, '$1 $2')}</span><h3 style={{ marginTop: 16 }}>{survey.propertyAddress}</h3><p>{survey.monthlyKwh} kWh / month · {survey.roofAreaSqm} m² roof · {survey.gridType === 'ThreePhase' ? 'Three phase' : 'Single phase'}</p>
      {survey.surveyStatus === 'Draft' && <button className="btn btn-primary" disabled={busy} onClick={() => void act(async () => { await request(`surveys/${survey.id}/submit`, {}); })}>{busy ? 'Processing…' : 'Submit for solar analysis'}</button>}
      {survey.surveyStatus === 'Failed' && <p className="account-error">Analysis could not finish. Contact the project team to review the assessment.</p>}
      {survey.surveyStatus === 'AnalysisComplete' && !(proposals[survey.id]?.length) && <button className="btn btn-secondary" disabled={busy} onClick={() => void act(async () => { await request('proposals', { solarSurveyId: survey.id }); })}>{busy ? 'Preparing…' : 'Request engineering proposal'}</button>}
      {proposals[survey.id]?.map(proposal => <p key={proposal.id}><Link to={`/proposals/${proposal.id}`}>View proposal · {proposal.proposalStatus.replace(/([a-z])([A-Z])/g, '$1 $2')}</Link></p>)}
    </article>)}
  </section>;
}
