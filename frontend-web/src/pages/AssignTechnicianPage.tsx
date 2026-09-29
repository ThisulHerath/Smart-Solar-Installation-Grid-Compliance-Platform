import { CheckCircle2, HardHat, UserRoundPlus } from 'lucide-react';
import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { AssignTechnicianForm } from '../components/AssignTechnicianForm';
import { FieldJob } from '../types/auth';

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
            <p>{assignedJob.propertyAddress}</p>
            <div>
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
