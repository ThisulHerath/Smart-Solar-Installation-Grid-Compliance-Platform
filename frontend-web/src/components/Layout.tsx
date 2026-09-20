import React from 'react';
import { Outlet, useLocation } from 'react-router-dom';
import { Navbar } from './Navbar';
import { useAuth } from '../context/AuthContext';
import { AdminSidebar } from './AdminSidebar';
import { AdminTopbar } from './AdminTopbar';

export const Layout: React.FC = () => {
  const { user } = useAuth();
  const location = useLocation();
  const administrator = user?.roles.includes('ADMINISTRATOR');
  const profileRoute =
    location.pathname === '/profile' ||
    location.pathname === '/account';

  return (
    <div className={`workspace-shell${administrator ? ' admin-layout' : ''}`} style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
      <Navbar />
      {administrator ? (
        <div className={`admin-route-shell${profileRoute ? ' profile-route' : ''}`}>
          {!profileRoute && <AdminSidebar />}
          <main className="admin-route-content"><AdminTopbar /><Outlet /></main>
        </div>
      ) : (
        <main style={{ flex: 1, maxWidth: '1280px', width: '100%', margin: '0 auto', padding: '32px 24px' }}>
          <Outlet />
        </main>
      )}
      <footer style={{
        borderTop: '1px solid var(--border-color)',
        padding: '20px 24px',
        textAlign: 'center',
        fontSize: '0.8rem',
        color: 'var(--text-muted)'
      }}>
        Smart Solar &bull; Sri Lanka &bull; Rooftop solar planning
      </footer>
    </div>
  );
};
