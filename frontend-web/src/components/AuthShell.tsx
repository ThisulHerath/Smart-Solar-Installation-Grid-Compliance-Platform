import { ReactNode } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Sun } from './Icons';
import '../styles/account.css';

export function AuthShell({ children }: { children: ReactNode }) {
  const location = useLocation();
  const isRegister = location.pathname === '/register';

  return (
    <main className="auth-shell">
      <header className="auth-nav">
        <Link className="auth-brand" to="/" aria-label="Smart Solar home">
          <span className="auth-brand-mark"><Sun size={25} /></span>
          <span className="auth-brand-name">smart<span>solar.</span></span>
        </Link>

        <nav className="auth-links" aria-label="Public navigation">
          <Link to="/">Home</Link>
          <Link to="/">Projects</Link>
          <Link to="/">Gallery</Link>
          <Link to="/">Contact</Link>
        </nav>

        <Link className="auth-nav-action" to={isRegister ? '/login' : '/register'}>
          {isRegister ? 'Sign in' : 'Register'}
        </Link>
      </header>

      <section className="auth-form-panel" aria-label={isRegister ? 'Register' : 'Login'}>
        <div className={`auth-form-card${isRegister ? ' register-card' : ''}`}>
          <Link className="auth-card-close" to="/" aria-label="Close">×</Link>
          <div className="auth-form-content">{children}</div>
        </div>
      </section>
    </main>
  );
}
