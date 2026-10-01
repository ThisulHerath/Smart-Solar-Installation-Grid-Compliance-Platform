import { AuthField, AuthForm } from '../components/AuthField';
import { useState } from 'react';
import { Mail, Phone, UserRound } from 'lucide-react';

import { Link, Navigate, useNavigate } from 'react-router-dom';

import { AuthShell } from '../components/AuthShell';
import { EmailCodeForm } from '../components/EmailCodeForm';

import { useAuth } from '../context/AuthContext';
import {
  accountApi,
  Challenge,
  Registration,
} from '../services/account';

export function RegisterPage() {
  const [details, setDetails] = useState<Registration>({
    fullName: '',
    email: '',
    password: '',
    phoneNumber: '',
  });

  const [confirm, setConfirm] = useState('');
  const [challenge, setChallenge] =
    useState<Challenge | null>(null);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const [termsAccepted, setTermsAccepted] = useState(false);

  const { user, login } = useAuth();
  const navigate = useNavigate();

  if (user) {
    return <Navigate to="/dashboard" replace />;
  }

  const requestCode = async () => {
    setError('');

    if (details.password !== confirm) {
      setError('Your passwords do not match.');
      return;
    }

    if (!termsAccepted) {
      setError('Please accept the terms and conditions to continue.');
      return;
    }

    setBusy(true);

    try {
      setChallenge(
        await accountApi.requestRegistration(details)
      );
    } catch (err) {
      setError(
        err instanceof Error
          ? err.message
          : 'Unable to send your verification email.'
      );
    } finally {
      setBusy(false);
    }
  };

  const field = (
    key: keyof Registration,
    label: string,
    type = 'text',
    autoComplete = ''
  ) => (
    <AuthField
      label={label}
      id={`register-${key}`}
      type={type}
      placeholder={
        key === 'fullName' ? 'Enter your full name' :
          key === 'email' ? 'you@example.com' :
            key === 'phoneNumber' ? '+94 77 123 4567' :
              'Create a strong password'
      }
      icon={
        key === 'fullName' ? <UserRound size={17} /> :
          key === 'email' ? <Mail size={17} /> :
            key === 'phoneNumber' ? <Phone size={17} /> : undefined
      }
      autoComplete={autoComplete}
      value={details[key] || ''}
      onChange={(e) =>
        setDetails({
          ...details,
          [key]: e.target.value,
        })
      }
      required={key !== 'phoneNumber'}
      disabled={busy}
      minLength={key === 'password' ? 12 : undefined}
      maxLength={
        key === 'password'
          ? 64
          : key === 'phoneNumber'
            ? 50
            : 254
      }
      hint={
        key === 'password'
          ? '12–64 characters. Try a memorable passphrase.'
          : undefined
      }
    />
  );

  return (
    <AuthShell>
      <p className="eyebrow">
        START YOUR SOLAR JOURNEY
      </p>

      <h2>
        {challenge
          ? 'Check your email'
          : 'Create your account'}
      </h2>

      <p className="auth-intro">
        {challenge
          ? 'One last step to activate your account.'
          : 'A homeowner account to plan and track your solar installation.'}
      </p>

      {error && (
        <p className="account-error" role="alert">
          {error}
        </p>
      )}

      {challenge ? (
        <EmailCodeForm
          challenge={challenge}
          busy={busy}
          onResend={requestCode}
          onBack={() => {
            setChallenge(null);
            setError('');
          }}
          onVerify={async (code) => {
            setBusy(true);
            setError('');

            try {
              const result =
                await accountApi.verifyRegistration(
                  challenge.challengeId,
                  code
                );

              login(result.token, result.user);

              navigate('/dashboard', {
                replace: true,
              });
            } catch (err) {
              setError(
                err instanceof Error
                  ? err.message
                  : 'Unable to verify your code.'
              );
            } finally {
              setBusy(false);
            }
          }}
        />
      ) : (
        <AuthForm
          className="account-form register-form"
          onSubmit={(e) => {
            e.preventDefault();
            void requestCode();
          }}
        >
          <div className="register-columns">
            <div className="register-column register-profile-column">
              {field('fullName', 'Full name', 'text', 'name')}
              <div className="register-contact-row">
                {field('email', 'Email address', 'email', 'email')}
                {field('phoneNumber', 'Phone number (optional)', 'tel', 'tel')}
              </div>
            </div>

            <div className="register-column register-security-column">
              {field('password', 'Password', 'password', 'new-password')}

              <AuthField
                label="Confirm password"
                matchValue={details.password}
                id="register-confirm"
                className="input-field"
                type="password"
                autoComplete="new-password"
                placeholder="Re-enter your password"
                required
                value={confirm}
                onChange={(e) => setConfirm(e.target.value)}
                disabled={busy}
              />

              <label className="register-terms">
                <input
                  type="checkbox"
                  checked={termsAccepted}
                  aria-required="true"
                  onChange={(event) => setTermsAccepted(event.target.checked)}
                  disabled={busy}
                />
                <span>I agree to the terms &amp; conditions</span>
              </label>

              <p className="field-help">
                We’ll email you a code to verify that this address belongs to you.
              </p>

              <button
                className="btn btn-primary register-submit"
                aria-label="Continue with email verification"
                disabled={busy}
              >
                {busy ? 'Sending code…' : 'Register'}
              </button>
            </div>
          </div>
        </AuthForm>
      )}

      <p className="auth-switch">
        Already registered?{' '}
        <Link to="/login">Sign in</Link>
      </p>
    </AuthShell>
  );
};
