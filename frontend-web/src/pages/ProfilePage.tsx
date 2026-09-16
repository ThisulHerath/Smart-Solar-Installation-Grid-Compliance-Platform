import { RecordReference } from '../components/RecordReference';
import { Link } from 'react-router-dom';
import { ArrowUpRight, Mail, Phone, ShieldCheck, UserRound } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import '../styles/profile.css';

export function ProfilePage() {
  const { user } = useAuth();
  if (!user) return null;
  const initials = user.fullName.split(' ').filter(Boolean).slice(0, 2).map(name => name[0]).join('').toUpperCase();
  const joined = new Date(user.createdAt);
  return <div className="profile-page"><header><p className="eyebrow">YOUR PERSONAL SPACE</p><h1>My profile</h1><p>Your details, your access, and your next step.</p></header>
    <div className="profile-grid"><section className="glass-panel profile-identity"><div className="profile-avatar" aria-hidden="true">{initials || <UserRound />}</div><h2>{user.fullName}</h2><p className="profile-email">{user.email}</p><div className="profile-roles">{user.roles.map(role => <span className="badge badge-emerald" key={role}>{role.replace(/_/g, ' ')}</span>)}</div><Link className="btn btn-primary" to="/dashboard">Open my workspace <ArrowUpRight size={17} /></Link></section>
      <section className="glass-panel profile-info"><h2>Personal information</h2><p>These are the details associated with your account.</p><dl><div><dt><UserRound size={16} /> Full name</dt><dd>{user.fullName}</dd></div><div><dt><Mail size={16} /> Email address</dt><dd>{user.email}</dd></div><div><dt><Phone size={16} /> Phone number</dt><dd>{user.phoneNumber || 'Not provided'}</dd></div><div><dt>Member since</dt><dd>{Number.isNaN(joined.getTime()) ? 'Not available' : joined.toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' })}</dd></div></dl><RecordReference label="User reference" value={user.id} /></section></div>
    <section className="glass-panel profile-security"><div className="profile-security-icon"><ShieldCheck size={28} /></div><div><h2>Keep your account protected</h2><p>Manage your password and account access using email verification.</p></div><Link className="btn btn-secondary" to="/account">Account & security <ArrowUpRight size={17} /></Link></section>
  </div>;
}

