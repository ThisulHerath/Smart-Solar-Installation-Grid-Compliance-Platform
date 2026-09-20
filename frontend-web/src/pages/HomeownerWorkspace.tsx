import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';

import { ValidatedForm } from '../components/ValidatedForm';
import { api } from '../services/api';
import { Survey } from '../types/auth';

import '../styles/account.css';

async function request(path: string, body?: unknown) {
  const token =
    localStorage.getItem('smartsolar_token') ??
    sessionStorage.getItem('smartsolar_token');
  const response = await fetch(
    `${import.meta.env.VITE_API_BASE_URL || 'http://localhost:5116'}/api/${path}`,
    {
      method: body === undefined ? 'GET' : 'POST',
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

      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          gap: 16,
          flexWrap: 'wrap',
        }}
      >
        <div>
          <h2>My solar projects</h2>

          <p className="field-help">
            Plan your rooftop installation and follow its
            engineering review.
          </p>
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

      {error && (
        <p className="account-error" role="alert">
          {error}
        </p>
      )}

      {showForm && (
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
      )}

      {loading ? (
        <p role="status">
          Loading your projects…
        </p>
      ) : !surveys.length ? (
        <section className="glass-panel account-card">
          <h3>
            Your solar journey starts here
          </h3>

          <p>
            Create your first assessment using your
            electricity bill and roof area. You can add
            site photos using the mobile app.
          </p>

          <Link to="/account">
            Manage your account
          </Link>
        </section>
      ) : (
        surveys.map((survey) => (
          <article
            className="glass-panel account-card"
            key={survey.id}
          >
            <span className="badge badge-emerald">
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
              <p className="account-error">
                Analysis could not finish. Contact the
                project team to review the assessment.
              </p>
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
        ))
      )}
    </section>
  );
};