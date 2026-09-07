import React from 'react';
import { Outlet } from 'react-router-dom';
import { Navbar } from './Navbar';

export const Layout: React.FC = () => {
  return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
      <Navbar />
      <main style={{ flex: 1, maxWidth: '1280px', width: '100%', margin: '0 auto', padding: '32px 24px' }}>
        <Outlet />
      </main>
      <footer style={{
        borderTop: '1px solid var(--border-color)',
        padding: '20px 24px',
        textAlign: 'center',
        fontSize: '0.8rem',
        color: 'var(--text-muted)'
      }}>
        SE3090 Software Engineering Frameworks &bull; Smart Solar Installation & Grid Compliance Platform &bull; Phase 1 Architecture
      </footer>
    </div>
  );
};
