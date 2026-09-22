import { Box, ClipboardList, FileCheck2, FileText, HardHat, LayoutDashboard, LogOut, Sun } from 'lucide-react';
import { Link, NavLink } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

type StaffRole = 'SENIOR_ENGINEER' | 'FIELD_TECHNICIAN' | 'INVENTORY_OFFICER';

const roleSettings: Record<StaffRole, { label: string; className: string; links: { to: string; label: string; icon: typeof LayoutDashboard }[] }> = {
  SENIOR_ENGINEER: {
    label: 'Engineering workspace',
    className: 'role-sidebar--engineer',
    links: [
      { to: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
      { to: '/surveys', label: 'Surveys', icon: ClipboardList },
      { to: '/field-jobs', label: 'F Operations', icon: HardHat },
      { to: '/proposals', label: 'Proposals', icon: FileText },
      { to: '/proposals/pending', label: 'Approvals', icon: FileCheck2 },
    ],
  },
  FIELD_TECHNICIAN: {
    label: 'Field workspace',
    className: 'role-sidebar--technician',
    links: [
      { to: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
      { to: '/technician-jobs', label: 'My assignments', icon: HardHat },
    ],
  },
  INVENTORY_OFFICER: {
    label: 'Inventory workspace',
    className: 'role-sidebar--inventory',
    links: [
      { to: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
      { to: '/inventory', label: 'Inventory', icon: Box },
    ],
  },
};

export function RoleSidebar({ role }: { role: StaffRole }) {
  const { logout } = useAuth();
  const settings = roleSettings[role];

  return (
    <aside className={`admin-sidebar role-sidebar ${settings.className}`} aria-label={`${settings.label} navigation`}>
      <Link className="admin-sidebar-brand" to="/dashboard">
        <Sun size={27} />
        <span>smart <b>solar</b></span>
      </Link>
      <p className="role-sidebar-label">{settings.label}</p>
      <nav className="admin-sidebar-nav">
        {settings.links.map(({ to, label, icon: Icon }) => (
          <NavLink key={to} to={to} end={to === '/dashboard'} className={({ isActive }) => `admin-sidebar-link${isActive ? ' active' : ''}`}>
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
