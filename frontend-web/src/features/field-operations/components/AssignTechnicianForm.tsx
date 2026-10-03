import {
  CalendarDays, Check, ChevronDown, ChevronLeft, ChevronRight, ClipboardList,
  Clock3, MapPin, Search, ShieldCheck, UserRound, X,
} from 'lucide-react';
import { RefObject, useEffect, useId, useMemo, useRef, useState } from 'react';
import { ValidatedForm } from '../../../components/ValidatedForm';
import { api } from '../../../services/api';
import { FieldJob, Survey } from '../../../types/auth';

type TechnicianOption = { id: string; fullName: string; email: string };
type Choice = { value: string; title: string; description?: string; badge?: string; searchText?: string };

function localDateValue(date: Date) {
  const local = new Date(date.getTime() - date.getTimezoneOffset() * 60_000);
  return local.toISOString().slice(0, 10);
}

function dateFromValue(value: string) {
  const [year, month, day] = value.split('-').map(Number);
  return new Date(year, month - 1, day);
}

function formatVisitDate(value: string) {
  return value ? new Intl.DateTimeFormat('en-LK', { weekday: 'short', day: 'numeric', month: 'short', year: 'numeric' }).format(dateFromValue(value)) : '';
}

function formatTime(value: string) {
  if (!value) return '';
  const [hours, minutes] = value.split(':').map(Number);
  return new Intl.DateTimeFormat('en-LK', { hour: 'numeric', minute: '2-digit' }).format(new Date(2000, 0, 1, hours, minutes));
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
  return survey.projectName || survey.propertyAddress || 'Unnamed customer site';
}

function ChoiceMenu({ label, value, placeholder, choices, onChange, disabled, searchable = false,
  searchPlaceholder = 'Search options', emptyMessage = 'No matching options found.', invalid = false, buttonRef }: {
  label: string; value: string; placeholder: string; choices: Choice[]; onChange: (value: string) => void;
  disabled?: boolean; searchable?: boolean; searchPlaceholder?: string; emptyMessage?: string;
  invalid?: boolean; buttonRef?: RefObject<HTMLButtonElement>;
}) {
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState('');
  const [activeIndex, setActiveIndex] = useState(0);
  const rootRef = useRef<HTMLDivElement>(null);
  const searchRef = useRef<HTMLInputElement>(null);
  const listId = useId();
  const selected = choices.find(choice => choice.value === value);
  const filtered = useMemo(() => {
    const normalized = query.trim().toLocaleLowerCase();
    return normalized ? choices.filter(choice => `${choice.title} ${choice.description || ''} ${choice.badge || ''} ${choice.searchText || ''}`.toLocaleLowerCase().includes(normalized)) : choices;
  }, [choices, query]);

  useEffect(() => {
    if (!open) return;
    const close = (event: MouseEvent) => { if (!rootRef.current?.contains(event.target as Node)) setOpen(false); };
    document.addEventListener('mousedown', close);
    return () => document.removeEventListener('mousedown', close);
  }, [open]);

  useEffect(() => {
    if (open && searchable) window.setTimeout(() => searchRef.current?.focus(), 0);
  }, [open, searchable]);

  function choose(nextValue: string) {
    onChange(nextValue);
    setOpen(false);
    setQuery('');
    window.setTimeout(() => buttonRef?.current?.focus(), 0);
  }

  function handleKeyDown(event: React.KeyboardEvent) {
    if (event.key === 'Escape') {
      event.preventDefault();
      setOpen(false);
      buttonRef?.current?.focus();
    } else if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
      event.preventDefault();
      if (!open) setOpen(true);
      const direction = event.key === 'ArrowDown' ? 1 : -1;
      setActiveIndex(index => Math.max(0, Math.min(filtered.length - 1, index + direction)));
    } else if (event.key === 'Enter' && open && filtered[activeIndex]) {
      event.preventDefault();
      choose(filtered[activeIndex].value);
    }
  }

  return (
    <div className={`assignment-choice ${open ? 'assignment-choice--open' : ''}`} ref={rootRef} onKeyDown={handleKeyDown}>
      <button ref={buttonRef} type="button" className="assignment-choice__trigger" aria-label={label} role="combobox"
        aria-expanded={open} aria-controls={listId} aria-haspopup="listbox" aria-invalid={invalid} disabled={disabled}
        onClick={() => { setOpen(current => !current); setActiveIndex(Math.max(0, choices.findIndex(choice => choice.value === value))); }}>
        <span className="assignment-choice__trigger-copy">
          <strong className={!selected ? 'assignment-choice__placeholder' : ''}>{selected?.title || placeholder}</strong>
          {selected?.description && <small>{selected.description}</small>}
        </span>
        {selected?.badge && <span className="assignment-choice__badge">{selected.badge}</span>}
        <ChevronDown size={18} aria-hidden="true" />
      </button>
      {open && (
        <div className="assignment-choice__popover">
          {searchable && <div className="assignment-choice__search"><Search size={17} aria-hidden="true" />
            <input ref={searchRef} aria-label={`Search ${label.toLocaleLowerCase()}`} value={query} placeholder={searchPlaceholder}
              onChange={event => { setQuery(event.target.value); setActiveIndex(0); }} />
            {query && <button type="button" aria-label="Clear search" onClick={() => setQuery('')}><X size={15} /></button>}
          </div>}
          <div id={listId} className="assignment-choice__list" role="listbox" aria-label={`${label} options`}>
            {filtered.map((choice, index) => <button key={choice.value} type="button" role="option" aria-selected={choice.value === value}
              className={`assignment-choice__option ${index === activeIndex ? 'assignment-choice__option--active' : ''}`}
              onMouseEnter={() => setActiveIndex(index)} onClick={() => choose(choice.value)}>
              <span className="assignment-choice__option-marker">{choice.value === value ? <Check size={16} /> : null}</span>
              <span><strong>{choice.title}</strong>{choice.description && <small>{choice.description}</small>}</span>
              {choice.badge && <em>{choice.badge}</em>}
            </button>)}
            {!filtered.length && <div className="assignment-choice__empty" role="status">{emptyMessage}</div>}
          </div>
          <footer>{filtered.length} {filtered.length === 1 ? 'option' : 'options'} · Use ↑ ↓ and Enter</footer>
        </div>
      )}
    </div>
  );
}

function DatePicker({ value, onChange, disabled, invalid, buttonRef }: {
  value: string; onChange: (value: string) => void; disabled?: boolean; invalid?: boolean;
  buttonRef: RefObject<HTMLButtonElement>;
}) {
  const todayValue = localDateValue(new Date());
  const [open, setOpen] = useState(false);
  const [month, setMonth] = useState(() => {
    const date = value ? dateFromValue(value) : new Date();
    return new Date(date.getFullYear(), date.getMonth(), 1);
  });
  const rootRef = useRef<HTMLDivElement>(null);
  const calendarId = useId();
  const firstDay = new Date(month.getFullYear(), month.getMonth(), 1).getDay();
  const daysInMonth = new Date(month.getFullYear(), month.getMonth() + 1, 0).getDate();
  const cells = Array.from({ length: firstDay + daysInMonth }, (_, index) => index < firstDay ? null : index - firstDay + 1);

  useEffect(() => {
    if (!open) return;
    const close = (event: MouseEvent) => { if (!rootRef.current?.contains(event.target as Node)) setOpen(false); };
    document.addEventListener('mousedown', close);
    return () => document.removeEventListener('mousedown', close);
  }, [open]);

  function select(nextValue: string) {
    onChange(nextValue);
    setOpen(false);
    window.setTimeout(() => buttonRef.current?.focus(), 0);
  }

  function quickDate(offset: number) {
    const date = new Date();
    date.setDate(date.getDate() + offset);
    select(localDateValue(date));
  }

  return (
    <div className="assignment-date" ref={rootRef}>
      <button ref={buttonRef} type="button" className="assignment-date__trigger" aria-label="Visit date" aria-expanded={open}
        aria-controls={calendarId} aria-invalid={invalid} disabled={disabled} onClick={() => setOpen(current => !current)}>
        <CalendarDays size={19} /><span><small>Visit date</small><strong>{value ? formatVisitDate(value) : 'Select a date'}</strong></span><ChevronDown size={18} />
      </button>
      {open && <div className="assignment-date__popover" id={calendarId}>
        <div className="assignment-date__quick"><button type="button" onClick={() => quickDate(0)}>Today</button><button type="button" onClick={() => quickDate(1)}>Tomorrow</button><button type="button" onClick={() => quickDate(7)}>Next week</button></div>
        <div className="assignment-date__month"><button type="button" aria-label="Previous month" onClick={() => setMonth(current => new Date(current.getFullYear(), current.getMonth() - 1, 1))}><ChevronLeft size={18} /></button><strong>{new Intl.DateTimeFormat('en-LK', { month: 'long', year: 'numeric' }).format(month)}</strong><button type="button" aria-label="Next month" onClick={() => setMonth(current => new Date(current.getFullYear(), current.getMonth() + 1, 1))}><ChevronRight size={18} /></button></div>
        <div className="assignment-date__weekdays">{['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'].map(day => <span key={day}>{day}</span>)}</div>
        <div className="assignment-date__days">{cells.map((day, index) => {
          if (!day) return <span key={`blank-${index}`} />;
          const dayValue = localDateValue(new Date(month.getFullYear(), month.getMonth(), day));
          return <button key={dayValue} type="button" disabled={dayValue < todayValue} aria-label={formatVisitDate(dayValue)} aria-pressed={dayValue === value} onClick={() => select(dayValue)}>{day}</button>;
        })}</div>
      </div>}
    </div>
  );
}

const timeChoices: Choice[] = Array.from({ length: 25 }, (_, index) => {
  const totalMinutes = 7 * 60 + index * 30;
  const value = `${String(Math.floor(totalMinutes / 60)).padStart(2, '0')}:${String(totalMinutes % 60).padStart(2, '0')}`;
  return { value, title: formatTime(value), description: index < 10 ? 'Morning arrival' : index < 20 ? 'Afternoon arrival' : 'Evening arrival' };
});

const priorityOptions = [
  { value: 'Low', note: 'Flexible timing' }, { value: 'Medium', note: 'Standard visit' },
  { value: 'High', note: 'Attend soon' }, { value: 'Urgent', note: 'Immediate attention' },
];

export function AssignTechnicianForm({ onAssigned, onCancel }: { onAssigned: (job: FieldJob) => void; onCancel: () => void }) {
  const [surveys, setSurveys] = useState<Survey[]>([]);
  const [technicians, setTechnicians] = useState<TechnicianOption[]>([]);
  const [surveyId, setSurveyId] = useState('');
  const [technicianId, setTechnicianId] = useState('');
  const [priority, setPriority] = useState('Medium');
  const [visitDate, setVisitDate] = useState('');
  const [visitTime, setVisitTime] = useState('');
  const [scheduleTouched, setScheduleTouched] = useState(false);
  const [selectionTouched, setSelectionTouched] = useState(false);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [attempt, setAttempt] = useState(0);
  const surveyRef = useRef<HTMLButtonElement>(null);
  const technicianRef = useRef<HTMLButtonElement>(null);
  const dateRef = useRef<HTMLButtonElement>(null);
  const timeRef = useRef<HTMLButtonElement>(null);
  const scheduleError = scheduleTouched ? scheduleValidation(visitDate, visitTime) : '';
  const selectedSurvey = surveys.find(survey => survey.id === surveyId);
  const selectedTechnician = technicians.find(technician => technician.id === technicianId);
  const surveyChoices = useMemo<Choice[]>(() => [...surveys].sort((a, b) => new Date(b.createdAt || 0).getTime() - new Date(a.createdAt || 0).getTime()).map(survey => ({
    value: survey.id, title: surveyTitle(survey),
    description: `${survey.customerName || 'Homeowner not provided'} · ${survey.propertyAddress || 'Address not provided'}`,
    badge: readableStatus(survey.surveyStatus), searchText: survey.id,
  })), [surveys]);
  const technicianChoices = useMemo<Choice[]>(() => technicians.map(technician => ({ value: technician.id, title: technician.fullName, description: technician.email, badge: 'Available' })), [technicians]);

  useEffect(() => {
    let active = true;
    setLoading(true); setError('');
    Promise.all([api.getSurveys(), api.getTechnicians()]).then(([surveyRows, technicianRows]) => {
      if (active) { setSurveys(surveyRows); setTechnicians(technicianRows); }
    }).catch(requestError => { if (active) setError(requestError.message); }).finally(() => { if (active) setLoading(false); });
    return () => { active = false; };
  }, [attempt]);

  return <section className="assignment-form-card glass-panel" aria-labelledby="assignment-heading">
    <header className="assignment-form-card__heading"><div><p className="eyebrow">ASSIGNMENT DETAILS</p><h2 id="assignment-heading">Site visit details</h2><p>Match a customer site with an available technician and choose a clear visit window.</p></div><span><ShieldCheck size={19} /> Engineer authorized</span></header>
    {error && <div className="assignment-form-error" role="alert">⚠ {error}</div>}
    {loading ? <div className="assignment-form-loading" role="status">Loading customer projects and available technicians…</div> :
    <ValidatedForm className="assignment-form" onSubmit={async event => {
      event.preventDefault();
      if (saving) return;
      setSelectionTouched(true); setScheduleTouched(true);
      if (!surveyId) { surveyRef.current?.scrollIntoView?.({ block: 'center', behavior: 'smooth' }); surveyRef.current?.focus({ preventScroll: true }); return; }
      if (!technicianId) { technicianRef.current?.scrollIntoView?.({ block: 'center', behavior: 'smooth' }); technicianRef.current?.focus({ preventScroll: true }); return; }
      const validationMessage = scheduleValidation(visitDate, visitTime);
      if (validationMessage) { const target = !visitDate ? dateRef : timeRef; target.current?.scrollIntoView?.({ block: 'center', behavior: 'smooth' }); target.current?.focus({ preventScroll: true }); return; }
      setSaving(true); setError('');
      try {
        const scheduledAt = visitDate && visitTime ? new Date(`${visitDate}T${visitTime}:00`).toISOString() : undefined;
        const job = await api.createFieldJob({ solarSurveyId: surveyId, technicianId, priority, ...(scheduledAt ? { scheduledAt } : {}) });
        onAssigned(job);
      } catch (requestError) { setError((requestError as Error).message); } finally { setSaving(false); }
    }}>
      <section className="assignment-form-section" aria-labelledby="assignment-project-heading">
        <div className="assignment-form-section__title"><span><ClipboardList size={18} /></span><div><h3 id="assignment-project-heading">1. Customer project</h3><p>Search by project, address, homeowner or survey reference.</p></div></div>
        <label className="assignment-field-label">Customer survey <span aria-hidden="true">*</span></label>
        <ChoiceMenu label="Customer survey" value={surveyId} placeholder={`Choose a customer site (${surveys.length} available)`} choices={surveyChoices}
          onChange={value => { setSurveyId(value); setSelectionTouched(true); }} searchable searchPlaceholder="Search project, address, homeowner or survey ID"
          emptyMessage="No customer sites match this search. Try the homeowner name or survey ID." invalid={selectionTouched && !surveyId} disabled={saving || !surveys.length} buttonRef={surveyRef} />
        {selectionTouched && !surveyId && <p className="assignment-inline-error" role="alert">Select the customer site that needs the field visit.</p>}
        {selectedSurvey && <article className="survey-picker__selection" aria-label="Selected survey details"><div className="survey-picker__selection-icon"><MapPin size={20} /></div><div className="survey-picker__selection-main"><span className="survey-picker__selection-label">Selected customer site</span><strong>{surveyTitle(selectedSurvey)}</strong>{selectedSurvey.propertyAddress && <small>{selectedSurvey.propertyAddress}</small>}</div><dl><div><dt>Homeowner</dt><dd>{selectedSurvey.customerName || 'Not provided'}</dd></div><div><dt>Survey ID</dt><dd>{selectedSurvey.id.slice(0, 8).toUpperCase()}</dd></div><div><dt>Status</dt><dd><span className={`survey-picker__status survey-picker__status--${selectedSurvey.surveyStatus?.toLocaleLowerCase() || 'unknown'}`}>{readableStatus(selectedSurvey.surveyStatus)}</span></dd></div></dl></article>}
        {!surveys.length && <p className="assignment-empty">No customer surveys are currently available.</p>}
      </section>
      <section className="assignment-form-section" aria-labelledby="assignment-technician-heading">
        <div className="assignment-form-section__title"><span><UserRound size={18} /></span><div><h3 id="assignment-technician-heading">2. Technician and priority</h3><p>Choose who will visit the site and how soon it should be handled.</p></div></div>
        <div className="assignment-form-grid assignment-form-grid--aligned"><div><label className="assignment-field-label">Field technician <span aria-hidden="true">*</span></label>
          <ChoiceMenu label="Field technician" value={technicianId} placeholder="Select an available technician" choices={technicianChoices} onChange={value => { setTechnicianId(value); setSelectionTouched(true); }} searchable searchPlaceholder="Search technician name or email" emptyMessage="No available technician matches this search." invalid={selectionTouched && !technicianId} disabled={saving || !technicians.length} buttonRef={technicianRef} />
          {selectionTouched && !technicianId && <p className="assignment-inline-error" role="alert">Select the technician responsible for this visit.</p>}</div>
          <fieldset className="assignment-priority"><legend>Priority <span aria-hidden="true">*</span></legend><div className="assignment-priority__grid">{priorityOptions.map(option => <label key={option.value} className={`assignment-priority__option assignment-priority__option--${option.value.toLocaleLowerCase()} ${priority === option.value ? 'assignment-priority__option--selected' : ''}`}><input type="radio" name="priority" value={option.value} checked={priority === option.value} disabled={saving} onChange={() => setPriority(option.value)} /><span><strong>{option.value}</strong><small>{option.note}</small></span><Check size={15} /></label>)}</div></fieldset>
        </div>{!technicians.length && <p className="assignment-empty">No active field technicians are available.</p>}
      </section>
      <section className="assignment-form-section" aria-labelledby="assignment-schedule-heading">
        <div className="assignment-form-section__title"><span><CalendarDays size={18} /></span><div><h3 id="assignment-schedule-heading">3. Visit schedule</h3><p>Optional. Add both fields when the appointment has been agreed with the homeowner.</p></div></div>
        <div className="assignment-form-grid assignment-schedule-grid"><DatePicker value={visitDate} onChange={value => { setVisitDate(value); setScheduleTouched(true); }} invalid={Boolean(scheduleError && !visitDate)} disabled={saving} buttonRef={dateRef} /><ChoiceMenu label="Arrival time" value={visitTime} placeholder="Select arrival time" choices={timeChoices} onChange={value => { setVisitTime(value); setScheduleTouched(true); }} invalid={Boolean(scheduleError && !visitTime)} disabled={saving} buttonRef={timeRef} /></div>
        <div className="assignment-schedule-help-row"><p id="visit-schedule-help" className={scheduleError ? 'assignment-schedule-error' : 'assignment-field-help'} role={scheduleError ? 'alert' : undefined}>{scheduleError ? `⚠ ${scheduleError}` : <><Clock3 size={14} /> The technician will see this appointment in the web and mobile workspace.</>}</p>{(visitDate || visitTime) && <button type="button" className="assignment-clear-schedule" onClick={() => { setVisitDate(''); setVisitTime(''); setScheduleTouched(false); }}><X size={14} /> Clear schedule</button>}</div>
      </section>
      {(selectedSurvey || selectedTechnician) && <aside className="assignment-preview" aria-label="Assignment summary"><strong>Ready to assign</strong><span>{selectedSurvey ? `${surveyTitle(selectedSurvey)} · ${selectedSurvey.customerName || 'Customer'}` : 'Select a customer survey'}</span><span>{selectedTechnician ? `${selectedTechnician.fullName} · ${priority} priority${visitDate && visitTime ? ` · ${formatVisitDate(visitDate)} at ${formatTime(visitTime)}` : ' · Schedule to be confirmed'}` : 'Select a field technician'}</span></aside>}
      <div className="assignment-form-actions"><button className="btn btn-primary" type="submit" disabled={saving}>{saving ? 'Creating assignment…' : 'Assign site visit'}</button><button className="btn btn-secondary" type="button" disabled={saving} onClick={onCancel}>Cancel</button>{error && <button className="btn btn-secondary" type="button" disabled={saving} onClick={() => setAttempt(value => value + 1)}>Reload options</button>}</div>
    </ValidatedForm>}
  </section>;
}
