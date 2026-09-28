import { useState } from 'react';
import { KeyRound, Mail } from 'lucide-react';
import { Link, useNavigate } from 'react-router-dom';

import { AuthField, AuthForm } from '../components/AuthField';
import { AuthShell } from '../components/AuthShell';
import { EmailCodeForm } from '../components/EmailCodeForm';
import { accountApi, Challenge } from '../services/account';

export function ForgotPasswordPage() {
  const [email, setEmail] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [challenge, setChallenge] = useState<Challenge | null>(null);
  const [notice, setNotice] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const navigate = useNavigate();

  const requestCode = async () => {
    if (newPassword !== confirmPassword) {
      setError('Your passwords do not match.');
      return;
    }

    setBusy(true);
    setError('');
    setNotice('');

    try {
      const result = await accountApi.requestPasswordReset({
        email: email.trim(),
        newPassword,
      });
      setNotice(result.message);
      setChallenge(result.challenge);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unable to request a password reset.');
    } finally {
      setBusy(false);
    }
  };

  return (
    <AuthShell>
      <p className="eyebrow">ACCOUNT RECOVERY</p>
      <h2>{challenge ? 'Check your email' : 'Reset your password'}</h2>
      <p className="auth-intro">
        {challenge
          ? 'Enter the verification code to securely set your new password.'
          : 'Choose a new password and we will send a verification code to your email.'}
      </p>

      {notice && <p className="account-success" role="status">{notice}</p>}
      {error && <p className="account-error" role="alert">{error}</p>}

      {challenge ? (
        <EmailCodeForm
          challenge={challenge}
          busy={busy}
          label="Reset password"
          onResend={requestCode}
          onBack={() => {
            setChallenge(null);
            setNotice('');
            setError('');
          }}
          onVerify={async (code) => {
            setBusy(true);
            setError('');
            try {
              const result = await accountApi.confirmPasswordReset(challenge.challengeId, code);
              navigate('/login', { replace: true, state: { message: result.message } });
            } catch (err) {
              setError(err instanceof Error ? err.message : 'Unable to reset your password.');
            } finally {
              setBusy(false);
            }
          }}
        />
      ) : (
        <AuthForm
          className="account-form"
          onSubmit={(event) => {
            event.preventDefault();
            void requestCode();
          }}
        >
          <AuthField
            label="Email address"
            id="reset-email"
            type="email"
            autoComplete="email"
            placeholder="you@example.com"
            icon={<Mail size={17} />}
            value={email}
            onChange={(event) => setEmail(event.target.value)}
            required
            disabled={busy}
          />
          <AuthField
            label="New password"
            id="reset-password"
            type="password"
            autoComplete="new-password"
            placeholder="Create a new password"
            icon={<KeyRound size={17} />}
            hint="12-64 characters. Try a memorable passphrase."
            value={newPassword}
            onChange={(event) => setNewPassword(event.target.value)}
            required
            minLength={12}
            maxLength={64}
            disabled={busy}
          />
          <AuthField
            label="Confirm new password"
            id="reset-confirm-password"
            type="password"
            autoComplete="new-password"
            placeholder="Re-enter your new password"
            matchValue={newPassword}
            value={confirmPassword}
            onChange={(event) => setConfirmPassword(event.target.value)}
            required
            disabled={busy}
          />
          <button className="btn btn-primary" disabled={busy}>
            {busy ? 'Sending code...' : 'Send verification code'}
          </button>
        </AuthForm>
      )}

      <p className="auth-switch">
        Remembered your password? <Link to="/login">Back to sign in</Link>
      </p>
    </AuthShell>
  );
}
