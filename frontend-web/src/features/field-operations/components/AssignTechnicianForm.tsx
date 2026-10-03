import { CalendarDays, ClipboardList, MapPin, Search, ShieldCheck, UserRound } from 'lucide-react';
import { useEffect, useMemo, useRef, useState } from 'react';
import { api } from '../../../services/api';
import { FieldJob, Survey } from '../../../types/auth';
import { ValidatedForm } from '../../../components/ValidatedForm';

type TechnicianOption = { id: string; fullName: string; email: string };

function localDateValue(date: Date) {
  const local = new Date(date.getTime() - date.getTimezoneOffset() * 60_000);
  return local.toISOString().slice(0, 10);
}

function scheduleValidation(date: string, time: string) {
  if (!date && !time) return '';
  if (!date || !time) return 'Select both a visit date and an arrival time.';
  if (new Date(`${date}T${time}:00`).getTime() <= Date.now()) return 'Choose a visit time in the future.';
  return '';
}

function readableStatus(status?: string) {
  return (status || 'Unknown').replace(/([a-z])([A-Z])/g, '$1 $2');
}

function surveyTitle(survey: Survey) {
  return survey.propertyAddress || survey.projectName || 'Unnamed customer site';
}

export function AssignTechnicianForm({ onAssigned, onCancel }: {
  onAssigned: (job: FieldJob) => void;
  onCancel: () => void;
}) {
  const [surveys, setSurveys] = useState<Survey[]>([]);
  const [surveyQuery, setSurveyQuery] = useState('');
  const [technicians, setTechnicians] = useState<TechnicianOption[]>([]);
  const [surveyId, setSurveyId] = useState('');
  const [technicianId, setTechnicianId] = useState('');
  const [priority, setPriority] = useState('Medium');
  const [visitDate, setVisitDate] = useState('');
  const [visitTime, setVisitTime] = useState('');
  const [scheduleTouched, setScheduleTouched] = useState(false);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [attempt, setAttempt] = useState(0);
  const dateRef = useRef<HTMLInputElement>(null);
  const today = useMemo(() => localDateValue(new Date()), []);
  const scheduleError = scheduleTouched ? scheduleValidation(visitDate, visitTime) : '';
  const selectedSurvey = surveys.find(survey => survey.id === surveyId);
  const selectedTechnician = technicians.find(technician => technician.id === technicianId);
  const visibleSurveys = useMemo(() => {
    const query = surveyQuery.trim().toLocaleLowerCase();
    return [...surveys]
      .sort((left, right) => new Date(right.createdAt || 0).getTime() - new Date(left.createdAt || 0).getTime())
      .filter(survey => {
        if (!query || survey.id === surveyId) return true;
        return [survey.propertyAddress, survey.projectName, survey.customerName, survey.id, survey.surveyStatus]
          .some(value => value?.toLocaleLowerCase().includes(query));
      });
  }, [surveyId, surveyQuery, surveys]);

  useEffect(() => {
    let active = true;
    setLoading(true);
    setError('');
    Promise.all([api.getSurveys(), api.getTechnicians()])
      .then(([surveyRows, technicianRows]) => {
        if (!active) return;
        setSurveys(surveyRows);
        setTechnicians(technicianRows);
      })
      .catch(requestError => {
        if (active) setError(requestError.message);
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => { active = false; };
  }, [attempt]);

  return (
    <section className="assignment-form-card glass-panel" aria-labelledby="assignment-heading">
      <header className="assignment-form-card__heading">
        <div>
          <p className="eyebrow">ASSIGNMENT DETAILS</p>
          <h2 id="assignment-heading">Site visit details</h2>
          <p>Select the customer project, technician, priority, and preferred visit time.</p>
        </div>
        <span><ShieldCheck size={19} /> Engineer authorized</span>
      </header>

      {error && <div className="assignment-form-error" role="alert">⚠ {error}</div>}
      {loading ? (
        <div className="assignment-form-loading" role="status">Loading customer projects and available technicians…</div>
      ) : (
        <ValidatedForm
          className="assignment-form"
          onSubmit={async event => {
            event.preventDefault();
            if (saving) return;
            setScheduleTouched(true);
            const validationMessage = scheduleValidation(visitDate, visitTime);
            if (validationMessage) {
              dateRef.current?.scrollIntoView({ block: 'center', behavior: 'smooth' });
              dateRef.current?.focus({ preventScroll: true });
              return;
            }

            setSaving(true);
            setError('');
            try {
              const scheduledAt = visitDate && visitTime ? new Date(`${visitDate}T${visitTime}:00`).toISOString() : undefined;
              const job = await api.createFieldJob({
                solarSurveyId: surveyId,
                technicianId,
                priority,
                ...(scheduledAt ? { scheduledAt } : {}),
              });
              onAssigned(job);
            } catch (requestError) {
              setError((requestError as Error).message);
            } finally {
              setSaving(false);
            }
          }}
        >
          <section className="assignment-form-section" aria-labelledby="assignment-project-heading">
            <div className="assignment-form-section__title">
              <span><ClipboardList size={18} /></span>
              <div><h3 id="assignment-project-heading">Customer project</h3><p>Choose the survey that requires a site inspection.</p></div>
            </div>
            <div className="survey-picker">
              <label className="survey-picker__search">
                Find a survey
                <span className="survey-picker__search-field">
                  <Search size={17} aria-hidden="true" />
                  <input
                    aria-label="Search customer surveys"
                    type="search"
                    placeholder="Search address, homeowner, project or survey ID"
                    value={surveyQuery}
                    disabled={saving || !surveys.length}
                    onChange={event => setSurveyQuery(event.target.value)}
                  />
                </span>
              </label>
              <label>
                Customer survey <span aria-hidden="true">*</span>
                <select aria-label="Customer survey" className="input-field survey-picker__select" required value={surveyId} disabled={saving || !surveys.length} onChange={event => setSurveyId(event.target.value)}>
                  <option value="">Choose a customer site ({visibleSurveys.length} available)</option>
                  {visibleSurveys.map(survey => (
                  <option key={survey.id} value={survey.id}>
                    {surveyTitle(survey)} — {survey.customerName || 'Unknown homeowner'} — {readableStatus(survey.surveyStatus)}
                  </option>
                  ))}
                </select>
              </label>
              {surveyQuery && !visibleSurveys.length && (
                <p className="assignment-empty" role="status">No surveys match “{surveyQuery}”. Try an address, homeowner name, or survey ID.</p>
              )}
              {selectedSurvey && (
                <article className="survey-picker__selection" aria-label="Selected survey details">
                  <div className="survey-picker__selection-icon"><MapPin size={20} aria-hidden="true" /></div>
                  <div className="survey-picker__selection-main">
                    <span className="survey-picker__selection-label">Selected customer site</span>
                    <strong>{surveyTitle(selectedSurvey)}</strong>
                    {selectedSurvey.projectName && selectedSurvey.projectName !== selectedSurvey.propertyAddress && <small>{selectedSurvey.projectName}</small>}
                  </div>
                  <dl>
                    <div><dt>Homeowner</dt><dd>{selectedSurvey.customerName || 'Not provided'}</dd></div>
                    <div><dt>Survey ID</dt><dd>{selectedSurvey.id.slice(0, 8).toUpperCase()}</dd></div>
                    <div><dt>Status</dt><dd><span className={`survey-picker__status survey-picker__status--${selectedSurvey.surveyStatus?.toLocaleLowerCase() || 'unknown'}`}>{readableStatus(selectedSurvey.surveyStatus)}</span></dd></div>
                  </dl>
                </article>
              )}
            </div>
            {!surveys.length && <p className="assignment-empty">No customer surveys are currently available.</p>}
          </section>

          <section className="assignment-form-section" aria-labelledby="assignment-technician-heading">
            <div className="assignment-form-section__title">
              <span><UserRound size={18} /></span>
              <div><h3 id="assignment-technician-heading">Technician and priority</h3><p>Select the person responsible for the field visit.</p></div>
            </div>
            <div className="assignment-form-grid">
              <label>
                Field technician <span aria-hidden="true">*</span>
                <select aria-label="Field technician" className="input-field" required value={technicianId} disabled={saving} onChange={event => setTechnicianId(event.target.value)}>
                  <option value="">Select an available technician</option>
                  {technicians.map(technician => <option key={technician.id} value={technician.id}>{technician.fullName} · {technician.email}</option>)}
                </select>
              </label>
              <label>
                Priority <span aria-hidden="true">*</span>
                <select aria-label="Priority" className="input-field" required value={priority} disabled={saving} onChange={event => setPriority(event.target.value)}>
                  {['Low', 'Medium', 'High', 'Urgent'].map(value => <option key={value}>{value}</option>)}
                </select>
              </label>
            </div>
            {!technicians.length && <p className="assignment-empty">No active field technicians are available.</p>}
          </section>

          <section className="assignment-form-section" aria-labelledby="assignment-schedule-heading">
            <div className="assignment-form-section__title">
              <span><CalendarDays size={18} /></span>
              <div><h3 id="assignment-schedule-heading">Visit schedule</h3><p>Optional. Leave both fields empty when the visit time is not confirmed.</p></div>
            </div>
            <div className="assignment-form-grid">
              <label>
                Visit date
                <input ref={dateRef} aria-label="Visit date" className="input-field" type="date" min={today} value={visitDate} required={Boolean(visitTime)} disabled={saving} aria-invalid={Boolean(scheduleError)} aria-describedby="visit-schedule-help" onBlur={() => setScheduleTouched(true)} onChange={event => setVisitDate(event.target.value)} />
              </label>
              <label>
                Arrival time
                <input aria-label="Arrival time" className="input-field" type="time" value={visitTime} required={Boolean(visitDate)} disabled={saving} aria-invalid={Boolean(scheduleError)} aria-describedby="visit-schedule-help" onBlur={() => setScheduleTouched(true)} onChange={event => setVisitTime(event.target.value)} />
              </label>
            </div>
            <p id="visit-schedule-help" className={scheduleError ? 'assignment-schedule-error' : 'assignment-field-help'} role={scheduleError ? 'alert' : undefined}>
              {scheduleError ? `⚠ ${scheduleError}` : 'The technician will see this date and time in their assignment.'}
            </p>
          </section>

          {(selectedSurvey || selectedTechnician) && (
            <aside className="assignment-preview" aria-label="Assignment summary">
              <strong>Assignment summary</strong>
              <span>{selectedSurvey ? `${selectedSurvey.projectName || selectedSurvey.propertyAddress} · ${selectedSurvey.customerName || 'Customer'} · ${selectedSurvey.propertyAddress}` : 'Select a customer survey'}</span>
              <span>{selectedTechnician ? `${selectedTechnician.fullName} · ${priority} priority` : 'Select a field technician'}</span>
            </aside>
          )}

          <div className="assignment-form-actions">
            <button className="btn btn-primary" type="submit" disabled={saving}>{saving ? 'Creating assignment…' : 'Assign site visit'}</button>
            <button className="btn btn-secondary" type="button" disabled={saving} onClick={onCancel}>Cancel</button>
            {error && <button className="btn btn-secondary" type="button" disabled={saving} onClick={() => setAttempt(value => value + 1)}>Reload options</button>}
          </div>
        </ValidatedForm>
      )}
    </section>
  );
}
