import { Boxes, ClipboardCheck, ClipboardList, FileCheck2, FileText, HardHat, LayoutDashboard, MapPinned, PackageCheck, Sun, UserRoundPlus } from 'lucide-react';
import { Link, NavLink } from 'react-router-dom';

type StaffRole = 'SENIOR_ENGINEER' | 'FIELD_TECHNICIAN' | 'INVENTORY_OFFICER';

const roleSettings: Record<StaffRole, { label: string; className: string; links: { to: string; label: string; icon: typeof LayoutDashboard }[] }> = {
  SENIOR_ENGINEER: {
    label: 'Engineering workspace',
    className: 'role-sidebar--engineer',
    links: [
      { to: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
      { to: '/surveys', label: 'Surveys', icon: ClipboardList },
      { to: '/field-jobs/assign', label: 'Assign technician', icon: UserRoundPlus },
      { to: '/field-jobs', label: 'Field jobs', icon: HardHat },
      { to: '/proposals', label: 'Proposals', icon: FileText },
      { to: '/proposals/pending', label: 'Approvals', icon: FileCheck2 },
      { to: '/inventory', label: 'Inventory', icon: Boxes },
      { to: '/customer-locations', label: 'Customer locations', icon: MapPinned },
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
      { to: '/inventory', label: 'Inventory overview', icon: Boxes },
      { to: '/inventory#catalog', label: 'Stock catalogue', icon: ClipboardList },
      { to: '/inventory#requests', label: 'Engineer requests', icon: ClipboardCheck },
      { to: '/inventory#reservations', label: 'Reservations', icon: PackageCheck },
    ],
  },
};

export function RoleSidebar({ role, open = false, onNavigate }: { role: StaffRole; open?: boolean; onNavigate?: () => void }) {
  const settings = roleSettings[role];

  return (
    <aside id="workspace-sidebar" className={`admin-sidebar role-sidebar ${settings.className}${open ? ' is-open' : ''}`} aria-label={`${settings.label} navigation`}>
      <Link className="admin-sidebar-brand" to="/dashboard" onClick={onNavigate}>
        <Sun size={27} />
        <span>smart <b>solar</b></span>
      </Link>
      <p className="role-sidebar-label">{settings.label}</p>
      <nav className="admin-sidebar-nav">
        {settings.links.map(({ to, label, icon: Icon }) => {
          if (to.startsWith('/inventory')) {
            const [pathname, hash] = to.split('#');
            const active = window.location.pathname === pathname && (hash ? window.location.hash === `#${hash}` : !window.location.hash);
            return (
              <Link key={to} to={to} className={`admin-sidebar-link${active ? ' active' : ''}`} onClick={onNavigate}>
                <Icon size={20} />
                <span>{label}</span>
              </Link>
            );
          }

          return (
            <NavLink key={to} to={to} end={to === '/dashboard' || to === '/field-jobs' || to === '/proposals' || to === '/inventory'} className={({ isActive }) => `admin-sidebar-link${isActive ? ' active' : ''}`} onClick={onNavigate}>
              <Icon size={20} />
              <span>{label}</span>
            </NavLink>
          );
        })}
      </nav>
    </aside>
  );
}
