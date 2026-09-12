import { AuthField, AuthForm } from '../components/AuthField';
import { useState } from 'react';
import { Link, Navigate, useNavigate } from 'react-router-dom';
import { AuthShell } from '../components/AuthShell';
import { EmailCodeForm } from '../components/EmailCodeForm';
import { accountApi, Challenge, Registration } from '../services/account';
import { useAuth } from '../context/AuthContext';
export function RegisterPage() {
  const [details, setDetails] = useState<Registration>({ fullName: '', email: '', password: '', phoneNumber: '' });
  const [confirm, setConfirm] = useState(''), [challenge, setChallenge] = useState<Challenge | null>(null), [error, setError] = useState(''), [busy, setBusy] = useState(false);
  const { user, login } = useAuth(), navigate = useNavigate();
  if (user) return <Navigate to="/" replace />;
  const requestCode = async () => {
    setError(''); if (details.password !== confirm) { setError('Your passwords do not match.'); return; } setBusy(true);
    try { setChallenge(await accountApi.requestRegistration(details)); } catch (err) { setError(err instanceof Error ? err.message : 'Unable to send your verification email.'); } finally { setBusy(false); }
  };
  const field = (key: keyof Registration, label: string, type = 'text', autoComplete = '') => <AuthField label={label} id={`register-${key}`} type={type} autoComplete={autoComplete} value={details[key] || ''} onChange={e => setDetails({ ...details, [key]: e.target.value })} required={key !== 'phoneNumber'} disabled={busy} minLength={key === 'password' ? 12 : undefined} maxLength={key === 'password' ? 64 : key === 'phoneNumber' ? 50 : 254} hint={key === 'password' ? '12–64 characters. Try a memorable passphrase.' : undefined} />;
  return <AuthShell><p className="eyebrow">START YOUR SOLAR JOURNEY</p><h2>{challenge ? 'Check your email' : 'Create your account'}</h2><p className="auth-intro">{challenge ? 'One last step to activate your account.' : 'A homeowner account to plan and track your solar installation.'}</p>
    {error && <p className="account-error" role="alert">{error}</p>}
    {challenge ? <EmailCodeForm challenge={challenge} busy={busy} onResend={requestCode} onBack={() => { setChallenge(null); setError(''); }} onVerify={async code => {
      setBusy(true); setError(''); try { const result = await accountApi.verifyRegistration(challenge.challengeId, code); login(result.token, result.user); navigate('/', { replace: true }); } catch (err) { setError(err instanceof Error ? err.message : 'Unable to verify your code.'); } finally { setBusy(false); }
    }} /> : <AuthForm className="account-form" onSubmit={e => { e.preventDefault(); void requestCode(); }}>
      {field('fullName', 'Full name', 'text', 'name')}{field('email', 'Email address', 'email', 'email')}{field('phoneNumber', 'Phone number (optional)', 'tel', 'tel')}{field('password', 'Password', 'password', 'new-password')}
      <AuthField label="Confirm password" matchValue={details.password} id="register-confirm" className="input-field" type="password" autoComplete="new-password" required value={confirm} onChange={e => setConfirm(e.target.value)} disabled={busy} />
      <p className="field-help">We’ll email you a code to verify that this address belongs to you.</p><button className="btn btn-primary" disabled={busy}>{busy ? 'Sending code…' : 'Continue with email verification'}</button></AuthForm>}
    <p className="auth-switch">Already registered? <Link to="/login">Sign in</Link></p></AuthShell>;
}
