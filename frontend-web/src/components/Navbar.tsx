import { useState } from 'react';
import { Link, NavLink, useLocation } from 'react-router-dom';
import { Sun, LogOut, LayoutDashboard, ClipboardList, HardHat, FileText, FileCheck2, Package, Menu, X } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { LogoutConfirmDialog } from './LogoutConfirmDialog';
import { NotificationBell } from './NotificationBell';
import '../styles/navigation.css';
import '../styles/member-home-nav.css';

export const Navbar = () => {
  const { user: authUser, logout, profilePhoto } = useAuth();
  const user = authUser as NonNullable<typeof authUser>;
  const location = useLocation();
  const [expanded, setExpanded] = useState(false);
  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);
  const engineer = user?.roles.some(role => ['ADMINISTRATOR', 'SENIOR_ENGINEER'].includes(role));
  const inventory = user?.roles.some(role => ['ADMINISTRATOR', 'SENIOR_ENGINEER', 'INVENTORY_OFFICER'].includes(role));
  const initials = user?.fullName.split(' ').filter(Boolean).slice(0, 2).map(part => part[0]).join('').toUpperCase() || '';
  const userRole = user?.roles[0]?.replace(/_/g, ' ').toLowerCase().replace(/\b\w/g, letter => letter.toUpperCase()) || 'Member';
  const profileRoute = location.pathname === '/profile' || location.pathname === '/account';
  const notificationRoute = location.pathname === '/notifications';
  const activeNav = profileRoute
    ? null
    : notificationRoute
      ? null
    : location.pathname !== '/'
      ? 'projects'
      : location.hash === '#services'
        ? 'services'
        : location.hash === '#process'
          ? 'process'
          : 'home';

  const handleConfirmLogout = () => {
    setShowLogoutConfirm(false);
    logout();
  };

  return (
    <>
      <header className="member-home-nav">
        <Link className="member-home-brand" to="/" aria-label="Smart Solar home">
          <Sun size={24} />
            <span>smart</span>
            <b>solar</b>
        </Link>
        <nav aria-label="Main navigation"><Link className={activeNav === 'home' ? 'is-active' : ''} to="/">Home</Link><Link className={activeNav === 'services' ? 'is-active' : ''} to="/#services">Services</Link><Link className={activeNav === 'process' ? 'is-active' : ''} to="/#process">How it works</Link><Link className={activeNav === 'projects' ? 'is-active' : ''} to="/dashboard">{user ? 'Dashboard' : 'Projects'}</Link></nav>
        {user ? <div className="member-home-account"><NotificationBell /><Link to="/profile" className={`member-home-user${profileRoute ? ' is-active' : ''}`} aria-current={profileRoute ? 'page' : undefined} aria-label="Open my profile"><span className="member-home-avatar">{profilePhoto ? <img src={profilePhoto} alt="" /> : initials}</span><span><strong>{user.fullName}</strong><small>{userRole}</small></span></Link><button className="member-home-logout" type="button" onClick={() => setShowLogoutConfirm(true)}><LogOut size={17} /> Logout</button></div> : <Link className="member-home-login" to="/login">Login</Link>}
      </header>

      {user && false && <>
      <header className="app-header">
        <div className="app-header-inner">
          <div className="app-header-top">
            <Link className="app-brand" to="/" aria-label="Smart Solar home">
              <span className="app-brand-icon"><Sun size={24} /></span>
              <span>smart<span className="app-brand-light">solar.</span><small>YOUR SOLAR WORKSPACE</small></span>
            </Link>
            {user ? (
              <div className="app-account">
                    <nav className="workspace-public-nav" aria-label="Main navigation">
                      <Link to="/">Home</Link>
                      <Link to="/dashboard">Projects</Link>
                      <Link to="/profile">Gallery</Link>
                      <Link to="/account">Contact</Link>
                    </nav>
                <Link to="/profile" className="app-user" aria-label="My profile">
                  <span className="app-user-avatar">{profilePhoto ? <img src={profilePhoto ?? undefined} alt="" /> : initials}</span>
                  <span className="app-user-details">
                    <strong>{user?.fullName}</strong>
                    <small>{user.roles.map(role => role.replace(/_/g, ' ').toLowerCase()).join(' · ')}</small>
                  </span>
                </Link>
                <span className="app-account-divider" />
                <button
                  className="app-logout"
                  aria-label="Logout"
                  onClick={() => setShowLogoutConfirm(true)}
                >
                  <LogOut size={16} />
                  <span>Logout</span>
                </button>
                <button
                  className="app-menu-toggle"
                  aria-label={expanded ? 'Close navigation' : 'Open navigation'}
                  aria-expanded={expanded}
                  aria-controls="app-navigation"
                  onClick={() => setExpanded(!expanded)}
                >
                  {expanded ? <X size={20} /> : <Menu size={20} />}
                </button>
              </div>
            ) : (
              <Link className="btn btn-primary" to="/login">Log in</Link>
            )}
          </div>
          {user && false && (
            <nav id="app-navigation" className={`app-navigation ${expanded ? 'expanded' : ''}`} aria-label="Workspace navigation">
              {[
                { to: '/dashboard', label: 'Overview', icon: LayoutDashboard, show: true },
                { to: '/surveys', label: 'Surveys', icon: ClipboardList, show: engineer },
                { to: '/field-jobs', label: 'Field operations', icon: HardHat, show: engineer },
                { to: '/proposals', label: 'Proposals', icon: FileText, show: engineer },
                { to: '/proposals/pending', label: 'Approvals', icon: FileCheck2, show: engineer },
                { to: '/inventory', label: 'Inventory', icon: Package, show: inventory },
              ].filter(item => item.show).map(({ to, label, icon: Icon }) => (
                <NavLink
                  key={to}
                  to={to}
                  end={to === '/proposals'}
                  className={({ isActive }) => `app-nav-link${isActive ? ' active' : ''}`}
                  onClick={() => setExpanded(false)}
                >
                  <Icon size={16} />
                  <span>{label}</span>
                </NavLink>
              ))}
              <NavLink
                to="/profile"
                className={({ isActive }) => `app-nav-link app-profile-link${isActive ? ' active' : ''}`}
                onClick={() => setExpanded(false)}
              >
                My profile <span>↗</span>
              </NavLink>
            </nav>
          )}
        </div>
      </header>
      </>}

      {showLogoutConfirm && <LogoutConfirmDialog onCancel={() => setShowLogoutConfirm(false)} onConfirm={handleConfirmLogout} />}
    </>
  );
};
