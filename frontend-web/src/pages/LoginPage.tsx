import { useState } from 'react';

import {
  Link,
  Navigate,
  useLocation,
  useNavigate,
} from 'react-router-dom';

import { AuthField, AuthForm } from '../components/AuthField';
import { AuthShell } from '../components/AuthShell';
import { useAuth } from '../context/AuthContext';
import { api } from '../services/api';

export function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [rememberMe, setRememberMe] = useState(false);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  const { login, user } = useAuth();

  const navigate = useNavigate();
  const location = useLocation();

  if (user) {
    return <Navigate to="/dashboard" replace />;
  }

  return (
    <AuthShell>
      <p className="eyebrow">
        WELCOME BACK
      </p>

      <h2>Welcome back</h2>

      <p className="auth-intro">
        Your solar project, all in one place.
        Sign in to continue managing your
        installation and project updates.
      </p>

      {location.state?.message && (
        <p
          className="account-success"
          role="status"
        >
          <span>✓</span>
          <span>{location.state.message}</span>
        </p>
      )}

      {error && (
        <p
          className="account-error"
          role="alert"
        >
          <span>!</span>
          <span>{error}</span>
        </p>
      )}

      <AuthForm
        className="account-form"
        onSubmit={async (e) => {
          e.preventDefault();

          setError('');
          setBusy(true);

          try {
            const result = await api.login(
              email.trim(),
              password
            );

            login(
              result.token,
              result.user
            );

            navigate('/dashboard', {
              replace: true,
            });
          } catch (err) {
            setError(
              err instanceof Error
                ? err.message
                : 'Unable to sign in. Please check your details and try again.'
            );
          } finally {
            setBusy(false);
          }
        }}
      >
        <AuthField
          label="Email address"
          id="login-email"
          className="input-field"
          type="email"
          autoComplete="email"
          placeholder="you@example.com"
          value={email}
          onChange={(e) =>
            setEmail(e.target.value)
          }
          required
          maxLength={254}
          disabled={busy}
        />

        <AuthField
          label="Password"
          id="login-password"
          className="input-field"
          type="password"
          autoComplete="current-password"
          placeholder="Enter your password"
          value={password}
          onChange={(e) =>
            setPassword(e.target.value)
          }
          required
          disabled={busy}
        />

        <div className="login-options">
          <label className="remember-me">
            <input
              type="checkbox"
              checked={rememberMe}
              onChange={(event) =>
                setRememberMe(
                  event.target.checked
                )
              }
              disabled={busy}
            />

            <span>Remember me</span>
          </label>

          <button
            className="forgot-password"
            type="button"
            onClick={() =>
              navigate('/forgot-password')
            }
            disabled={busy}
          >
            Forgot password?
          </button>
        </div>

        <button
          className="btn btn-primary"
          disabled={busy}
          type="submit"
        >
          {busy
            ? 'Signing in…'
            : 'Sign in'}
        </button>
      </AuthForm>

      <p className="auth-switch">
        New to Smart Solar?{' '}
        <Link to="/register">
          Create an account
        </Link>
      </p>
    </AuthShell>
  );
}