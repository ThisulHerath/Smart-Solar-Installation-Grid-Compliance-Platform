import { useEffect, useRef, useState } from 'react';
import { createPortal } from 'react-dom';
import { Link } from 'react-router-dom';
import { Trash2, ChevronLeft, ChevronRight, Search, ClipboardCheck, MapPinned, ShieldCheck } from 'lucide-react';

import { ValidatedForm } from '../components/ValidatedForm';
import { api } from '../services/api';
import { Survey } from '../types/auth';
import projectSolarFacility from '../../images/project-solar-facility.png';

import '../styles/account.css';
import '../styles/project-pagination.css';

async function request(path: string, body?: unknown, method?: string) {
  const token =
    localStorage.getItem('smartsolar_token') ??
    sessionStorage.getItem('smartsolar_token');
  const response = await fetch(
    `${import.meta.env.VITE_API_BASE_URL || 'http://localhost:5116'}/api/${path}`,
    {
      method: method ?? (body === undefined ? 'GET' : 'POST'),
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      ...(body === undefined
        ? {}
        : {
            body: JSON.stringify(body),
          }),
    }
  );

  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    throw new Error(
      data.message ||
        'Unable to complete this request. Please try again.'
    );
  }

  return data;
}

export function HomeownerWorkspace() {
  const [activeImage, setActiveImage] = useState(0);
  const [surveys, setSurveys] = useState<Survey[]>([]);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [deleteTarget, setDeleteTarget] = useState<Survey | null>(null);
  const [deleteError, setDeleteError] = useState('');
  const deleteDialog = useRef<HTMLDialogElement>(null);
  useEffect(() => {
    if (deleteTarget) deleteDialog.current?.showModal();
    else deleteDialog.current?.close();
  }, [deleteTarget]);

  const deleteProject = async () => {
    if (!deleteTarget || busy) return;
    setBusy(true);
    setDeleteError('');
    try {
      await request(`surveys/${deleteTarget.id}`, undefined, 'DELETE');
      setSurveys(current => current.filter(item => item.id !== deleteTarget.id));
      setDeleteTarget(null);
    } catch (e) {
      setDeleteError(e instanceof Error ? e.message : 'Unable to delete project. Please try again.');
    } finally {
      setBusy(false);
    }
  };
  const [projectSearch, setProjectSearch] = useState('');
  const [projectPage, setProjectPage] = useState(1);
  const filteredSurveys = surveys.filter(survey => (survey.propertyAddress || '').toLowerCase().includes(projectSearch.trim().toLowerCase()));
  const pageCount = Math.max(1, Math.ceil(filteredSurveys.length / 5));
  const currentPage = Math.min(projectPage, pageCount);
  const pageStart = (currentPage - 1) * 5;
  const visibleSurveys = filteredSurveys.slice(pageStart, pageStart + 5);

  const [showForm, setShowForm] = useState(false);
  const [address, setAddress] = useState('');
  const [kwh, setKwh] = useState('');
  const [area, setArea] = useState('');
  const [grid, setGrid] = useState('SinglePhase');

  const [
    proposals,
    setProposals,
  ] = useState<
    Record<string, { id: string; proposalStatus: string }[]>
  >({});

  const load = async () => {
    const rows = await api.getSurveys();

    setSurveys(rows);

    const entries = await Promise.all(
      rows.map(
        async (row) =>
          [
            row.id,
            await request(`proposals/survey/${row.id}`),
          ] as const
      )
    );

    setProposals(Object.fromEntries(entries));
  };

  useEffect(() => {
    load()
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    const timer = window.setInterval(() => {
      setActiveImage((current) => (current + 1) % 3);
    }, 5000);

    return () => window.clearInterval(timer);
  }, []);

  const act = async (fn: () => Promise<void>) => {
    setError('');
    setBusy(true);

    try {
      await fn();
      await load();
    } catch (e) {
      setError(
        e instanceof Error
          ? e.message
          : 'Unable to complete this request.'
      );
    } finally {
      setBusy(false);
    }
  };

  return (
    <section
      className="account-page"
      style={{ width: '100%' }}
    >
      <section className="solar-dashboard-carousel" aria-label="Solar inspiration gallery">
        <button
          type="button"
          className="carousel-arrow carousel-arrow-left"
          aria-label="Previous image"
          onClick={() => setActiveImage((activeImage + 2) % 3)}
        >
          ‹
        </button>
        <img
          src={`/images/${activeImage + 1}.jpeg`}
          alt="Solar installation showcase"
        />
        <button
          type="button"
          className="carousel-arrow carousel-arrow-right"
          aria-label="Next image"
          onClick={() => setActiveImage((activeImage + 1) % 3)}
        >
          ›
        </button>
        <div className="carousel-dots" aria-label="Gallery images">
          {[0, 1, 2].map((index) => (
            <button
              type="button"
              key={index}
              className={index === activeImage ? 'active' : ''}
              aria-label={`Show image ${index + 1}`}
              onClick={() => setActiveImage(index)}
            />
          ))}
        </div>
      </section>

      <section className="homeowner-project-heading">
        <div>
          <h2>My solar projects</h2>

          <p className="field-help">
            Plan your rooftop installation and follow its
            engineering review.
          </p>

          <div className="project-assessment-points" aria-label="Solar assessment journey">
            <span><ClipboardCheck size={17} aria-hidden="true" />Share your details</span>
            <span><MapPinned size={17} aria-hidden="true" />Review your site</span>
            <span><ShieldCheck size={17} aria-hidden="true" />Plan for approval</span>
          </div>

        <button
          className="btn btn-primary"
          onClick={() => setShowForm(!showForm)}
          disabled={busy}
        >
          {showForm
            ? 'Close form'
            : 'Start a solar assessment'}
        </button>
        </div>
        <img src={projectSolarFacility} alt="Commercial solar facility at sunset" />
      </section>

      {error && (
        <p className="account-error" role="alert">
          {error}
        </p>
      )}

      {showForm && createPortal((
        <div className="assessment-modal-overlay" role="dialog" aria-modal="true" aria-labelledby="assessment-modal-title">
          <ValidatedForm
            className="assessment-modal-card account-form"
            onSubmit={(e) => {
              e.preventDefault();

              void act(async () => {
                await request('surveys', {
                  monthlyKwh: Number(kwh),
                  roofAreaSqm: Number(area),
                  gridType: grid,
                  propertyAddress: address,
                  roofOrientation: 'Unknown',
                });

                setShowForm(false);
                setAddress('');
                setKwh('');
                setArea('');
              });
            }}
          >
            <button
              type="button"
              className="assessment-modal-close"
              aria-label="Close assessment form"
              onClick={() => setShowForm(false)}
            >
              ×
            </button>

            <h3 id="assessment-modal-title">Tell us about your home</h3>

            <label htmlFor="site-address">
              Property address
            </label>

            <input
              id="site-address"
              className="input-field"
              placeholder="Enter your property address"
              required
              maxLength={500}
              value={address}
              onChange={(e) => setAddress(e.target.value)}
              disabled={busy}
            />

            <label htmlFor="monthly-use">
              Monthly electricity use (kWh)
            </label>

            <input
              id="monthly-use"
              className="input-field"
              type="number"
              placeholder="e.g. 450"
              min="0.01"
              max="100000"
              step="0.01"
              required
              value={kwh}
              onChange={(e) => setKwh(e.target.value)}
              disabled={busy}
            />

            <label htmlFor="roof-area">
              Available roof area (m²)
            </label>

            <input
              id="roof-area"
              className="input-field"
              type="number"
              placeholder="e.g. 120"
              min="1"
              max="100000"
              step="0.01"
              required
              value={area}
              onChange={(e) => setArea(e.target.value)}
              disabled={busy}
            />

            <label htmlFor="grid-type">
              Electricity connection
            </label>

            <select
              id="grid-type"
              className="input-field"
              value={grid}
              onChange={(e) => setGrid(e.target.value)}
              disabled={busy}
            >
              <option value="SinglePhase">
                Single phase
              </option>

              <option value="ThreePhase">
                Three phase
              </option>
            </select>

            <p className="field-help">
              Use your electricity bill and an approximate usable roof area. A site inspection will verify these details.
            </p>

            <button
              className="btn btn-primary"
              disabled={busy}
            >
              {busy ? 'Saving…' : 'Save assessment draft'}
            </button>
          </ValidatedForm>
        </div>
      ), document.body)}

      {loading ? (
        <p role="status">
          Loading your projects…
        </p>
      ) : !surveys.length ? (
        <section className="glass-panel account-card journey-start-card">
          <div className="journey-start-card__intro">
            <span className="journey-start-card__eyebrow"><ShieldCheck size={15} /> Your first project</span>
            <h3>Your solar journey starts here</h3>
            <p>Create your first assessment using your electricity bill and usable roof area. Our team will guide the review from there.</p>
            <Link to="/account" className="journey-start-card__account-link">Manage your account</Link>
          </div>
          <ol className="journey-start-card__steps" aria-label="Solar project steps">
            <li><span><ClipboardCheck size={18} /></span><div><b>Share the essentials</b><small>Add your bill usage and roof area.</small></div></li>
            <li><span><MapPinned size={18} /></span><div><b>Site review</b><small>We verify your rooftop details.</small></div></li>
            <li><span><ShieldCheck size={18} /></span><div><b>Plan with confidence</b><small>Receive your engineered proposal.</small></div></li>
          </ol>
        </section>
      ) : (
        <section className="project-list" aria-label="Your projects">
          <div className="project-list__toolbar">
            <h3>Projects <span>{surveys.length}</span></h3>
            <label className="project-list__search"><Search size={18} aria-hidden="true" /><input type="search" aria-label="Search projects" placeholder="Search by address" value={projectSearch} onChange={event => { setProjectSearch(event.target.value); setProjectPage(1); }} /></label>
          </div>
          {!filteredSurveys.length && <p role="status">No projects match your search.</p>}
        <div className="project-list__cards">{visibleSurveys.map((survey) => (
          <article
            className="project-survey-card"
            key={survey.id}
          >
            <button type="button" className="project-delete" title="Delete project" aria-label={`Delete project ${survey.propertyAddress}`} disabled={busy || survey.surveyStatus === 'Processing'} onClick={() => {
              setDeleteError('');
              setDeleteTarget(survey);
            }}><Trash2 size={17} /></button>
            <span className={`badge ${survey.surveyStatus === 'Failed' ? 'badge-danger' : 'badge-emerald'}`}>
              {survey.surveyStatus.replace(
                /([a-z])([A-Z])/g,
                '$1 $2'
              )}
            </span>

            <h3 style={{ marginTop: 16 }}>
              {survey.propertyAddress}
            </h3>

            <p>
              {survey.monthlyKwh} kWh / month ·{' '}
              {survey.roofAreaSqm} m² roof ·{' '}
              {survey.gridType === 'ThreePhase'
                ? 'Three phase'
                : 'Single phase'}
            </p>

            {survey.surveyStatus === 'Draft' && (
              <button
                className="btn btn-primary"
                disabled={busy}
                onClick={() =>
                  void act(async () => {
                    await request(
                      `surveys/${survey.id}/submit`,
                      {}
                    );
                  })
                }
              >
                {busy
                  ? 'Processing…'
                  : 'Submit for solar analysis'}
              </button>
            )}

            {survey.surveyStatus === 'Failed' && (
              <>
                <p className="account-error">
                  Analysis incomplete. Retry to continue.
                </p>
                <button
                  className="btn btn-primary project-survey-card__retry"
                  disabled={busy}
                  onClick={() =>
                    void act(async () => {
                      await request(`surveys/${survey.id}/retry`, {});
                    })
                  }
                >
                  {busy ? 'Rechecking...' : 'Retry analysis'}
                </button>
              </>
            )}

            {survey.surveyStatus === 'AnalysisComplete' &&
              !(proposals[survey.id]?.length) && (
                <button
                  className="btn btn-secondary"
                  disabled={busy}
                  onClick={() =>
                    void act(async () => {
                      await request('proposals', {
                        solarSurveyId: survey.id,
                      });
                    })
                  }
                >
                  {busy
                    ? 'Preparing…'
                    : 'Request engineering proposal'}
                </button>
              )}

            {proposals[survey.id]?.map((proposal) => (
              <p key={proposal.id}>
                <Link
                  to={`/proposals/${proposal.id}`}
                >
                  View proposal ·{' '}
                  {proposal.proposalStatus.replace(
                    /([a-z])([A-Z])/g,
                    '$1 $2'
                  )}
                </Link>
              </p>
            ))}
          </article>
        ))}</div>
          {filteredSurveys.length > 0 && <nav className="project-list__pagination" aria-label="Project pages">
            <span role="status">{pageStart + 1}-{Math.min(pageStart + 5, filteredSurveys.length)} of {filteredSurveys.length} projects</span>
            <div>
              <button type="button" title="Previous page" aria-label="Previous project page" disabled={currentPage === 1} onClick={() => setProjectPage(currentPage - 1)}><ChevronLeft size={18} /></button>
              <span>Page {currentPage} of {pageCount}</span>
              <button type="button" title="Next page" aria-label="Next project page" disabled={currentPage === pageCount} onClick={() => setProjectPage(currentPage + 1)}><ChevronRight size={18} /></button>
            </div>
          </nav>}
        </section>
      )}
      {createPortal(<dialog ref={deleteDialog} className="project-delete-dialog" aria-labelledby="delete-project-title" onCancel={event => { if (busy) event.preventDefault(); else setDeleteTarget(null); }}>
        <h2 id="delete-project-title">Delete project?</h2>
        <p><strong>{deleteTarget?.propertyAddress}</strong></p>
        <p>This permanently removes the project, proposals and inspection records. This cannot be undone.</p>
        {deleteError && <p role="alert" className="project-delete-dialog__error">{deleteError}</p>}
        <div><button type="button" disabled={busy} onClick={() => setDeleteTarget(null)}>Cancel</button><button type="button" className="project-delete-dialog__confirm" disabled={busy} onClick={() => void deleteProject()}>{busy ? 'Deleting...' : 'Delete project'}</button></div>
      </dialog>, document.body)}
    </section>
  );
};
