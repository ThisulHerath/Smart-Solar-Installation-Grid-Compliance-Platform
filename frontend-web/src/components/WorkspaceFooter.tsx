import { Link } from 'react-router-dom';
import { ArrowUpRight, MapPin, Sun } from 'lucide-react';
import '../styles/workspace-footer.css';

export const WorkspaceFooter = () => (
  <footer className="workspace-footer">
    <div className="workspace-footer__main">
      <div className="workspace-footer__brand-column">
        <Link className="workspace-footer__brand" to="/" aria-label="Smart Solar home">
          <span className="workspace-footer__mark"><Sun size={26} aria-hidden="true" /></span>
          <span>smart<strong>solar</strong></span>
        </Link>
        <p>A clearer path to rooftop solar. Plan your installation, follow your project, and move toward a brighter future.</p>
        <span className="workspace-footer__location"><MapPin size={15} aria-hidden="true" /> Built for Sri Lanka</span>
      </div>
      <nav className="workspace-footer__links" aria-label="Footer explore navigation">
        <h2>Explore</h2>
        <Link to="/">Home</Link>
        <Link to="/#services">Our services</Link>
        <Link to="/#process">How it works</Link>
      </nav>
      <nav className="workspace-footer__links" aria-label="Footer workspace navigation">
        <h2>Your workspace</h2>
        <Link to="/dashboard" onClick={() => window.scrollTo({ top: 0, left: 0, behavior: 'instant' })}>Dashboard</Link>
        <Link to="/profile">My profile</Link>
        <Link to="/account">Account settings</Link>
      </nav>
      <div className="workspace-footer__action">
        <span className="workspace-footer__eyebrow">YOUR NEXT STEP</span>
        <h2>Keep your solar plans moving.</h2>
        <p>Everything you need to follow your progress, in one place.</p>
        <Link to="/dashboard" onClick={() => window.scrollTo({ top: 0, left: 0, behavior: 'instant' })}>Open dashboard <ArrowUpRight size={17} aria-hidden="true" /></Link>
      </div>
    </div>
    <div className="workspace-footer__bottom">
      <small>© {new Date().getFullYear()} Smart Solar. All rights reserved.</small>
      <span>Rooftop solar planning <span aria-hidden="true">·</span> Grid compliance</span>
    </div>
  </footer>
);
