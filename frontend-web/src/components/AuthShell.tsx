import { ReactNode } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Search } from 'lucide-react';
import { Sun } from './Icons';
import '../styles/account.css';
import '../styles/auth-home-nav.css';

export function AuthShell({ children }: { children: ReactNode }) {
  const location = useLocation();
  const isRegister = location.pathname === '/register';

  return (
    <main className="auth-shell">
      <header className="auth-home-navbar">
        <Link className="auth-home-brand" to="/" aria-label="Smart Solar home">
          <Sun size={27} />
          <span>smart <b>solar</b></span>
        </Link>

        <nav className="auth-home-links" aria-label="Public navigation">
          <Link to="/">Home</Link>
          <Link to="/#services">Services</Link>
          <Link to="/#projects">Projects</Link>
          <Link to="/#process">How it works</Link>
          <Link to="/login">Log in</Link>
        </nav>

        <div className="auth-home-tools"><Search size={24} aria-hidden="true" /><Link to={isRegister ? '/login' : '/register'}>{isRegister ? 'Login' : 'Register'}</Link></div>
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
