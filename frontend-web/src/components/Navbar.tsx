import React from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { Sun, LogOut, Shield, User as UserIcon } from './Icons';

export const Navbar: React.FC = () => {
  const { user, logout } = useAuth();

  return (
    <header style={{
      borderBottom: '1px solid var(--border-color)',
      background: 'rgba(10, 13, 20, 0.8)',
      backdropFilter: 'blur(12px)',
      position: 'sticky',
      top: 0,
      zIndex: 50
    }}>
      <div style={{
        maxWidth: '1280px',
        margin: '0 auto',
        padding: '14px 24px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        flexWrap: 'wrap',
        gap: '16px'
      }}>
        {/* Brand */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <div style={{
            width: '36px',
            height: '36px',
            borderRadius: '10px',
            background: 'linear-gradient(135deg, #10b981 0%, #f59e0b 100%)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            boxShadow: '0 0 15px rgba(16, 185, 129, 0.3)'
          }}>
            <Sun size={20} color="#ffffff" />
          </div>
          <div>
            <div style={{ fontWeight: 800, fontSize: '1.05rem', letterSpacing: '-0.02em' }}>
              SMART SOLAR <span style={{ color: 'var(--solar-emerald)' }}>PLATFORM</span>
            </div>
            <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)', fontWeight: 500 }}>
              Solar planning and field operations
            </div>
          </div>
        </div>

        {/* Navigation & User Status / Actions */}
        {user ? (
          <div style={{ display: 'flex', alignItems: 'center', gap: '24px', flexWrap: 'wrap' }}>
            <nav style={{ display: 'flex', gap: '16px', fontSize: '0.9rem', fontWeight: 600, flexWrap: 'wrap' }}>
              {user.roles.some(role => ['ADMINISTRATOR', 'INVENTORY_OFFICER', 'SENIOR_ENGINEER'].includes(role)) && <Link to="/inventory" style={{ color: 'var(--solar-emerald)' }}>Inventory</Link>}
              <Link to="/" style={{ color: 'var(--text-primary)', textDecoration: 'none' }}>Dashboard</Link>
              <Link to="/account" style={{ color: 'var(--text-primary)', textDecoration: 'none' }}>Account & security</Link>
              {(user.roles?.includes('ADMINISTRATOR') || user.roles?.includes('SENIOR_ENGINEER')) && (
                <>
                  <Link to="/surveys" style={{ color: 'var(--solar-emerald)', textDecoration: 'none' }}>Staff Surveys</Link>
                  <Link to="/field-jobs" style={{ color: 'var(--solar-cyan)', textDecoration: 'none' }}>Field Operations</Link>
                  <Link to="/proposals" style={{ color: '#8b5cf6', textDecoration: 'none' }}>Proposals</Link>
                  <Link to="/proposals/pending" style={{ color: '#f59e0b', textDecoration: 'none' }}>Pending Approvals</Link>
                </>
              )}
            </nav>

            <div style={{ display: 'flex', alignItems: 'center', gap: '16px', flexWrap: 'wrap', maxWidth: '100%' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <div style={{
                  width: '32px',
                  height: '32px',
                  borderRadius: '50%',
                  background: 'rgba(255, 255, 255, 0.08)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center'
                }}>
                  <UserIcon size={16} color="var(--text-secondary)" />
                </div>
                <div style={{ display: 'flex', flexDirection: 'column' }}>
                  <span style={{ fontSize: '0.85rem', fontWeight: 600 }}>{user.fullName}</span>
                  <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>{user.email}</span>
                </div>
              </div>

              <div style={{ display: 'flex', gap: '6px' }}>
                {user.roles.map(r => (
                  <span key={r} className="badge badge-emerald">
                    <Shield size={11} /> {r}
                  </span>
                ))}
              </div>

              <button onClick={logout} className="btn btn-secondary" style={{ padding: '6px 12px', fontSize: '0.8rem' }}>
                <LogOut size={14} /> Logout
              </button>
            </div>
          </div>
        ) : (
          <div className="badge badge-amber">
            Smart Solar · Sri Lanka
          </div>
        )}
      </div>
    </header>
  );
};
