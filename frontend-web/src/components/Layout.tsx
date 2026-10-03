import React from 'react';
import { Outlet, useLocation } from 'react-router-dom';
import { Navbar } from './Navbar';
import { useAuth } from '../context/AuthContext';
import { AdminSidebar } from './AdminSidebar';
import { RoleSidebar } from './RoleSidebar';
import { WorkspaceFooter } from './WorkspaceFooter';

export const Layout: React.FC = () => {
  const { user } = useAuth();
  const location = useLocation();
  const administrator = user?.roles.includes('ADMINISTRATOR');
  const staffRole = user?.roles.includes('SENIOR_ENGINEER')
    ? 'SENIOR_ENGINEER'
    : user?.roles.includes('FIELD_TECHNICIAN')
      ? 'FIELD_TECHNICIAN'
      : user?.roles.includes('INVENTORY_OFFICER')
        ? 'INVENTORY_OFFICER'
        : null;
  const profileRoute =
    location.pathname === '/profile' ||
    location.pathname === '/account' ||
    location.pathname === '/notifications';

  return (
    <div className={`workspace-shell${administrator || staffRole ? ' admin-layout' : ''}${staffRole && !administrator ? ' staff-layout' : ''}`} style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
      <Navbar />
      {administrator || staffRole ? (
        <div className={`admin-route-shell${profileRoute ? ' profile-route' : ''}`}>
          {administrator ? <AdminSidebar /> : <RoleSidebar role={staffRole!} />}
          <main className="admin-route-content"><Outlet /></main>
        </div>
      ) : (
        <main style={{ flex: 1, maxWidth: '1280px', width: '100%', margin: '0 auto', padding: '32px 24px' }}>
          <Outlet />
        </main>
      )}
      <WorkspaceFooter />
    </div>
  );
};
