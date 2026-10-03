import { useState } from 'react';
import { KeyRound, MailCheck, ShieldCheck } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { AuthField, AuthForm } from '../components/AuthField';
import { AuthShell } from '../components/AuthShell';
import { EmailCodeForm } from '../components/EmailCodeForm';
import { useAuth } from '../context/AuthContext';
import { accountApi, Challenge } from '../services/account';
import './StaffOnboardingPage.css';

const checks = [
  { label: '12–64 characters', test: (value: string) => value.length >= 12 && value.length <= 64 },
  { label: 'Uppercase and lowercase letters', test: (value: string) => /[A-Z]/.test(value) && /[a-z]/.test(value) },
  { label: 'At least one number', test: (value: string) => /\d/.test(value) },
  { label: 'At least one symbol', test: (value: string) => /[^A-Za-z0-9]/.test(value) },
];

export function StaffOnboardingPage() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [challenge, setChallenge] = useState<Challenge | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const passwordValid = checks.every(check => check.test(password)) && new TextEncoder().encode(password).length <= 72;

  async function requestCode() {
    if (!passwordValid || password !== confirmPassword) {
      setError(password !== confirmPassword ? 'The passwords do not match.' : 'Complete every password requirement before continuing.');
      return;
    }
    setBusy(true); setError('');
    try { setChallenge(await accountApi.requestStaffOnboarding(password)); }
    catch (requestError) { setError(requestError instanceof Error ? requestError.message : 'Unable to send the verification code.'); }
    finally { setBusy(false); }
  }

  async function verify(code: string) {
    if (!challenge) return;
    setBusy(true); setError('');
    try {
      const result = await accountApi.confirmStaffOnboarding(challenge.challengeId, code);
      logout();
      navigate('/login', { replace: true, state: { message: result.message } });
    } catch (requestError) { setError(requestError instanceof Error ? requestError.message : 'Unable to verify this code.'); }
    finally { setBusy(false); }
  }

  return <AuthShell>
    <div className="staff-onboarding-heading"><span><ShieldCheck size={23} /></span><div><p className="eyebrow">FIRST SIGN-IN SECURITY</p><h2>Secure your staff account</h2></div></div>
    <p className="auth-intro">Welcome, {user?.fullName}. Replace the temporary password and verify your assigned email before opening the workspace.</p>
    {error && <p className="account-error" role="alert">{error}</p>}
    {challenge ? <EmailCodeForm challenge={challenge} busy={busy} label="Verify and secure account" onVerify={code => void verify(code)} onResend={() => void requestCode()} onBack={() => { setChallenge(null); setError(''); }} /> :
      <AuthForm className="account-form" onSubmit={event => { event.preventDefault(); void requestCode(); }}>
        <div className="staff-onboarding-email"><MailCheck size={18} /><span>Verification code will be sent to</span><strong>{user?.email}</strong></div>
        <AuthField label="New password" id="staff-new-password" type="password" autoComplete="new-password" minLength={12} maxLength={64} value={password} onChange={event => setPassword(event.target.value)} required disabled={busy} icon={<KeyRound size={17} />} />
        <AuthField label="Confirm new password" id="staff-confirm-password" type="password" autoComplete="new-password" minLength={12} maxLength={64} value={confirmPassword} matchValue={password} onChange={event => setConfirmPassword(event.target.value)} required disabled={busy} />
        <ul className="staff-password-checks" aria-label="Password requirements">{checks.map(check => <li key={check.label} className={check.test(password) ? 'complete' : ''}><span aria-hidden="true">{check.test(password) ? '✓' : '○'}</span>{check.label}</li>)}</ul>
        <button className="btn btn-primary" disabled={busy}>{busy ? 'Sending code…' : 'Continue with email verification'}</button>
      </AuthForm>}
  </AuthShell>;
}
