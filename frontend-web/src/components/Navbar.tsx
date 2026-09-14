import { useState } from 'react';
import { Link, NavLink } from 'react-router-dom';
import { Sun, LogOut, LayoutDashboard, ClipboardList, HardHat, FileText, FileCheck2, Package, Menu, X } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import '../styles/navigation.css';

export const Navbar = () => {
  const { user, logout } = useAuth();
  const [expanded, setExpanded] = useState(false);
  const engineer = user?.roles.some(role => ['ADMINISTRATOR', 'SENIOR_ENGINEER'].includes(role));
  const inventory = user?.roles.some(role => ['ADMINISTRATOR', 'SENIOR_ENGINEER', 'INVENTORY_OFFICER'].includes(role));
  const initials = user?.fullName.split(' ').filter(Boolean).slice(0, 2).map(part => part[0]).join('').toUpperCase();
  return <header className="app-header"><div className="app-header-inner">
    <div className="app-header-top"><Link className="app-brand" to="/" aria-label="Smart Solar home"><span className="app-brand-icon"><Sun size={24} /></span><span>smart<span className="app-brand-light">solar.</span><small>YOUR SOLAR WORKSPACE</small></span></Link>
      {user ? <div className="app-account"><Link to="/profile" className="app-user" aria-label="My profile"><span className="app-user-avatar">{initials}</span><span className="app-user-details"><strong>{user.fullName}</strong><small>{user.roles.map(role => role.replace(/_/g, ' ').toLowerCase()).join(' · ')}</small></span></Link><span className="app-account-divider" /><button className="app-logout" onClick={logout}><LogOut size={16} /><span>Logout</span></button><button className="app-menu-toggle" aria-label={expanded ? 'Close navigation' : 'Open navigation'} aria-expanded={expanded} aria-controls="app-navigation" onClick={() => setExpanded(!expanded)}>{expanded ? <X size={20} /> : <Menu size={20} />}</button></div> : <Link className="btn btn-primary" to="/login">Log in</Link>}
    </div>
    {user && <nav id="app-navigation" className={`app-navigation ${expanded ? 'expanded' : ''}`} aria-label="Workspace navigation">
      {[
        { to: '/dashboard', label: 'Overview', icon: LayoutDashboard, show: true },
        { to: '/surveys', label: 'Surveys', icon: ClipboardList, show: engineer },
        { to: '/field-jobs', label: 'Field operations', icon: HardHat, show: engineer },
        { to: '/proposals', label: 'Proposals', icon: FileText, show: engineer },
        { to: '/proposals/pending', label: 'Approvals', icon: FileCheck2, show: engineer },
        { to: '/inventory', label: 'Inventory', icon: Package, show: inventory },
      ].filter(item => item.show).map(({ to, label, icon: Icon }) => <NavLink key={to} to={to} end={to === '/proposals'} className={({ isActive }) => `app-nav-link${isActive ? ' active' : ''}`} onClick={() => setExpanded(false)}><Icon size={16} /><span>{label}</span></NavLink>)}
      <NavLink to="/profile" className={({ isActive }) => `app-nav-link app-profile-link${isActive ? ' active' : ''}`} onClick={() => setExpanded(false)}>My profile <span>↗</span></NavLink>
    </nav>}
  </div></header>;
};
