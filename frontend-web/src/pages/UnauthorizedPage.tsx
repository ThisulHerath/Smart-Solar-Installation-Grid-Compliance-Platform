import React from 'react';
import { Link } from 'react-router-dom';
import { ShieldAlert, ArrowLeft } from '../components/Icons';

export const UnauthorizedPage: React.FC = () => {
  return (
    <div style={{
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      minHeight: '60vh',
      textAlign: 'center'
    }}>
      <div className="glass-panel" style={{ maxWidth: '440px', padding: '36px' }}>
        <div style={{
          width: '52px',
          height: '52px',
          borderRadius: '50%',
          background: 'rgba(239, 68, 68, 0.15)',
          display: 'inline-flex',
          alignItems: 'center',
          justifyContent: 'center',
          marginBottom: '16px'
        }}>
          <ShieldAlert size={28} color="#ef4444" />
        </div>
        <h2 style={{ fontSize: '1.4rem', marginBottom: '8px' }}>403 - Access Denied</h2>
        <p style={{ color: 'var(--text-secondary)', fontSize: '0.875rem', marginBottom: '24px' }}>
          Your user account does not possess the required role permissions to access this specific platform resource.
        </p>
        <Link to="/" className="btn btn-primary" style={{ display: 'inline-flex' }}>
          <ArrowLeft size={16} /> Return to Dashboard
        </Link>
      </div>
    </div>
  );
};
