import { ReactNode } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Search } from 'lucide-react';
import { Sun } from './Icons';
import '../styles/account.css';
import '../styles/auth-shell.css';

export function AuthShell({ children }: { children: ReactNode }) {
  const location = useLocation();
  const isRegister = location.pathname === '/register';
  const formCard = (
    <div className={`auth-form-card${isRegister ? ' register-card' : ''}`}>
      <Link className="auth-card-close" to="/" aria-label="Close">&times;</Link>
      <div className="auth-form-content">{children}</div>
    </div>
  );
  const visual = (
    <aside className={`auth-visual${isRegister ? ' auth-visual--register' : ''}`} aria-hidden="true">
      <span className="auth-visual-sun" />
      <span className="auth-visual-panels" />
      <span className="auth-visual-horizon" />
      <div className="auth-visual-caption">
        <p>From roof survey to grid connection.</p>
        <ol>
          <li>Site survey</li>
          <li>Engineered proposal</li>
          <li>Utility approval</li>
        </ol>
        <small>Built for rooftop solar in Sri Lanka.</small>
      </div>
    </aside>
  );

  return (
    <main className={`auth-shell${isRegister ? ' auth-shell--register' : ' auth-shell--login'}`}>
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
        </nav>

        <div className="auth-home-tools"><Search size={24} aria-hidden="true" /><Link to={isRegister ? '/login' : '/register'}>{isRegister ? 'Login' : 'Register'}</Link></div>
      </header>

      <section className="auth-form-panel" aria-label={isRegister ? 'Register' : 'Login'}>
        <div className="auth-card-frame">
          {formCard}
          {visual}
        </div>
      </section>
    </main>
  );
}
