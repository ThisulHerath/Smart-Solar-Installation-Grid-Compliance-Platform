import { AuthField, AuthForm } from '../components/AuthField';
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';

import { EmailCodeForm } from '../components/EmailCodeForm';
import { useAuth } from '../context/AuthContext';
import {
  accountApi,
  AccountAction,
  Challenge,
} from '../services/account';

import '../styles/account.css';

export function AccountPage() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const [action, setAction] = useState<AccountAction | null>(null);
  const [challenge, setChallenge] = useState<Challenge | null>(null);

  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [acknowledged, setAcknowledged] = useState(false);

  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  // Reset the current security flow
  const reset = () => {
    setAction(null);
    setChallenge(null);
    setPassword('');
    setConfirm('');
    setAcknowledged(false);
    setError('');
  };

  // Request email verification code
  const requestCode = async () => {
    if (!action) return;

    setError('');

    if (action === 'password' && password !== confirm) {
      setError('Your passwords do not match.');
      return;
    }

    setBusy(true);

    try {
      const newChallenge = await accountApi.requestAction(
        action,
        password,
      );

      setChallenge(newChallenge);
    } catch (err) {
      setError(
        err instanceof Error
          ? err.message
          : 'Unable to send the verification email.',
      );
    } finally {
      setBusy(false);
    }
  };

  // Verify email code and complete the selected action
  const verifyAction = async (code: string) => {
    if (!challenge || !action) return;

    setBusy(true);
    setError('');

    try {
      const result = await accountApi.confirmAction(
        action,
        challenge.challengeId,
        code,
      );

      logout();

      navigate('/login', {
        replace: true,
        state: {
          message: result.message,
        },
      });
    } catch (err) {
      setError(
        err instanceof Error
          ? err.message
          : 'Unable to confirm this action.',
      );
    } finally {
      setBusy(false);
    }
  };

  return (
    <main className="account-page">
      {/* Page Header */}
      <header>
        <p className="eyebrow">YOUR SMART SOLAR ACCOUNT</p>

        <h1>Account & security</h1>

        <p className="auth-intro">
          Manage your details and protect access to your solar project.
        </p>
      </header>

      {/* Profile */}
      <section className="glass-panel account-card">
        <h2>Profile</h2>

        <dl className="profile-details">
          <div>
            <dt>Full name</dt>
            <dd>{user?.fullName}</dd>
          </div>

          <div>
            <dt>Email address</dt>
            <dd>{user?.email}</dd>
          </div>

          <div>
            <dt>Phone number</dt>
            <dd>{user?.phoneNumber || 'Not provided'}</dd>
          </div>
        </dl>
      </section>

      {/* Security Options */}
      {!action ? (
        <div className="security-grid">

          {/* Change Password */}
          <section className="glass-panel account-card">
            <h2>Change password</h2>

            <p>
              Choose a new password, then confirm it with a code
              sent to your email. You’ll be signed out on every device.
            </p>

            <button
              className="btn btn-secondary"
              onClick={() => setAction('password')}
            >
              Change password
            </button>
          </section>

          {/* Delete Account */}
          <section className="glass-panel account-card danger-card">
            <h2>Delete account</h2>

            <p>
              Permanently remove your sign-in access and profile
              details. This action requires email verification.
            </p>

            <button
              className="btn btn-danger"
              onClick={() => setAction('account-deletion')}
            >
              Delete account
            </button>
          </section>
        </div>
      ) : (
        <section
          className={`glass-panel account-card security-flow ${
            action === 'account-deletion'
              ? 'danger-card'
              : ''
          }`}
        >
          <h2>
            {action === 'password'
              ? 'Set a new password'
              : 'Confirm account deletion'}
          </h2>

          {/* Error Message */}
          {error && (
            <p className="account-error" role="alert">
              {error}
            </p>
          )}

          {/* Email Verification */}
          {challenge ? (
            <EmailCodeForm
              challenge={challenge}
              busy={busy}
              onResend={requestCode}
              onBack={reset}
              label={
                action === 'password'
                  ? 'Verify & change password'
                  : 'Verify & delete my account'
              }
              onVerify={verifyAction}
            />
          ) : (
            <AuthForm
              className="account-form"
              onSubmit={(e) => {
                e.preventDefault();
                void requestCode();
              }}
            >
              {/* Change Password Form */}
              {action === 'password' ? (
                <>
                  <AuthField
                    label="New password"
                    hint="Use 12–64 characters. All current sessions will end after verification."
                    id="new-password"
                    className="input-field"
                    type="password"
                    autoComplete="new-password"
                    minLength={12}
                    maxLength={64}
                    required
                    value={password}
                    onChange={(e) =>
                      setPassword(e.target.value)
                    }
                    disabled={busy}
                  />

                  <AuthField
                    label="Confirm new password"
                    matchValue={password}
                    id="confirm-password"
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
                </>
              ) : (
                /* Delete Account Form */
                <>
                  <p>
                    Your login and profile contact details will be
                    removed. Installation, survey, safety and approval
                    records will remain in the project’s audit history.
                    This does not cancel an installation or remove
                    information already included in those records.
                  </p>

                  <label className="delete-acknowledgement">
                    <input
                      type="checkbox"
                      required
                      checked={acknowledged}
                      onInvalid={(e) => {
                        e.preventDefault();

                        setError(
                          'Please confirm that you understand account deletion cannot be undone.',
                        );
                      }}
                      onChange={(e) => {
                        setAcknowledged(e.target.checked);
                        setError('');
                      }}
                      disabled={busy}
                    />

                    I understand that deleting my account cannot
                    be undone.
                  </label>
                </>
              )}

              {/* Submit */}
              <button
                className={`btn ${
                  action === 'password'
                    ? 'btn-primary'
                    : 'btn-danger'
                }`}
                disabled={busy}
              >
                {busy
                  ? 'Sending code…'
                  : 'Send verification code'}
              </button>

              {/* Cancel */}
              <button
                className="text-button"
                type="button"
                onClick={reset}
                disabled={busy}
              >
                Cancel
              </button>
            </AuthForm>
          )}
        </section>
      )}
    </main>
  );
}
