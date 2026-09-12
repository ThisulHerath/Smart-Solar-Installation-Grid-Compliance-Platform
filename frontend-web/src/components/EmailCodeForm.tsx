import { useEffect, useState } from 'react';
import { Challenge } from '../services/account';
export function EmailCodeForm({ challenge, busy, onVerify, onResend, onBack, label = 'Verify email' }: {
  challenge: Challenge; busy: boolean; onVerify: (code: string) => void; onResend: () => void; onBack: () => void; label?: string;
}) {
  const [code, setCode] = useState(''), [now, setNow] = useState(Date.now());
  const [resendAt, setResendAt] = useState(Date.now() + challenge.resendAfterSeconds * 1000);
  useEffect(() => { setCode(''); setResendAt(Date.now() + challenge.resendAfterSeconds * 1000); }, [challenge]);
  useEffect(() => { const timer = window.setInterval(() => setNow(Date.now()), 1000); return () => window.clearInterval(timer); }, []);
  const remaining = Math.max(0, Math.ceil((resendAt - now) / 1000)), expired = new Date(challenge.expiresAt).getTime() <= now;
  return <div className="account-form"><p role="status">We sent a six-digit code to <strong>{challenge.maskedEmail}</strong>. Check your inbox and spam folder.</p>
    <form className="account-form" onSubmit={event => { event.preventDefault(); onVerify(code); }}><label htmlFor="email-code">Email verification code</label>
      <input id="email-code" className="input-field otp-input" value={code} onChange={e => setCode(e.target.value.replace(/\D/g, '').slice(0, 6))} autoComplete="one-time-code" inputMode="numeric" pattern="[0-9]{6}" maxLength={6} required autoFocus aria-describedby="code-expiry" disabled={busy} />
      <p id="code-expiry" className="field-help">{expired ? 'This code has expired. Request a new code below.' : 'Your code expires after 10 minutes and can be used once.'}</p>
      <button className="btn btn-primary" disabled={busy || code.length !== 6 || expired}>{busy ? 'Please wait…' : label}</button></form>
    <button type="button" className="btn btn-secondary" disabled={busy || remaining > 0} onClick={onResend}>{remaining ? `Resend code in ${remaining}s` : 'Send a new code'}</button>
    <button type="button" className="text-button" disabled={busy} onClick={onBack}>Go back</button></div>;
}
