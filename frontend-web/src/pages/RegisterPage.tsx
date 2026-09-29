import { AuthField, AuthForm } from '../components/AuthField';
import { useState } from 'react';
import { Link, Navigate, useNavigate } from 'react-router-dom';

import { AuthShell } from '../components/AuthShell';
import { EmailCodeForm } from '../components/EmailCodeForm';
import {
  accountApi,
  Challenge,
  Registration,
} from '../services/account';
import { useAuth } from '../context/AuthContext';

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
      {!challenge ? (
        <>
          <div className="auth-content-header">
            <div className="auth-mini-badge">
              <span className="auth-mini-badge-dot" />
              Homeowner registration
            </div>

            <h2>Start your solar journey</h2>

            <p className="auth-intro">
              Create your Smart Solar account to plan,
              monitor and manage your solar installation.
            </p>
          </div>

          <div className="register-progress">
            <div className="register-progress-step active">
              <span>1</span>
              <div>
                <strong>Your details</strong>
                <small>Create your account</small>
              </div>
            </div>

            <div className="register-progress-line" />

            <div className="register-progress-step">
              <span>2</span>
              <div>
                <strong>Verify email</strong>
                <small>Confirm your address</small>
              </div>
            </div>
          </div>
        </>
      ) : (
        <div className="auth-content-header">
          <div className="auth-mini-badge">
            <span className="auth-mini-badge-dot" />
            Almost there
          </div>

          <h2>Check your email</h2>

          <p className="auth-intro">
            We sent a verification code to your email.
            Enter it below to activate your Smart Solar account.
          </p>
        </div>
      )}

      {error && (
        <div className="account-error" role="alert">
          <span className="status-icon">!</span>
          <span>{error}</span>
        </div>
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
          className="account-form"
          onSubmit={(e) => {
            e.preventDefault();
            void requestCode();
          }}
        >
          {field(
            'fullName',
            'Full name',
            'text',
            'name'
          )}

          {field(
            'email',
            'Email address',
            'email',
            'email'
          )}

          {field(
            'phoneNumber',
            'Phone number',
            'tel',
            'tel'
          )}

          {field(
            'password',
            'Password',
            'password',
            'new-password'
          )}

          <AuthField
            label="Confirm password"
            matchValue={details.password}
            id="register-confirm"
            className="input-field"
            type="password"
            autoComplete="new-password"
            required
            value={confirm}
            onChange={(e) =>
              setConfirm(e.target.value)
            }
            disabled={busy}
          />

          <div className="verification-info">
            <span className="verification-icon">✓</span>

            <div>
              <strong>Email verification</strong>
              <p>
                We'll send a verification code to confirm
                that this email belongs to you.
              </p>
            </div>
          </div>

          <button
            className="btn btn-primary auth-submit-btn"
            disabled={busy}
            type="submit"
          >
            {busy ? (
              <>
                <span className="button-spinner" />
                Sending code...
              </>
            ) : (
              <>
                Continue
                <span className="button-arrow">→</span>
              </>
            )}
          </button>
        </AuthForm>
      )}

      <div className="auth-divider">
        <span>Already have an account?</span>
      </div>

      <Link
        className="auth-secondary-btn"
        to="/login"
      >
        Sign in instead
      </Link>

      <p className="auth-security-note">
        <span>🔒</span>
        Your information is handled securely.
      </p>
    </AuthShell>
  );
}