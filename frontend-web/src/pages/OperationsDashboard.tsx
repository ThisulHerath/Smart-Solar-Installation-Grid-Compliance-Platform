import { useEffect, useState } from 'react';

import { WorkspaceLinks } from '../components/WorkspaceLinks';
import { useAuth } from '../context/AuthContext';
import { HomeownerWorkspace } from './HomeownerWorkspace';

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
  const { user } = useAuth();

  const [report, setReport] = useState<Report | null>(null);
  const [error, setError] = useState('');

  const staff = user?.roles.some((role) =>
    [
      'ADMINISTRATOR',
      'SENIOR_ENGINEER',
      'INVENTORY_OFFICER',
    ].includes(role)
  );

  useEffect(() => {
    if (!staff) return;

    fetch(
      `${
        import.meta.env.VITE_API_BASE_URL ||
        'http://localhost:5116'
      }/api/reports/overview`,
      {
        headers: {
          Authorization: `Bearer ${localStorage.getItem(
            'smartsolar_token'
          )}`,
        },
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
  }, [staff]);

  return (
    <main
      style={{
        display: 'grid',
        gap: 24,
      }}
    >
      <section
        className="glass-panel"
        style={{
          padding: 32,
        }}
      >
        <p
          style={{
            color: '#287247',
            letterSpacing: 2,
          }}
        >
          SMART SOLAR · SRI LANKA
        </p>

        <h1>Welcome, {user?.fullName}</h1>

        <p>
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

      <WorkspaceLinks />
    </main>
  );
};