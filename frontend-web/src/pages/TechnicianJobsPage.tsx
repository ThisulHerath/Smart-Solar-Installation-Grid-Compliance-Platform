import { useEffect, useState } from 'react';
import { ArrowRight, CalendarDays, MapPin } from 'lucide-react';
import { useAuth } from '../context/AuthContext';

type TechnicianJob = { id: string; propertyAddress: string; customerName: string; status: string; priority: string; scheduledAt?: string };

export function TechnicianJobsPage() {
  const { token } = useAuth();
  const [jobs, setJobs] = useState<TechnicianJob[]>([]);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch(`${import.meta.env.VITE_API_BASE_URL || 'http://localhost:5116'}/api/technician/jobs`, { headers: token ? { Authorization: `Bearer ${token}` } : {} })
      .then(async (response) => { if (!response.ok) throw new Error('Unable to load your assigned jobs.'); return response.json(); })
      .then(setJobs).catch((requestError) => setError(requestError.message)).finally(() => setLoading(false));
  }, [token]);

  return <main className="technician-jobs-page operations-page"><header className="technician-jobs-heading"><div><p className="eyebrow">FIELD WORKSPACE</p><h1>My assignments</h1><p>Site inspections and compliance work assigned to you.</p></div></header>{error && <p className="staff-dashboard-error" role="alert">{error}</p>}{loading ? <p className="technician-jobs-empty">Loading assigned work...</p> : jobs.length === 0 ? <p className="technician-jobs-empty">No field assignments are scheduled for you right now.</p> : <div className="technician-job-grid">{jobs.map((job) => <article key={job.id}><span className="technician-job-status">{job.status.replace(/_/g, ' ')}</span><h2>{job.customerName}</h2><p><MapPin size={15} />{job.propertyAddress}</p><p><CalendarDays size={15} />{job.scheduledAt ? new Date(job.scheduledAt).toLocaleDateString('en-LK', { dateStyle: 'medium' }) : 'Schedule pending'}</p><strong>{job.priority} priority</strong><span className="technician-job-note">Assigned field visit <ArrowRight size={15} /></span></article>)}</div>}</main>;
}
