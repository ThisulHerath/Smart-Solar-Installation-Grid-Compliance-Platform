import { ReactNode } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Search } from 'lucide-react';
import { Sun } from './Icons';
import solarScene from '../../images/hero-solar.jpg';
import '../styles/account.css';
import '../styles/auth-home-nav.css';

export function AuthShell({ children }: { children: ReactNode }) {
  const location = useLocation();
  const isRegister = location.pathname === '/register';

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
        <div className={`auth-form-card${isRegister ? ' register-card' : ''}`}>
          <Link className="auth-card-close" to="/" aria-label="Close">×</Link>
          <div className="auth-form-content">{children}</div>
        </div>
        <aside className="auth-visual" aria-hidden="true">
          <img src={solarScene} alt="" />
        </aside>
      </section>
    </main>
  );
}
