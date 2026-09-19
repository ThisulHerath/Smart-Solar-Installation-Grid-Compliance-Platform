import { useState } from 'react';
import { Link } from 'react-router-dom';
import {
  ArrowRight,
  ArrowUpRight,
  Check,
  Layers,
  Leaf,
  Menu,
  ScanLine,
  ShieldCheck,
  Sun,
  X,
} from 'lucide-react';

import { useAuth } from '../context/AuthContext';
import '../styles/landing.css';

export function LandingPage() {
  const { user } = useAuth();
  const [menuOpen, setMenuOpen] = useState(false);

  const destination = user ? '/dashboard' : '/register';

  return (
    <div className="solar-landing">
      <a href="#main-content" className="landing-skip">
        Skip to content
      </a>

      <header className="landing-nav landing-width">
        <Link
          to="/"
          className="landing-brand"
          aria-label="Smart Solar home"
        >
          <Sun size={30} strokeWidth={1.7} />
          smart<span>solar.</span>
        </Link>

        <button
          className="landing-menu"
          aria-label={menuOpen ? 'Close menu' : 'Open menu'}
          aria-expanded={menuOpen}
          aria-controls="landing-navigation"
          onClick={() => setMenuOpen(!menuOpen)}
        >
          {menuOpen ? <X /> : <Menu />}
        </button>

        <nav
          id="landing-navigation"
          className={menuOpen ? 'is-open' : ''}
          aria-label="Main navigation"
        >
          <a
            href="#how-it-works"
            onClick={() => setMenuOpen(false)}
          >
            How it works
          </a>

          <a
            href="#services"
            onClick={() => setMenuOpen(false)}
          >
            Our services
          </a>

          <Link to={user ? '/profile' : '/login'}>
            {user ? 'My profile' : 'Log in'}
          </Link>

          <Link
            className="landing-button dark small"
            to={destination}
          >
            {user ? 'Open dashboard' : 'Get started'}
            <ArrowUpRight size={17} />
          </Link>
        </nav>
      </header>

      <main id="main-content">
        <section className="landing-hero landing-width">
          <div className="landing-hero-copy">
            <p className="landing-kicker">
              <span />
              A BRIGHTER WAY FORWARD
            </p>

            <h1>
              Good for your home.
              <br />
              <span>
                Better for
                <br />
                tomorrow.
              </span>
            </h1>

            <p className="landing-lead">
              Turn your rooftop into a new beginning. Plan your solar
              journey with clear assessments, expert review, and
              everything in one place.
            </p>

            <div className="landing-actions">
              <Link
                className="landing-button dark"
                to={destination}
              >
                {user
                  ? 'Go to my workspace'
                  : 'Start your solar journey'}
                <ArrowUpRight size={20} />
              </Link>

              <a
                href="#how-it-works"
                className="landing-text-link"
              >
                Explore the process
                <ArrowRight size={17} />
              </a>
            </div>

            <p className="landing-reassurance">
              <ShieldCheck size={17} />
              Built for Sri Lankan homes. Guided by engineering.
            </p>
          </div>

          <div
            className="landing-art"
            role="img"
            aria-label="Illustration of a modern home with rooftop solar panels surrounded by greenery"
          >
            <div className="art-orbit orbit-one" />
            <div className="art-orbit orbit-two" />

            <div className="art-sun">
              <Sun size={48} strokeWidth={1} />
            </div>

            <span className="art-caption">
              MORE POSSIBILITY.
              <br />
              SAME ROOFTOP.
            </span>

            <div className="art-land" />

            <div className="art-house">
              <div className="house-front">
                <i />
                <i />
                <b />
              </div>

              <div className="house-side" />

              <div className="house-roof">
                <div className="roof-panels">
                  {Array.from({ length: 12 }, (_, i) => (
                    <span key={i} />
                  ))}
                </div>
              </div>
            </div>

            <div className="art-tree tree-one" />
            <div className="art-tree tree-two" />

            <div className="art-note">
              <span>
                <Leaf size={22} />
              </span>

              <div>
                <strong>Your roof. New potential.</strong>
                <small>Make room for cleaner energy.</small>
              </div>
            </div>

            <div className="art-coordinate">
              SRI LANKA <span>7° N · 81° E</span>
            </div>
          </div>
        </section>

        <div className="landing-strip">
          <div className="landing-width">
            <span>
              <Sun />
              Rooftop potential
            </span>

            <span>
              <ScanLine />
              Thoughtful assessments
            </span>

            <span>
              <ShieldCheck />
              Engineering review
            </span>

            <span>
              <Layers />
              Equipment planning
            </span>
          </div>
        </div>

        <section
          id="services"
          className="landing-section landing-width"
        >
          <div className="landing-section-heading">
            <div>
              <p className="landing-kicker">
                FROM POSSIBILITY TO A PLAN
              </p>

              <h2>
                A little clarity.
                <br />
                A lot of potential.
              </h2>
            </div>

            <p>
              Bring every part of your solar project together, from
              understanding your roof to preparing the right
              equipment.
            </p>
          </div>

          <div className="landing-services">
            {[
              {
                icon: Sun,
                number: '01',
                title: 'Know your rooftop',
                copy: 'Share your electricity usage, roof details, and site photos to begin a solar assessment.',
              },
              {
                icon: ShieldCheck,
                number: '02',
                title: 'Plan with confidence',
                copy: 'Connect site inspections, compliance checks, and engineering review in one clear workflow.',
              },
              {
                icon: Layers,
                number: '03',
                title: 'See the whole picture',
                copy: 'Follow your proposal and equipment preparation with updates in your personal workspace.',
              },
            ].map(({ icon: Icon, number, title, copy }) => (
              <article key={number}>
                <div className="service-top">
                  <Icon size={30} strokeWidth={1.5} />
                  <span>{number}</span>
                </div>

                <h3>{title}</h3>

                <p>{copy}</p>

                <Link
                  to={user ? '/dashboard' : '/login'}
                  aria-label={`${title} — open services`}
                >
                  Explore service
                  <ArrowUpRight size={18} />
                </Link>
              </article>
            ))}
          </div>
        </section>

        <section className="landing-process">
          <div className="landing-width process-grid">
            <div>
              <p className="landing-kicker">
                YOUR NEXT CHAPTER STARTS HERE
              </p>

              <h2>
                Less guesswork.
                <br />
                <span>More sunshine.</span>
              </h2>

              <p>
                You don’t need to have all the answers. Start with
                your home, and follow the next step from your
                dashboard.
              </p>

              <Link
                className="landing-button lime"
                to={destination}
              >
                {user
                  ? 'Continue your project'
                  : 'Create your account'}
                <ArrowUpRight size={20} />
              </Link>
            </div>

            <ol>
              {[
                [
                  'Make yourself at home',
                  'Register and verify your email to open your own secure workspace.',
                ],
                [
                  'Tell us about your roof',
                  'Add your property details, electricity usage, and site photos.',
                ],
                [
                  'Follow your solar plan',
                  'Track inspections, engineering decisions, and equipment preparation.',
                ],
              ].map(([title, copy], i) => (
                <li key={title}>
                  <span>0{i + 1}</span>

                  <div>
                    <h3>{title}</h3>
                    <p>{copy}</p>
                  </div>

                  <Check size={20} />
                </li>
              ))}
            </ol>
          </div>
        </section>

        <section className="landing-final landing-width">
          <p className="landing-kicker">
            MAKE YOUR NEXT MOVE A BRIGHT ONE
          </p>

          <h2>
            Your solar story
            <br />
            starts with you.
          </h2>

          <Link
            className="landing-button dark"
            to={destination}
          >
            {user ? 'Open my dashboard' : 'Let’s get started'}
            <ArrowUpRight size={20} />
          </Link>

          <p>Log in or register to access solar planning services.</p>
        </section>
      </main>

      <footer className="landing-footer landing-width">
        <Link className="landing-brand" to="/">
          <Sun size={24} />
          smart<span>solar.</span>
        </Link>

        <p>
          Rooftop solar planning, made clearer.
          <br />
          <small>
            Final installation and grid connection require
            authorized engineering and utility approval.
          </small>
        </p>

        <span>Made for Sri Lanka ↗</span>
      </footer>
    </div>
  );
};