import { FormEvent, useEffect, useMemo, useState } from 'react';
import { CheckCircle2, CircleOff, Plus, RefreshCw, Search, ShieldCheck, Users } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import {
  CreateManagedUserInput,
  ManagedUser,
  StaffRole,
  userManagementService,
} from '../services/userManagementService';
import './UserManagementPage.css';

const roleLabels: Record<string, string> = {
  ADMINISTRATOR: 'Administrator',
  SENIOR_ENGINEER: 'Senior engineer',
  FIELD_TECHNICIAN: 'Field technician',
  INVENTORY_OFFICER: 'Inventory officer',
};

const emptyDraft: CreateManagedUserInput = {
  fullName: '',
  email: '',
  password: '',
  phoneNumber: '',
  role: 'SENIOR_ENGINEER',
};

export function UserManagementPage() {
  const { user: currentUser } = useAuth();
  const [users, setUsers] = useState<ManagedUser[]>([]);
  const [search, setSearch] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [draft, setDraft] = useState<CreateManagedUserInput>(emptyDraft);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');

  const loadUsers = async () => {
    setLoading(true);
    setError('');
    try {
      setUsers(await userManagementService.list());
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Unable to load users.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { void loadUsers(); }, []);

  const filteredUsers = useMemo(() => {
    const query = search.trim().toLowerCase();
    if (!query) return users;
    return users.filter((item) =>
      [item.fullName, item.email, item.phoneNumber, ...item.roles]
        .filter(Boolean)
        .some((value) => value!.toLowerCase().includes(query)),
    );
  }, [search, users]);

  const activeUsers = users.filter((item) => item.isActive).length;

  const submit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setSaving(true);
    setError('');
    setMessage('');
    try {
      await userManagementService.create({ ...draft, phoneNumber: draft.phoneNumber?.trim() || undefined });
      setDraft(emptyDraft);
      setShowForm(false);
      setMessage('User account created and ready to sign in.');
      await loadUsers();
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Unable to create user.');
    } finally {
      setSaving(false);
    }
  };

  const changeStatus = async (managedUser: ManagedUser) => {
    setSaving(true);
    setError('');
    setMessage('');
    try {
      await userManagementService.updateStatus(managedUser.id, !managedUser.isActive);
      setMessage(`${managedUser.fullName} is now ${managedUser.isActive ? 'deactivated' : 'active'}.`);
      await loadUsers();
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Unable to update user status.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <main className="user-management-page operations-page">
      <header className="user-management-header">
        <div>
          <p className="eyebrow">ADMINISTRATION</p>
          <h1>User management</h1>
          <p>Set up staff access, review account details, and manage account availability.</p>
        </div>
        <button className="btn btn-primary" onClick={() => setShowForm((visible) => !visible)}>
          <Plus size={17} />
          {showForm ? 'Close form' : 'Add user'}
        </button>
      </header>

      {message && <p className="user-management-notice" role="status"><CheckCircle2 size={17} />{message}</p>}
      {error && <p className="user-management-error" role="alert">{error}</p>}

      {showForm && (
        <section className="user-create-panel" aria-labelledby="new-user-title">
          <div>
            <p className="eyebrow">NEW STAFF ACCOUNT</p>
            <h2 id="new-user-title">Add a team member</h2>
            <p>Choose the access role before sharing the temporary sign-in details.</p>
          </div>
          <form className="user-create-form" onSubmit={submit}>
            <label>Full name<input required placeholder="e.g. Nimal Perera" value={draft.fullName} onChange={(event) => setDraft({ ...draft, fullName: event.target.value })} /></label>
            <label>Email address<input required type="email" placeholder="e.g. nimal@smartsolar.lk" value={draft.email} onChange={(event) => setDraft({ ...draft, email: event.target.value })} /></label>
            <label>Phone number<input placeholder="e.g. +94 77 123 4567" value={draft.phoneNumber} onChange={(event) => setDraft({ ...draft, phoneNumber: event.target.value })} /></label>
            <label>Access role<select value={draft.role} onChange={(event) => setDraft({ ...draft, role: event.target.value as StaffRole })}>
              {Object.entries(roleLabels).map(([value, label]) => <option key={value} value={value}>{label}</option>)}
            </select></label>
            <label className="user-password-field">Temporary password<input required minLength={8} type="password" placeholder="At least 8 characters" value={draft.password} onChange={(event) => setDraft({ ...draft, password: event.target.value })} /></label>
            <button className="btn btn-primary" disabled={saving}>{saving ? 'Saving...' : 'Create account'}</button>
          </form>
        </section>
      )}

      <section className="user-summary-grid" aria-label="User account summary">
        <div><Users size={20} /><span>Total users</span><strong>{users.length}</strong></div>
        <div><CheckCircle2 size={20} /><span>Active accounts</span><strong>{activeUsers}</strong></div>
        <div><CircleOff size={20} /><span>Inactive accounts</span><strong>{users.length - activeUsers}</strong></div>
      </section>

      <section className="user-access-guide" aria-label="Available staff roles">
        <div><ShieldCheck size={19} /><span>Access roles</span><p>Accounts are created with one focused staff responsibility.</p></div>
        {Object.entries(roleLabels).map(([role, label]) => <span key={role}>{label}</span>)}
      </section>

      <section className="user-directory-panel">
        <div className="user-directory-heading">
          <div><h2>Team directory</h2><p>{filteredUsers.length} account{filteredUsers.length === 1 ? '' : 's'} shown</p></div>
          <div className="user-directory-actions">
            <label className="user-search"><Search size={17} /><input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Search name, email, or role" /></label>
            <button className="user-refresh" type="button" onClick={() => void loadUsers()} disabled={loading} aria-label="Refresh users"><RefreshCw size={17} /></button>
          </div>
        </div>

        {loading ? <p className="user-directory-empty">Loading user accounts...</p> : filteredUsers.length === 0 ? <p className="user-directory-empty">No user accounts match this search.</p> : (
          <div className="user-directory-table"><table><thead><tr><th>Team member</th><th>Access role</th><th>Contact</th><th>Created</th><th>Account state</th><th>Action</th></tr></thead><tbody>
            {filteredUsers.map((managedUser) => {
              const isCurrentUser = managedUser.id === currentUser?.id;
              return <tr key={managedUser.id}><td><div className="user-avatar">{managedUser.fullName.split(' ').map((part) => part[0]).slice(0, 2).join('')}</div><div><strong>{managedUser.fullName}</strong><small>{managedUser.email}</small></div></td><td><div className="user-role-list">{managedUser.roles.map((role) => <span key={role} className={`user-role user-role-${role.toLowerCase().replace(/_/g, '-')}`}><ShieldCheck size={13} />{roleLabels[role] || role}</span>)}</div></td><td>{managedUser.phoneNumber || 'Not provided'}</td><td>{new Intl.DateTimeFormat('en-LK', { dateStyle: 'medium' }).format(new Date(managedUser.createdAt))}</td><td><span className={`user-state ${managedUser.isActive ? 'active' : 'inactive'}`}>{managedUser.isActive ? 'Active' : 'Deactivated'}</span></td><td><button className={managedUser.isActive ? 'user-deactivate' : 'user-activate'} onClick={() => void changeStatus(managedUser)} disabled={saving || isCurrentUser}>{managedUser.isActive ? 'Deactivate' : 'Activate'}</button>{isCurrentUser && <small className="user-current-account">Current account</small>}</td></tr>;
            })}
          </tbody></table></div>
        )}
      </section>
    </main>
  );
}
