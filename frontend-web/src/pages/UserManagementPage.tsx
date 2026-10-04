import { FormEvent, useEffect, useMemo, useRef, useState } from 'react';
import {
  Check, CheckCircle2, CircleOff, Eye, EyeOff, KeyRound, MailCheck,
  RefreshCw, Search, ShieldCheck, Trash2, UserPlus, Users, X,
} from 'lucide-react';
import { DestructiveConfirmDialog } from '../components/DestructiveConfirmDialog';
import { useAuth } from '../context/AuthContext';
import { CreateManagedUserInput, ManagedUser, StaffRole, userManagementService } from '../services/userManagementService';
import './UserManagementPage.css';

const roleDetails: Record<StaffRole, { label: string; description: string }> = {
  ADMINISTRATOR: { label: 'Administrator', description: 'Manage staff, access and the whole platform' },
  SENIOR_ENGINEER: { label: 'Senior engineer', description: 'Review surveys, field work and proposals' },
  FIELD_TECHNICIAN: { label: 'Field technician', description: 'Complete assigned site inspections' },
  INVENTORY_OFFICER: { label: 'Inventory officer', description: 'Manage equipment, pricing and reservations' },
};
const roleLabels = Object.fromEntries(Object.entries(roleDetails).map(([key, value]) => [key, value.label]));
const emptyDraft: CreateManagedUserInput = { fullName: '', email: '', password: '', phoneNumber: '', role: 'SENIOR_ENGINEER' };

type DraftField = keyof CreateManagedUserInput;
type FieldErrors = Partial<Record<DraftField, string>>;

function passwordChecks(value: string) {
  return {
    length: value.length >= 12 && value.length <= 64 && new TextEncoder().encode(value).length <= 72,
    upperLower: /[A-Z]/.test(value) && /[a-z]/.test(value),
    number: /\d/.test(value),
    symbol: /[^A-Za-z0-9]/.test(value),
  };
}

function validateDraft(draft: CreateManagedUserInput): FieldErrors {
  const errors: FieldErrors = {};
  const fullName = draft.fullName.trim();
  if (!/^[\p{L}][\p{L}\p{M} .'-]{1,99}$/u.test(fullName)) errors.fullName = 'Enter 2–100 letters. Spaces, apostrophes and hyphens are allowed.';
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(draft.email.trim()) || draft.email.trim().length > 254) errors.email = 'Enter a valid email, such as nimal@smartsolar.lk.';
  if (draft.phoneNumber?.trim()) {
    const value = draft.phoneNumber.trim();
    const digits = value.replace(/\D/g, '');
    if (!/^\+?[0-9() .-]+$/.test(value) || digits.length < 7 || digits.length > 15) errors.phoneNumber = 'Use 7–15 digits, such as +94 77 123 4567.';
  }
  const checks = passwordChecks(draft.password);
  if (!Object.values(checks).every(Boolean)) errors.password = 'Use 12–64 characters with uppercase, lowercase, number and symbol.';
  if (!roleDetails[draft.role]) errors.role = 'Select a permitted staff role.';
  return errors;
}

function generateTemporaryPassword() {
  const groups = ['ABCDEFGHJKLMNPQRSTUVWXYZ', 'abcdefghijkmnopqrstuvwxyz', '23456789', '!@#$%&*?'];
  const random = (characters: string) => characters[crypto.getRandomValues(new Uint32Array(1))[0] % characters.length];
  const characters = groups.map(random);
  const all = groups.join('');
  while (characters.length < 16) characters.push(random(all));
  for (let index = characters.length - 1; index > 0; index--) {
    const target = crypto.getRandomValues(new Uint32Array(1))[0] % (index + 1);
    [characters[index], characters[target]] = [characters[target], characters[index]];
  }
  return characters.join('');
}

function limitPhoneInput(value: string) {
  const allowed = value.replace(/[^0-9+() .-]/g, '');
  let digitCount = 0;
  return [...allowed]
    .filter(character => !/\d/.test(character) || ++digitCount <= 15)
    .join('')
    .slice(0, 24);
}

export function UserManagementPage() {
  const { user: currentUser } = useAuth();
  const formRef = useRef<HTMLFormElement>(null);
  const [users, setUsers] = useState<ManagedUser[]>([]);
  const [search, setSearch] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [draft, setDraft] = useState<CreateManagedUserInput>(emptyDraft);
  const [touched, setTouched] = useState<Partial<Record<DraftField, boolean>>>({});
  const [submitted, setSubmitted] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<ManagedUser | null>(null);
  const [deleteError, setDeleteError] = useState('');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  const errors = useMemo(() => validateDraft(draft), [draft]);
  const checks = passwordChecks(draft.password);

  const loadUsers = async () => {
    setLoading(true); setError('');
    try { setUsers(await userManagementService.list()); }
    catch (requestError) { setError(requestError instanceof Error ? requestError.message : 'Unable to load users.'); }
    finally { setLoading(false); }
  };

  useEffect(() => { void loadUsers(); }, []);

  const filteredUsers = useMemo(() => {
    const query = search.trim().toLowerCase();
    return query ? users.filter(item => [item.fullName, item.email, item.phoneNumber, ...item.roles].filter(Boolean).some(value => value!.toLowerCase().includes(query))) : users;
  }, [search, users]);
  const activeUsers = users.filter(item => item.isActive).length;
  const pendingSetup = users.filter(item => item.mustChangePassword).length;

  function updateField<K extends DraftField>(field: K, value: CreateManagedUserInput[K]) {
    setDraft(current => ({ ...current, [field]: value }));
  }

  const submit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault(); setSubmitted(true); setMessage(''); setError('');
    const firstInvalid = (Object.keys(errors) as DraftField[])[0];
    if (firstInvalid) {
      formRef.current?.querySelector<HTMLElement>(`[data-field="${firstInvalid}"]`)?.focus();
      return;
    }
    setSaving(true);
    try {
      await userManagementService.create({ ...draft, fullName: draft.fullName.trim(), email: draft.email.trim().toLowerCase(), phoneNumber: draft.phoneNumber?.trim() || undefined });
      setDraft(emptyDraft); setTouched({}); setSubmitted(false); setShowPassword(false); setShowForm(false);
      setMessage('Staff account created. Email verification and a new password are required at first sign-in.');
      await loadUsers();
    } catch (requestError) { setError(requestError instanceof Error ? requestError.message : 'Unable to create user.'); }
    finally { setSaving(false); }
  };

  const changeStatus = async (managedUser: ManagedUser) => {
    setSaving(true); setError(''); setMessage('');
    try {
      await userManagementService.updateStatus(managedUser.id, !managedUser.isActive);
      setMessage(`${managedUser.fullName} is now ${managedUser.isActive ? 'deactivated' : 'active'}.`);
      await loadUsers();
    } catch (requestError) { setError(requestError instanceof Error ? requestError.message : 'Unable to update user status.'); }
    finally { setSaving(false); }
  };

  const deleteUser = async () => {
    if (!deleteTarget) return;
    setSaving(true); setDeleteError(''); setMessage('');
    try {
      await userManagementService.delete(deleteTarget.id);
      setMessage(`${deleteTarget.fullName} was removed. Existing job and audit history remains available.`);
      setDeleteTarget(null);
      await loadUsers();
    } catch (requestError) { setDeleteError(requestError instanceof Error ? requestError.message : 'Unable to remove this user.'); }
    finally { setSaving(false); }
  };

  return <main className="user-management-page operations-page">
    <header className="user-management-header"><div><p className="eyebrow">ADMINISTRATION</p><h1>People & access</h1><p>Create secure staff accounts, monitor first sign-in setup and control workspace access.</p></div><button className="btn btn-primary" onClick={() => { setShowForm(visible => !visible); setSubmitted(false); setTouched({}); }}><UserPlus size={18} />{showForm ? 'Close form' : 'Add team member'}</button></header>
    {message && <p className="user-management-notice" role="status"><CheckCircle2 size={17} />{message}</p>}
    {error && <p className="user-management-error" role="alert">⚠ {error}</p>}

    {showForm && <section className="user-create-panel" aria-labelledby="new-user-title">
      <header className="user-create-intro"><span><UserPlus size={21} /></span><div><p className="eyebrow">NEW STAFF ACCOUNT</p><h2 id="new-user-title">Add a team member</h2><p>Create temporary access. The staff member must verify their email and replace this password before entering the workspace.</p></div><button type="button" aria-label="Close staff form" onClick={() => setShowForm(false)}><X size={18} /></button></header>
      <form ref={formRef} className="user-create-form" noValidate onSubmit={submit}>
        <fieldset className="user-form-section" aria-labelledby="personal-details-title"><div id="personal-details-title" className="user-form-section-title"><span>1</span>Personal details</div><div className="user-form-grid">
          <label>Full name <span>*</span><input data-field="fullName" required value={draft.fullName} placeholder="e.g. Nimal Perera" autoComplete="name" minLength={2} maxLength={100} aria-invalid={Boolean((submitted || touched.fullName) && errors.fullName)} aria-describedby="staff-name-error" onBlur={() => setTouched(value => ({ ...value, fullName: true }))} onChange={event => updateField('fullName', event.target.value)} />{(submitted || touched.fullName) && errors.fullName && <small id="staff-name-error" className="user-field-error">⚠ {errors.fullName}</small>}</label>
          <label>Email address <span>*</span><input data-field="email" required type="email" value={draft.email} placeholder="e.g. nimal@smartsolar.lk" autoComplete="email" maxLength={254} aria-invalid={Boolean((submitted || touched.email) && errors.email)} aria-describedby="staff-email-error" onBlur={() => setTouched(value => ({ ...value, email: true }))} onChange={event => updateField('email', event.target.value)} />{(submitted || touched.email) && errors.email && <small id="staff-email-error" className="user-field-error">⚠ {errors.email}</small>}</label>
          <label>Phone number <em>Optional · 7–15 digits</em><input data-field="phoneNumber" type="tel" inputMode="tel" maxLength={24} value={draft.phoneNumber} placeholder="e.g. +94 77 123 4567" autoComplete="tel" aria-invalid={Boolean((submitted || touched.phoneNumber) && errors.phoneNumber)} aria-describedby="staff-phone-error" onBlur={() => setTouched(value => ({ ...value, phoneNumber: true }))} onChange={event => updateField('phoneNumber', limitPhoneInput(event.target.value))} />{(submitted || touched.phoneNumber) && errors.phoneNumber && <small id="staff-phone-error" className="user-field-error">⚠ {errors.phoneNumber}</small>}</label>
        </div></fieldset>
        <fieldset className="user-form-section" aria-labelledby="access-role-title"><div id="access-role-title" className="user-form-section-title"><span>2</span>Access role</div><p className="user-form-help">Choose the role that matches this person’s day-to-day responsibility.</p><div className="user-role-picker" role="radiogroup" aria-label="Access role">{(Object.entries(roleDetails) as [StaffRole, typeof roleDetails[StaffRole]][]).map(([role, details]) => <label key={role} className={draft.role === role ? 'selected' : ''}><input data-field="role" type="radio" name="staff-role" value={role} checked={draft.role === role} onChange={() => updateField('role', role)} /><ShieldCheck size={18} /><span><strong>{details.label}</strong><small>{details.description}</small></span>{draft.role === role && <Check size={16} />}</label>)}</div></fieldset>
        <fieldset className="user-form-section" aria-labelledby="temporary-signin-title"><div id="temporary-signin-title" className="user-form-section-title"><span>3</span>Temporary sign-in</div><div className="user-password-heading"><p>The administrator shares this once. The staff member must replace it after email verification.</p><button type="button" onClick={() => { updateField('password', generateTemporaryPassword()); setShowPassword(true); setTouched(value => ({ ...value, password: true })); }}><KeyRound size={15} /> Generate secure password</button></div>
          <label className="user-password-field">Temporary password <span>*</span><div className="user-password-input"><input data-field="password" required minLength={12} type={showPassword ? 'text' : 'password'} value={draft.password} autoComplete="new-password" maxLength={64} placeholder="Create or generate a secure password" aria-invalid={Boolean((submitted || touched.password) && errors.password)} aria-describedby="staff-password-error" onBlur={() => setTouched(value => ({ ...value, password: true }))} onChange={event => updateField('password', event.target.value)} /><button type="button" aria-label={`${showPassword ? 'Hide' : 'Show'} temporary password`} onClick={() => setShowPassword(value => !value)}>{showPassword ? <EyeOff size={18} /> : <Eye size={18} />}</button></div>{(submitted || touched.password) && errors.password && <small id="staff-password-error" className="user-field-error">⚠ {errors.password}</small>}</label>
          <div className="user-password-checks" aria-label="Temporary password requirements">{[[checks.length, '12–64 characters'], [checks.upperLower, 'Uppercase and lowercase'], [checks.number, 'One number'], [checks.symbol, 'One symbol']].map(([complete, label]) => <span key={String(label)} className={complete ? 'complete' : ''}>{complete ? <Check size={13} /> : <CircleOff size={13} />}{label}</span>)}</div>
        </fieldset>
        <footer className="user-create-actions"><div><MailCheck size={17} /><span><strong>First-login protection enabled</strong><small>Email verification and a new password are required.</small></span></div><button className="btn btn-primary" disabled={saving}>{saving ? 'Creating account…' : 'Create staff account'}</button></footer>
      </form>
    </section>}

    <section className="user-summary-grid" aria-label="User account summary"><div><Users size={20} /><span>Total staff</span><strong>{users.length}</strong></div><div><CheckCircle2 size={20} /><span>Active accounts</span><strong>{activeUsers}</strong></div><div><KeyRound size={20} /><span>First login pending</span><strong>{pendingSetup}</strong></div><div><CircleOff size={20} /><span>Inactive accounts</span><strong>{users.length - activeUsers}</strong></div></section>

    <section className="user-directory-panel"><div className="user-directory-heading"><div><p className="eyebrow">TEAM DIRECTORY</p><h2>Staff access</h2><p>{filteredUsers.length} account{filteredUsers.length === 1 ? '' : 's'} shown</p></div><div className="user-directory-actions"><label className="user-search"><Search size={17} /><input value={search} onChange={event => setSearch(event.target.value)} placeholder="Search name, email, phone or role" aria-label="Search staff" />{search && <button type="button" aria-label="Clear staff search" onClick={() => setSearch('')}><X size={14} /></button>}</label><button className="user-refresh" type="button" onClick={() => void loadUsers()} disabled={loading} aria-label="Refresh users"><RefreshCw size={17} /></button></div></div>
      {loading ? <p className="user-directory-empty">Loading staff accounts…</p> : filteredUsers.length === 0 ? <p className="user-directory-empty">No staff accounts match this search.</p> : <div className="user-directory-table"><table><thead><tr><th>Team member</th><th>Access role</th><th>Security setup</th><th>Created</th><th>Account</th><th>Actions</th></tr></thead><tbody>{filteredUsers.map(managedUser => {
        const isCurrentUser = managedUser.id === currentUser?.id;
        return <tr key={managedUser.id}><td><div className="user-avatar">{managedUser.fullName.split(' ').map(part => part[0]).slice(0, 2).join('')}</div><div><strong>{managedUser.fullName}</strong><small>{managedUser.email}</small><small>{managedUser.phoneNumber || 'No phone number'}</small></div></td><td><div className="user-role-list">{managedUser.roles.map(role => <span key={role} className={`user-role user-role-${role.toLowerCase().replace(/_/g, '-')}`}><ShieldCheck size={13} />{roleLabels[role] || role}</span>)}</div></td><td><span className={`user-security-state ${managedUser.mustChangePassword ? 'pending' : 'complete'}`}>{managedUser.mustChangePassword ? <KeyRound size={13} /> : <MailCheck size={13} />}{managedUser.mustChangePassword ? 'First login pending' : managedUser.emailVerified ? 'Email verified' : 'Verification pending'}</span></td><td>{new Intl.DateTimeFormat('en-LK', { dateStyle: 'medium' }).format(new Date(managedUser.createdAt))}</td><td><span className={`user-state ${managedUser.isActive ? 'active' : 'inactive'}`}>{managedUser.isActive ? 'Active' : 'Deactivated'}</span>{isCurrentUser && <small className="user-current-account">Current account</small>}</td><td><div className="user-row-actions"><button className={managedUser.isActive ? 'user-deactivate' : 'user-activate'} onClick={() => void changeStatus(managedUser)} disabled={saving || isCurrentUser}>{managedUser.isActive ? 'Deactivate' : 'Activate'}</button><button className="user-delete" aria-label={`Delete ${managedUser.fullName}`} onClick={() => { setDeleteTarget(managedUser); setDeleteError(''); }} disabled={saving || isCurrentUser}><Trash2 size={15} /></button></div></td></tr>;
      })}</tbody></table></div>}
    </section>

    <DestructiveConfirmDialog open={Boolean(deleteTarget)} title="Delete staff account?" subject={deleteTarget && `${deleteTarget.fullName} · ${deleteTarget.email}`} confirmLabel="Delete account" pendingLabel="Deleting account…" pending={saving} error={deleteError} onCancel={() => { setDeleteTarget(null); setDeleteError(''); }} onConfirm={() => void deleteUser()}><p>This immediately blocks sign-in and removes the account from the directory. Existing job assignments and audit history will be preserved.</p></DestructiveConfirmDialog>
  </main>;
}
