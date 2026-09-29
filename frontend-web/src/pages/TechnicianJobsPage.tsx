import { useEffect, useState } from 'react';
import {
  ArrowRight,
  CalendarDays,
  CheckCircle2,
  LocateFixed,
  MapPin,
  Navigation,
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { externalDirectionsUrl } from '../utils/maps';

type TechnicianJob = {
  id: string;
  propertyAddress: string;
  customerName: string;
  status: string;
  priority: string;
  scheduledAt?: string;
  latitude?: number;
  longitude?: number;
};

type TechnicianLocation = {
  latitude: number;
  longitude: number;
  accuracy: number;
};

function locationErrorMessage(error: GeolocationPositionError) {
  if (error.code === error.PERMISSION_DENIED) {
    return 'Location permission was blocked. Allow location access in your browser settings and try again.';
  }
  if (error.code === error.TIMEOUT) {
    return 'Your location request timed out. Move near a window or check location services, then try again.';
  }
  return 'Your current location could not be detected. Check location services and try again.';
}

export function TechnicianJobsPage() {
  const { token } = useAuth();
  const [jobs, setJobs] = useState<TechnicianJob[]>([]);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);
  const [technicianLocation, setTechnicianLocation] = useState<TechnicianLocation | null>(null);
  const [locationError, setLocationError] = useState('');
  const [locating, setLocating] = useState(false);

  useEffect(() => {
    fetch(`${import.meta.env.VITE_API_BASE_URL || 'http://localhost:5116'}/api/technician/jobs`, {
      headers: token ? { Authorization: `Bearer ${token}` } : {},
    })
      .then(async response => {
        if (!response.ok) throw new Error('Unable to load your assigned jobs.');
        return response.json();
      })
      .then(setJobs)
      .catch(requestError => setError(requestError.message))
      .finally(() => setLoading(false));
  }, [token]);

  const getCurrentLocation = () => {
    if (!navigator.geolocation) {
      setLocationError('This browser does not provide location access.');
      return;
    }

    setLocating(true);
    setLocationError('');
    navigator.geolocation.getCurrentPosition(
      position => {
        setTechnicianLocation({
          latitude: position.coords.latitude,
          longitude: position.coords.longitude,
          accuracy: position.coords.accuracy,
        });
        setLocating(false);
      },
      geolocationError => {
        setLocationError(locationErrorMessage(geolocationError));
        setLocating(false);
      },
      { enableHighAccuracy: true, timeout: 20_000, maximumAge: 30_000 },
    );
  };

  return (
    <main className="technician-jobs-page operations-page">
      <header className="technician-jobs-heading">
        <div>
          <p className="eyebrow">FIELD WORKSPACE</p>
          <h1>My assignments</h1>
          <p>Site inspections, homeowner locations, and compliance work assigned to you.</p>
        </div>
      </header>

      <section className="technician-route-origin" aria-labelledby="route-origin-heading">
        <span className="technician-route-origin__icon"><LocateFixed size={23} /></span>
        <div>
          <p className="eyebrow">ROUTE STARTING POINT</p>
          <h2 id="route-origin-heading">Get your location before navigating</h2>
          <p>
            {technicianLocation
              ? `Current location confirmed with approximately ${Math.round(technicianLocation.accuracy)} m accuracy.`
              : 'Your location is used only to create the route from you to the customer home.'}
          </p>
          {locationError && <p className="technician-route-origin__error" role="alert">⚠ {locationError}</p>}
        </div>
        <button className="btn btn-secondary" type="button" onClick={getCurrentLocation} disabled={locating}>
          <LocateFixed size={17} />
          {locating ? 'Getting location…' : technicianLocation ? 'Update my location' : '1. Get my current location'}
        </button>
      </section>

      {error && <p className="staff-dashboard-error" role="alert">{error}</p>}
      {loading ? (
        <p className="technician-jobs-empty">Loading assigned work...</p>
      ) : jobs.length === 0 ? (
        <p className="technician-jobs-empty">No field assignments are scheduled for you right now.</p>
      ) : (
        <div className="technician-job-grid">
          {jobs.map(job => {
            const directionsUrl = technicianLocation
              ? externalDirectionsUrl(job.latitude, job.longitude, job.propertyAddress, technicianLocation)
              : '';
            return (
              <article key={job.id}>
                <span className="technician-job-status">{job.status.replace(/_/g, ' ')}</span>
                <h2>{job.customerName}</h2>
                <p><MapPin size={15} />{job.propertyAddress}</p>
                <span className="technician-job-location-state">
                  <CheckCircle2 size={14} />
                  {job.latitude != null && job.longitude != null
                    ? 'Homeowner map location confirmed'
                    : 'Directions use the property address'}
                </span>
                <p>
                  <CalendarDays size={15} />
                  {job.scheduledAt
                    ? new Date(job.scheduledAt).toLocaleDateString('en-LK', { dateStyle: 'medium' })
                    : 'Schedule pending'}
                </p>
                <strong>{job.priority} priority</strong>
                {technicianLocation ? (
                  <a
                    aria-label={`Navigate from my location to ${job.customerName}'s home`}
                    className="technician-job-directions"
                    href={directionsUrl}
                    target="_blank"
                    rel="noreferrer"
                  >
                    <Navigation size={16} />2. Navigate to customer home
                  </a>
                ) : (
                  <button
                    className="technician-job-directions technician-job-directions--disabled"
                    type="button"
                    disabled
                    title="Get your current location first"
                  >
                    <Navigation size={16} />2. Navigate to customer home
                  </button>
                )}
                <span className="technician-job-note">Assigned field visit <ArrowRight size={15} /></span>
              </article>
            );
          })}
        </div>
      )}
    </main>
  );
}
