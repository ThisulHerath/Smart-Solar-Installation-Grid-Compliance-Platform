import { AuthField, AuthForm } from '../components/AuthField';
import { useState } from 'react';
import { Link, Navigate, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { api } from '../services/api';
import { AuthShell } from '../components/AuthShell';
export function LoginPage() {
  const [email, setEmail] = useState(''), [password, setPassword] = useState(''), [error, setError] = useState(''), [busy, setBusy] = useState(false);
  const { login, user } = useAuth(), navigate = useNavigate(), location = useLocation();
  if (user) return <Navigate to="/" replace />;
  return <AuthShell><p className="eyebrow">WELCOME BACK</p><h2>Sign in to Smart Solar</h2><p className="auth-intro">Your solar project, all in one place.</p>
    {location.state?.message && <p className="account-success" role="status">{location.state.message}</p>}{error && <p className="account-error" role="alert">{error}</p>}
    <AuthForm className="account-form" onSubmit={async e => {
      e.preventDefault(); setError(''); setBusy(true);
      try { const result = await api.login(email.trim(), password); login(result.token, result.user); navigate('/', { replace: true }); }
      catch (err) { setError(err instanceof Error ? err.message : 'Unable to sign in. Please try again.'); } finally { setBusy(false); }
    }}><AuthField label="Email address" id="login-email" className="input-field" type="email" autoComplete="email" placeholder="you@example.com" value={email} onChange={e => setEmail(e.target.value)} required maxLength={254} disabled={busy} />
      <AuthField label="Password" id="login-password" className="input-field" type="password" autoComplete="current-password" value={password} onChange={e => setPassword(e.target.value)} required disabled={busy} />
      <button className="btn btn-primary" disabled={busy}>{busy ? 'Signing in…' : 'Sign in'}</button></AuthForm>
    <p className="auth-switch">New to Smart Solar? <Link to="/register">Create an account</Link></p></AuthShell>;
}
