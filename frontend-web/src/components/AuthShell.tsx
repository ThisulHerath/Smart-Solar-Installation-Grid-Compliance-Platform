import { ReactNode } from 'react';
import { Link } from 'react-router-dom';
import { Sun, ShieldCheck, ArrowRight } from './Icons';
import '../styles/account.css';
export function AuthShell({ children }: { children: ReactNode }) {
  return <main className="auth-shell"><section className="auth-story" aria-label="About Smart Solar">
    <Link className="auth-brand" to="/login"><Sun size={30} /> Smart Solar<span>SRI LANKA</span></Link>
    <div className="auth-story-copy"><p className="eyebrow">YOUR ROOFTOP. YOUR NEXT CHAPTER.</p><h1>A clearer path<br />to solar.</h1><p>From your first roof assessment to engineering review, keep your solar installation moving with confidence.</p>
      <div className="solar-scene" aria-hidden="true"><div className="solar-sun" /><div className="solar-roof" /><span className="solar-ground" /></div>
      <div className="auth-steps"><span>01 · Assess your home</span><ArrowRight size={16} /><span>02 · Plan your installation</span></div></div>
    <p className="auth-trust"><ShieldCheck size={18} /> Email verification protects your account.</p>
  </section><section className="auth-form-panel"><div className="auth-form-content">{children}</div><p className="auth-footnote">Built for rooftop solar in Sri Lanka.<br />Engineering and utility approval remain part of every installation.</p></section></main>;
}
