import { ReactNode } from 'react';
import { ArrowUpRight, Search } from 'lucide-react';
import { Link, useLocation } from 'react-router-dom';

import { Sun } from './Icons';

import '../styles/account.css';
import '../styles/auth-modern.css';

export function AuthShell({
  children,
}: {
  children: ReactNode;
}) {
  const location = useLocation();

  const isRegister = location.pathname === '/register';

  const formCard = (
    <div
      className={`auth-form-card ${
        isRegister ? 'register-card' : 'login-card'
      }`}
    >
      <Link
        className="auth-card-close"
        to="/"
        aria-label="Back to home"
      >
        ×
      </Link>

      <div className="auth-form-content">
        {children}
      </div>
    </div>
  );

  const visual = (
    <aside
      className={`auth-visual ${
        isRegister
          ? 'auth-visual--register'
          : 'auth-visual--login'
      }`}
      aria-hidden="true"
    >
      <div
        className="auth-visual-image"
      />

      <div className="auth-visual-overlay" />

      <div className="auth-visual-top">
        <div className="visual-brand">
          <span className="visual-brand-icon">
            <Sun size={16} />
          </span>

          <span>smart solar</span>
        </div>

        <span className="visual-pill">
          Clean energy
        </span>
      </div>

      <div className="auth-visual-bottom">
        <div className="visual-kicker">
          {isRegister
            ? 'START YOUR SOLAR JOURNEY'
            : 'YOUR SOLAR WORKSPACE'}
        </div>

        <h3>
          {isRegister
            ? 'Power your home with confidence.'
            : 'Your solar project, all in one place.'}
        </h3>

        <p>
          Plan, track and manage your solar installation
          through one connected platform.
        </p>

        <div className="visual-progress">
          <span className="visual-progress-item active">
            <b>01</b>
            Plan
          </span>

          <span className="visual-progress-line" />

          <span className="visual-progress-item">
            <b>02</b>
            Review
          </span>

          <span className="visual-progress-line" />

          <span className="visual-progress-item">
            <b>03</b>
            Connect
          </span>
        </div>
      </div>

      <div className="visual-corner-mark">
        <ArrowUpRight size={16} />
      </div>
    </aside>
  );

  return (
    <main
      className={`auth-shell ${
        isRegister
          ? 'auth-shell--register'
          : 'auth-shell--login'
      }`}
    >
      <header className="auth-home-navbar">
        <Link
          className="auth-home-brand"
          to="/"
          aria-label="Smart Solar home"
        >
          <span className="auth-brand-icon">
            <Sun size={20} />
          </span>

          <span className="auth-brand-wordmark">
            smart <b>solar</b>
          </span>
        </Link>

        <nav
          className="auth-home-links"
          aria-label="Public navigation"
        >
          <Link to="/">Home</Link>
          <Link to="/#services">Services</Link>
          <Link to="/#projects">Projects</Link>
          <Link to="/#process">How it works</Link>
        </nav>

        <div className="auth-home-tools">
          <button
            type="button"
            className="auth-search-button"
            aria-label="Search"
          >
            <Search size={18} />
          </button>

          <Link
            className="auth-nav-action"
            to={isRegister ? '/login' : '/register'}
          >
            <span>
              {isRegister ? 'Sign in' : 'Get started'}
            </span>

            <ArrowUpRight size={15} />
          </Link>
        </div>
      </header>

      <section
        className="auth-form-panel"
        aria-label={isRegister ? 'Register' : 'Login'}
      >
        <div className="auth-card-frame">
          {formCard}
          {visual}
        </div>
      </section>

      <footer className="auth-footer">
        <span>© {new Date().getFullYear()} Smart Solar</span>

        <span className="auth-footer-dot">•</span>

        <span>
          Smarter solar. Better connected.
        </span>
      </footer>
    </main>
  );
}