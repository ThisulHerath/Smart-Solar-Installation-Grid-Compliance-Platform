import { useEffect, useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { HomeownerWorkspace } from './HomeownerWorkspace';
import { StaffDashboard } from '../components/StaffDashboard';

type Report = {
  surveyCount: number;
  pendingApprovals: number;
  approvedProposals: number;
  lowStockItems: number;
  reservedEquipmentValueLkr: number;
  proposalStatuses: {
    status: string;
    count: number;
  }[];
};

export function OperationsDashboard() {
  const { user, token } = useAuth();

  const [report, setReport] = useState<Report | null>(null);
  const [error, setError] = useState('');

  const staff = user?.roles.some((role) =>
    [
      'ADMINISTRATOR',
      'SENIOR_ENGINEER',
      'INVENTORY_OFFICER',
    ].includes(role)
  );
  const admin = user?.roles.includes('ADMINISTRATOR');

  useEffect(() => {
    if (!staff) return;

    fetch(
      `${
        import.meta.env.VITE_API_BASE_URL ||
        'http://localhost:5116'
      }/api/reports/overview`,
      {
        headers: token ? { Authorization: `Bearer ${token}` } : {},
      }
    )
      .then(async (response) => {
        if (!response.ok) {
          throw new Error('Unable to load operational totals.');
        }

        return response.json();
      })
      .then(setReport)
      .catch((e) => setError(e.message));
  }, [staff, token]);

  if (admin && user) {
    return (
      <section className="admin-dashboard-content">
          <section className="admin-welcome-card">
            <p>SMART SOLAR · SRI LANKA</p>
            <h1>Welcome, System Administrator Dashboard</h1>
            <span>Coordinate rooftop solar surveys, field inspections, engineering review, and equipment preparation.</span>
          </section>

          {error && <p role="alert">{error}</p>}
          {!report && !error && <p>Loading your dashboard…</p>}

          {report && (
            <>
              <div className="admin-metrics-grid">
                {[
                  ['Solar surveys', report.surveyCount, 'survey'],
                  ['Awaiting approval', report.pendingApprovals, 'pending'],
                  ['Approved proposals', report.approvedProposals, 'approved'],
                  ['Low stock items', report.lowStockItems, 'low-stock'],
                ].map(([label, value, tone]) => (
                  <section className={`admin-metric-card ${tone}`} key={label}>
                    <span>{label}</span>
                    <strong>{value}</strong>
                  </section>
                ))}
              </div>

              <section className="admin-equipment-card">
                <h2>Reserved equipment value</h2>
                <strong>LKR {report.reservedEquipmentValueLkr.toLocaleString('en-LK')}</strong>
                <p>Equipment value only; excludes installation and taxes.</p>
                <h3>Proposal activity</h3>
                {report.proposalStatuses.length ? report.proposalStatuses.map((row) => (
                  <span key={row.status}>{row.status}: {row.count}</span>
                )) : <span>No proposals yet.</span>}
              </section>
            </>
          )}
      </section>
    );
  }

  if (user && !user.roles.includes('HOMEOWNER')) {
    return <StaffDashboard user={user} report={report} error={error} />;
  }

  return (
    <main className="workspace-dashboard" style={{ display: 'grid', gap: 24 }}>
      <section
        className="glass-panel dashboard-hero"
        style={{
          padding: 32,
        }}
      >
        <p className="dashboard-kicker">SMART SOLAR · SRI LANKA</p>

        <h1>Welcome, {user?.fullName}</h1>

        <p className="dashboard-hero-copy">
          Coordinate rooftop solar surveys, field inspections,
          engineering review, and equipment preparation.
        </p>
      </section>

      {error && <p role="alert">{error}</p>}

      {user?.roles.includes('HOMEOWNER') && (
        <HomeownerWorkspace />
      )}

      {staff && !report && !error && (
        <p>Loading your dashboard…</p>
      )}

      {report && (
        <>
          <div
            style={{
              display: 'grid',
              gridTemplateColumns:
                'repeat(auto-fit,minmax(170px,1fr))',
              gap: 16,
            }}
          >
            {(
              [
                ['Solar surveys', report.surveyCount],
                ['Awaiting approval', report.pendingApprovals],
                [
                  'Approved proposals',
                  report.approvedProposals,
                ],
                ['Low stock items', report.lowStockItems],
              ] as const
            ).map(([name, count]) => (
              <section
                className="glass-panel"
                style={{
                  padding: 24,
                }}
                key={name}
              >
                <p>{name}</p>

                <strong
                  style={{
                    fontSize: 34,
                  }}
                >
                  {count}
                </strong>
              </section>
            ))}
          </div>

          <section
            className="glass-panel"
            style={{
              padding: 24,
            }}
          >
            <h2>Reserved equipment value</h2>

            <p
              style={{
                fontSize: 30,
                color: '#287247',
              }}
            >
              LKR{' '}
              {report.reservedEquipmentValueLkr.toLocaleString(
                'en-LK'
              )}
            </p>

            <p>
              Equipment value only; excludes installation and
              taxes.
            </p>

            <h3>Proposal activity</h3>

            {report.proposalStatuses.length ? (
              report.proposalStatuses.map((row) => (
                <p key={row.status}>
                  {row.status}: {row.count}
                </p>
              ))
            ) : (
              <p>No proposals yet.</p>
            )}
          </section>
        </>
      )}

    </main>
  );
};
