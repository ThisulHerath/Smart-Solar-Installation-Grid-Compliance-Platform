import { Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export function AdminTopbar() {
  const { user, profilePhoto } = useAuth();

  if (!user) return null;

  const initials = user.fullName
    .split(' ')
    .filter(Boolean)
    .map((part) => part[0])
    .join('')
    .slice(0, 2)
    .toUpperCase();

  return (
    <header className="admin-topbar">
      <h1>Dashboard</h1>
      <Link className="admin-topbar-user" to="/profile" aria-label="Open profile">
        <span>{profilePhoto ? <img src={profilePhoto} alt="" /> : initials}</span>
        <div>
          <strong>{user.fullName}</strong>
          <small>System admin · Administrator</small>
        </div>
      </Link>
    </header>
  );
}
