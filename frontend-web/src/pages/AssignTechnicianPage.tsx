import { CheckCircle2, HardHat, MapPin, Navigation, UserRoundPlus } from 'lucide-react';
import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { AssignTechnicianForm } from '../components/AssignTechnicianForm';
import { FieldJob } from '../types/auth';
import { externalDirectionsUrl } from '../utils/maps';

export function AssignTechnicianPage() {
  const navigate = useNavigate();
  const [assignedJob, setAssignedJob] = useState<FieldJob | null>(null);

  return (
    <main className="assignment-page operations-page">
      <header className="assignment-page__header">
        <span><UserRoundPlus size={22} /></span>
        <div>
          <p className="eyebrow">FIELD VISIT PLANNING</p>
          <h1>Assign a technician</h1>
          <p>Create one site visit by matching a customer survey with an available field technician.</p>
        </div>
      </header>

      {assignedJob ? (
        <section className="assignment-success" role="status">
          <CheckCircle2 size={34} />
          <div>
            <p className="eyebrow">ASSIGNMENT CREATED</p>
            <h2>{assignedJob.technicianName} is assigned</h2>
            <h3>{assignedJob.projectName || 'Solar project'}</h3>
            <p className="assignment-success__address"><MapPin size={17} /> {assignedJob.propertyAddress}</p>
            <p className="assignment-success__location">
              <CheckCircle2 size={16} />
              {assignedJob.latitude != null && assignedJob.longitude != null
                ? 'Homeowner map location included in the technician assignment.'
                : 'No map pin was saved; navigation will use the property address.'}
            </p>
            <div>
              <a
                className="btn btn-secondary"
                href={externalDirectionsUrl(assignedJob.latitude, assignedJob.longitude, assignedJob.propertyAddress)}
                target="_blank"
                rel="noreferrer"
              >
                <Navigation size={17} /> Open customer location
              </a>
              <button className="btn btn-primary" type="button" onClick={() => setAssignedJob(null)}>
                <UserRoundPlus size={17} /> Assign another technician
              </button>
              <Link className="btn btn-secondary" to="/field-jobs">
                <HardHat size={17} /> View field jobs
              </Link>
            </div>
          </div>
        </section>
      ) : (
        <AssignTechnicianForm
          onAssigned={setAssignedJob}
          onCancel={() => navigate('/field-jobs')}
        />
      )}
    </main>
  );
}
