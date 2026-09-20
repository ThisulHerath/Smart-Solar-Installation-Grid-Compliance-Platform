import { Box, ClipboardList, FileCheck2, FileText, HardHat, LayoutDashboard, LogOut, ShieldCheck } from 'lucide-react';
import { Link, NavLink } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export function AdminSidebar() {
  const { user, logout } = useAuth();

  if (!user) return null;

  const links = [
    { to: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
    { to: '/surveys', label: 'Surveys', icon: ClipboardList },
    { to: '/field-jobs', label: 'F Operations', icon: HardHat },
    { to: '/proposals', label: 'Proposals', icon: FileText },
    { to: '/proposals/pending', label: 'Approvals', icon: FileCheck2 },
    { to: '/inventory', label: 'Inventory', icon: Box },
  ];

  return (
    <aside className="admin-sidebar" aria-label="Administrator navigation">
      <Link className="admin-sidebar-brand" to="/dashboard">
        <ShieldCheck size={30} />
        <strong>SOLAR</strong>
      </Link>

      <nav className="admin-sidebar-nav">
        {links.map(({ to, label, icon: Icon }) => (
          <NavLink
            key={to}
            to={to}
            end={to === '/dashboard'}
            className={({ isActive }) => `admin-sidebar-link${isActive ? ' active' : ''}`}
          >
            <Icon size={20} />
            <span>{label}</span>
          </NavLink>
        ))}
      </nav>

      <button className="admin-sidebar-logout" type="button" onClick={logout}>
        <LogOut size={20} />
        <span>Log out</span>
      </button>
    </aside>
  );
}
