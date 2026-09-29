import { Box, ClipboardList, FileCheck2, FileText, HardHat, LayoutDashboard, MapPinned, Sun, UserRoundPlus, UsersRound } from 'lucide-react';
import { Link, NavLink } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export function AdminSidebar() {
  const { user } = useAuth();

  if (!user) return null;

  const links = [
    { to: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
    { to: '/surveys', label: 'Surveys', icon: ClipboardList },
    { to: '/field-jobs/assign', label: 'Assign technician', icon: UserRoundPlus },
    { to: '/field-jobs', label: 'Field jobs', icon: HardHat },
    { to: '/proposals', label: 'Proposals', icon: FileText },
    { to: '/proposals/pending', label: 'Approvals', icon: FileCheck2 },
    { to: '/customer-locations', label: 'Customer locations', icon: MapPinned },
    { to: '/inventory', label: 'Inventory', icon: Box },
    { to: '/users', label: 'User management', icon: UsersRound },
  ];

  return (
    <aside className="admin-sidebar" aria-label="Administrator navigation">
      <Link className="admin-sidebar-brand" to="/dashboard">
        <Sun size={27} />
        <span>smart <b>solar</b></span>
      </Link>

      <nav className="admin-sidebar-nav">
        {links.map(({ to, label, icon: Icon }) => (
          <NavLink
            key={to}
            to={to}
            end={to === '/dashboard' || to === '/field-jobs' || to === '/proposals'}
            className={({ isActive }) => `admin-sidebar-link${isActive ? ' active' : ''}`}
          >
            <Icon size={20} />
            <span>{label}</span>
          </NavLink>
        ))}
      </nav>

    </aside>
  );
}
