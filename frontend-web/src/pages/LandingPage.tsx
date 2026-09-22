import { useState, type CSSProperties } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { ArrowRight, BadgeCheck, CalendarCheck2, CheckCircle2, ClipboardList, Headphones, Layers3, Leaf, LogOut, Mail, MapPin, Menu, Minus, Phone, Play, Plus, Search, Send, ShieldCheck, Star, Sun, WalletCards, Wrench, X, Zap } from 'lucide-react';

import { useAuth } from '../context/AuthContext';
import solarEngineerPortrait from '../../images/hero-engineer.png';
import solarPanels from '../../images/1.jpeg';
import serviceInstallation from '../../images/service-installation.png';
import servicePlanning from '../../images/service-planning.png';
import serviceHome from '../../images/service-home.png';
import whyEngineeringTeam from '../../images/why-engineering-team.png';
import aboutGridTeam from '../../images/about-grid-team.png';
import '../styles/landing.css';
import '../styles/solar-home-polish.css';
import '../styles/footer-contact.css';
import '../styles/home-sections.css';
import '../styles/home-extended.css';
import '../styles/hero-engineer.css';
import '../styles/landing-nav-active.css';
import '../styles/landing-account.css';
import '../styles/hero-spacing.css';
import '../styles/about-emphasis.css';
import '../styles/footer-full.css';

const faqs = [
  ['What are the benefits of installing solar panels?', 'Solar can reduce reliance on grid electricity while giving you a clearer view of your household energy plan.'],
  ['How does the solar installation process work?', 'Start with an assessment, review the proposed system, track engineering evidence, then follow approval and installation milestones from your workspace.'],
  ['What maintenance is required for solar panels?', 'Regular cleaning and periodic checks help panels perform well. Your project workspace keeps inspection records easy to find.'],
  ['Can I use solar panels to power my entire home?', 'This depends on your usage, rooftop, and proposed system size. An assessment gives you the most reliable answer.'],
  ['Do I need batteries to store solar energy?', 'Battery options can be included where they suit your energy goals and installation plan.'],
];

const touchLabel = 'GET IN TOUCH · GET IN TOUCH ·';

export function LandingPage() {
  const { user, logout, profilePhoto } = useAuth();
  const { hash } = useLocation();
  const [menuOpen, setMenuOpen] = useState(false);
  const [openFaq, setOpenFaq] = useState(1);
  const destination = user ? '/dashboard' : '/register';
  const activeSection = hash === '#services' ? 'services' : hash === '#projects' ? 'projects' : hash === '#process' ? 'process' : 'home';
  const userInitials = user?.fullName.split(' ').filter(Boolean).slice(0, 2).map((part) => part[0]).join('').toUpperCase() || '';
  const userRole = user?.roles[0]?.replace(/_/g, ' ').toLowerCase().replace(/\b\w/g, (letter) => letter.toUpperCase()) || 'Member';

  return (
    <div className="eco-landing">
      <a className="landing-skip" href="#main-content">Skip to content</a>
      <header className="eco-nav">
        <Link className="eco-brand" to="/" aria-label="Smart Solar home"><Sun size={24} /><span>smart</span>solar</Link>
        <button className="eco-menu" aria-label={menuOpen ? 'Close menu' : 'Open menu'} aria-expanded={menuOpen} onClick={() => setMenuOpen(!menuOpen)}>{menuOpen ? <X size={20} /> : <Menu size={20} />}</button>
        <nav className={menuOpen ? 'is-open' : ''} aria-label="Main navigation">
          <a className={activeSection === 'home' ? 'is-active' : ''} href="#main-content" onClick={() => setMenuOpen(false)}>Home</a>
          <a className={activeSection === 'services' ? 'is-active' : ''} href="#services" onClick={() => setMenuOpen(false)}>Services</a>
          <Link to="/dashboard" onClick={() => setMenuOpen(false)}>Projects</Link>
          <a className={activeSection === 'process' ? 'is-active' : ''} href="#process" onClick={() => setMenuOpen(false)}>How it works</a>
        </nav>
        <div className="nav-actions">{user ? <div className="landing-account-actions"><Link className="landing-user" to="/profile" aria-label="Open my profile"><span className="landing-user-avatar">{profilePhoto ? <img src={profilePhoto} alt="" /> : userInitials}</span><span><strong>{user.fullName}</strong><small>{userRole}</small></span></Link><button type="button" className="landing-logout" onClick={logout}><LogOut size={17} /> Logout</button></div> : <><Search size={21} aria-hidden="true" /><Link to="/login">Login</Link></>}</div>
      </header>

      <main id="main-content">
        <section className="eco-hero">
          <div className="hero-copy">
            <p className="hero-kicker"><i /> SMART SOLAR PLATFORM</p>
            <h1>Greening our future:<br /><span>Renewable energy</span></h1>
            <p>Plan, review, and track your solar project through one connected workspace built for homeowners and engineering teams.</p>
            <div className="hero-links"><Link to={destination} className="eco-primary">{user ? 'Open my workspace' : 'Explore solar planning'} <ArrowRight size={19} /></Link><a href="#services">View all services</a></div>
            <div className="hero-notes"><span><CheckCircle2 size={16} /> Grid compliance support</span><span><CheckCircle2 size={16} /> Engineering review</span></div>
          </div>
          <div className="hero-photo hero-photo--engineer" id="projects"><img src={solarEngineerPortrait} alt="Smart Solar engineer holding project plans" /><span className="photo-caption">SOLAR<br />EXPERT</span><div className="touch-badge" aria-label="Get in touch"><span className="touch-ring" aria-hidden="true">{[...touchLabel].map((letter, index) => <i key={`${letter}-${index}`} style={{ '--letter': index } as CSSProperties}>{letter}</i>)}</span><b><ArrowRight size={22} /></b></div></div>
        </section>

        <section className="eco-benefits" aria-label="Smart Solar benefits">
          <article><span><Leaf size={22} /></span><div><strong>Eco friendly</strong><small>Cleaner energy for everyday living</small></div></article>
          <article><span><BadgeCheck size={22} /></span><div><strong>Engineering review</strong><small>Guided checks at every key stage</small></div></article>
          <article><span><WalletCards size={22} /></span><div><strong>Clear planning</strong><small>Better visibility before you commit</small></div></article>
          <article><span><Headphones size={22} /></span><div><strong>Project support</strong><small>Know what happens next</small></div></article>
        </section>

        <section id="services" className="eco-services"><header><p>OUR SERVICES</p><h2>Services for <span>sustainable energy.</span></h2><span>Everything you need to prepare your solar project, without losing track of the important details.</span></header><div className="service-grid service-grid--visual"><article><img src={serviceInstallation} alt="Technician installing rooftop solar panels" /><span className="service-icon"><Sun size={21} /></span><h3>Solar panel solutions</h3><p>Plan the right rooftop system with clear project records and engineering review.</p><a href="#process">Learn more <ArrowRight size={14} /></a></article><article><img src={servicePlanning} alt="Solar panels at sunset" /><span className="service-icon"><Wrench size={21} /></span><h3>Solar planning review</h3><p>Keep technical checks, evidence, and next steps visible in one place.</p><a href="#process">Learn more <ArrowRight size={14} /></a></article><article><img src={serviceHome} alt="Home with rooftop solar panels" /><span className="service-icon"><Zap size={21} /></span><h3>Home solar systems</h3><p>Move confidently through approvals with organised, traceable submissions.</p><a href="#process">Learn more <ArrowRight size={14} /></a></article></div></section>

        <section className="eco-why"><header><p>WHY CHOOSE US</p><h2>Why choose our <span>green<br />energy solutions.</span></h2><Link to={destination} className="eco-why-cta">Get a quote</Link></header><div className="eco-why-content"><div className="why-image"><img src={whyEngineeringTeam} alt="Engineering team reviewing construction plans" /><button type="button" aria-label="Learn how Smart Solar works"><Play size={19} fill="currentColor" /></button></div><div className="why-grid"><article><WalletCards size={28} /><h3>Save your money</h3><p>Clear estimates and project information keep your solar investment easy to understand.</p></article><article><BadgeCheck size={28} /><h3>Certified review</h3><p>Bring installer, engineer, and homeowner conversations into one workspace.</p></article><article><Headphones size={28} /><h3>24 x 7 support</h3><p>Know the next step in your project without chasing scattered updates.</p></article><article><ShieldCheck size={28} /><h3>Trusted records</h3><p>Keep compliance evidence organised from assessment through approval.</p></article></div></div></section>

        <section className="eco-banner"><div><p>SAFEST AND SWIFTEST</p><h2>Securing clean, safe,<br /><span>renewable energy.</span></h2></div><Link to={destination} className="banner-cta">Discover more <ArrowRight size={18} /></Link></section>
        <section id="process" className="eco-process"><header><p>OUR WORK PROCESS</p><h2>Four steps forward:<br /><span>Navigating our process.</span></h2></header><div className="process-steps"><article><span><ClipboardList size={23} /><b>01</b></span><h3>Consult project</h3><p>Share your home and energy goals.</p></article><article><span><Wrench size={23} /><b>02</b></span><h3>Installation system</h3><p>Review the design and documents.</p></article><article><span><Layers3 size={23} /><b>03</b></span><h3>Project execution</h3><p>Track the work and approvals.</p></article><article><span><CalendarCheck2 size={23} /><b>04</b></span><h3>Ready to use</h3><p>Keep your project history close.</p></article></div></section>
        <section className="eco-about"><div className="about-image"><img src={aboutGridTeam} alt="Engineers reviewing a power grid installation" /><span><Sun size={25} /></span></div><div><p>ABOUT SMART SOLAR</p><h2>Empowering a<br /><span>sustainable future.</span></h2><p>We bring homeowners, engineers, and project evidence into one focused workspace. That means less uncertainty, clearer approvals, and a better solar journey.</p><div className="about-stats"><strong>1500+<small>Projects planned</small></strong><strong>750+<small>Homeowners supported</small></strong><strong>99%<small>Workflow visibility</small></strong></div></div></section>
        <section className="eco-testimonial"><header><p>TESTIMONIAL</p><h2>What our <span>clients<br />say about us.</span></h2></header><div className="testimonial-card"><img src={solarPanels} alt="Smart Solar customer" /><div><div className="testimonial-rating"><span><Star size={15} fill="currentColor" /><Star size={15} fill="currentColor" /><Star size={15} fill="currentColor" /><Star size={15} fill="currentColor" /><Star size={15} fill="currentColor" /></span> 5.0</div><p>“The project was much easier to understand once everything was in one place. We could see what needed approval and what would happen next.”</p><strong>Kasun Perera<small>Homeowner, Colombo</small></strong></div></div></section>
        <section className="eco-contact"><form onSubmit={(event) => event.preventDefault()}><div className="contact-field-row"><label>Your name<input required placeholder="e.g. John Doe" /></label><label>Email<input required type="email" placeholder="example@gmail.com" /></label></div><label>Subject<input required placeholder="Solar project enquiry" /></label><label>Your message<textarea required rows={4} placeholder="Tell us about your rooftop or project..." /></label><button type="submit">Send enquiry <Send size={15} /></button></form><div><p>CONTACT US</p><h2>Get your <span>free<br />quote today.</span></h2><p>Start with a conversation about your home, solar needs, and project timeline.</p><ul><li><Phone size={16} /> +94 11 555 0120</li><li><Mail size={16} /> solar@smartsolar.lk</li><li><MapPin size={16} /> 246/4 Royal Lane, Colombo</li></ul></div></section>
        <section className="eco-faq"><header><p>FAQ</p><h2>Question? <span>Look here.</span></h2></header><div>{faqs.map(([question, answer], index) => <article className={openFaq === index ? 'is-open' : ''} key={question}><button type="button" onClick={() => setOpenFaq(openFaq === index ? -1 : index)} aria-expanded={openFaq === index}><span>{question}</span>{openFaq === index ? <Minus size={17} /> : <Plus size={17} />}</button>{openFaq === index && <p>{answer}</p>}</article>)}</div></section>
        <section className="eco-newsletter"><p>OUR NEWSLETTER</p><h2>Subscribe for <span>exclusive<br />green energy</span> updates!</h2><form onSubmit={(event) => event.preventDefault()}><label><Mail size={16} /><input type="email" required placeholder="Enter email address" /></label><button type="submit">Subscribe</button></form></section>
      </main>

      <footer className="eco-footer">
        <div className="eco-footer-main">
          <div className="footer-brand-column"><Link className="eco-brand" to="/"><Sun size={21} /><span>Smart</span> Solar</Link><p>One connected workspace for clearer solar planning, engineering review, and grid compliance.</p><div className="footer-socials"><a href="mailto:solar@smartsolar.lk" aria-label="Email Smart Solar"><Mail size={15} /></a><a href="tel:+94115550120" aria-label="Call Smart Solar"><Phone size={15} /></a><a href="#main-content" aria-label="Smart Solar updates"><Send size={15} /></a></div></div>
          <div><h3>Company</h3><a href="#process">Our process</a><a href="#services">Services</a><a href="#main-content">Testimonials</a><a href="#main-content">FAQs</a><a href="#main-content">Contact us</a></div>
          <div><h3>Contact</h3><a href="tel:+94115550120">+94 11 555 0120</a><a href="mailto:solar@smartsolar.lk">solar@smartsolar.lk</a><p>246/4 Royal Lane,<br />Colombo, Sri Lanka</p></div>
          <div className="footer-subscribe"><h3>Get the latest information</h3><form onSubmit={(event) => event.preventDefault()}><input type="email" required placeholder="Email address" aria-label="Footer email address" /><button type="submit" aria-label="Subscribe"><Send size={16} /></button></form></div>
        </div>
        <div className="eco-footer-legal"><span>Copyright © 2026 Smart Solar. All rights reserved.</span><span><a href="#main-content">User terms</a><a href="#main-content">Privacy policy</a></span></div>
      </footer>
    </div>
  );
}
