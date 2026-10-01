import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import {
  ShieldCheck,
  KeyRound,
  Trash2,
  User,
  Mail,
  Phone,
  AlertTriangle,
  CheckCircle2,
  Eye,
  EyeOff,
  ArrowLeft,
  ArrowUpRight,
  Lock,
  Check,
  CircleAlert,
  Send,
  Shield,
  Clock,
  Sparkles,
  UserCheck,
} from 'lucide-react';

import { EmailCodeForm } from '../components/EmailCodeForm';
import { DestructiveConfirmDialog } from '../components/DestructiveConfirmDialog';
import { useAuth } from '../context/AuthContext';
import {
  accountApi,
  AccountAction,
  Challenge,
} from '../services/account';

import '../styles/account.css';

export function AccountPage() {
  const { user, profilePhoto, logout } = useAuth();
  const navigate = useNavigate();

  const [action, setAction] = useState<AccountAction | null>(null);
  const [challenge, setChallenge] = useState<Challenge | null>(null);

  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [acknowledged, setAcknowledged] = useState(false);

  const [showPassword, setShowPassword] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
  const [touchedPassword, setTouchedPassword] = useState(false);
  const [touchedConfirm, setTouchedConfirm] = useState(false);

  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);

  // Password validation criteria
  const hasMinLength = password.length >= 12 && password.length <= 64;
  const hasUpper = /[A-Z]/.test(password);
  const hasLower = /[a-z]/.test(password);
  const hasNumber = /[0-9]/.test(password);
  const hasSpecial = /[^A-Za-z0-9]/.test(password);
  const byteCount = new TextEncoder().encode(password).length;
  const isByteValid = byteCount <= 72;

  // Strength computation (0 to 4)
  let strengthScore = 0;
  if (hasMinLength && isByteValid) strengthScore++;
  if (hasUpper && hasLower) strengthScore++;
  if (hasNumber) strengthScore++;
  if (hasSpecial) strengthScore++;

  const strengthLabels = ['Too weak', 'Weak', 'Fair', 'Good', 'Strong'];
  const strengthClass = !password
    ? ''
    : strengthScore <= 1
      ? 'strength-weak'
      : strengthScore === 2
        ? 'strength-fair'
        : strengthScore === 3
          ? 'strength-good'
          : 'strength-strong';

  const passwordsMatch = confirm.length > 0 && password === confirm;
  const passwordsMismatch = confirm.length > 0 && password !== confirm;

  // Reset the current security flow
  const reset = () => {
    setAction(null);
    setChallenge(null);
    setPassword('');
    setConfirm('');
    setAcknowledged(false);
    setShowPassword(false);
    setShowConfirm(false);
    setTouchedPassword(false);
    setTouchedConfirm(false);
    setError('');
  };

  // Request email verification code
  const requestCode = async () => {
    if (!action) return;

    setError('');

    if (action === 'password') {
      if (password.length < 12) {
        setError('Use at least 12 characters for your password.');
        return;
      }
      if (password.length > 64) {
        setError('Use no more than 64 characters for your password.');
        return;
      }
      if (!isByteValid) {
        setError('This password is too long in bytes (max 72 UTF-8 bytes).');
        return;
      }
      if (password !== confirm) {
        setError('Your passwords do not match.');
        return;
      }
    }

    if (action === 'account-deletion' && !acknowledged) {
      setError('Please confirm that you understand account deletion cannot be undone.');
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

  const initials = user?.fullName
    ? user.fullName
        .split(' ')
        .filter(Boolean)
        .slice(0, 2)
        .map((part) => part[0])
        .join('')
        .toUpperCase()
    : 'U';

  const userRole = user?.roles?.[0]
    ? user.roles[0]
        .replace(/_/g, ' ')
        .toLowerCase()
        .replace(/\b\w/g, (l) => l.toUpperCase())
    : 'Member';

  return (
    <main className="account-page">
      {/* Account Navigation Tabs */}
      <nav className="account-nav-tabs" aria-label="Account sections">
        <Link to="/profile" className="account-nav-tab">
          <User size={16} />
          <span>My Profile</span>
        </Link>
        <span className="account-nav-tab is-active" aria-current="page">
          <ShieldCheck size={16} />
          <span>Account & Security</span>
        </span>
      </nav>

      {/* Page Header */}
      <header className="account-header">
        <div className="account-eyebrow-wrap">
          <span className="account-eyebrow-badge">
            <ShieldCheck size={14} />
            <span className="eyebrow">YOUR SMART SOLAR ACCOUNT</span>
          </span>
        </div>

        <h1>Account & security</h1>

        <p className="auth-intro">
          Manage your credentials, authentication methods, and account security.
        </p>
      </header>

      {/* Profile Overview Card */}
      <section className="glass-panel account-card profile-overview-card">
        <div className="profile-card-header">
          <div className="profile-card-user">
            <div className="profile-card-avatar" aria-hidden="true">
              {profilePhoto ? (
                <img src={profilePhoto} alt="" />
              ) : (
                <span>{initials}</span>
              )}
            </div>
            <div>
              <h2>Profile</h2>
              <div className="profile-badge-row">
                <span className="badge badge-emerald">
                  <UserCheck size={12} /> {userRole}
                </span>
                <span className="badge badge-subtle">
                  <CheckCircle2 size={12} /> Active
                </span>
              </div>
            </div>
          </div>

          <Link to="/profile" className="btn btn-secondary edit-profile-link">
            <span>Edit profile details</span>
            <ArrowUpRight size={14} />
          </Link>
        </div>

        <dl className="profile-details">
          <div className="profile-detail-item">
            <dt>
              <User size={15} className="detail-icon" />
              <span>Full name</span>
            </dt>
            <dd>{user?.fullName || 'Not provided'}</dd>
          </div>

          <div className="profile-detail-item">
            <dt>
              <Mail size={15} className="detail-icon" />
              <span>Email address</span>
            </dt>
            <dd>
              <span className="email-text">{user?.email}</span>
              <span className="verified-pill" title="Email is verified">
                <CheckCircle2 size={12} /> Verified
              </span>
            </dd>
          </div>

          <div className="profile-detail-item">
            <dt>
              <Phone size={15} className="detail-icon" />
              <span>Phone number</span>
            </dt>
            <dd>{user?.phoneNumber || 'Not provided'}</dd>
          </div>

          <div className="profile-detail-item">
            <dt>
              <ShieldCheck size={15} className="detail-icon" />
              <span>Authentication</span>
            </dt>
            <dd className="auth-status-dd">
              <span className="shield-tag">Two-Step Email OTP Protected</span>
            </dd>
          </div>
        </dl>
      </section>

      {/* Security Actions Grid */}
      {!action ? (
        <div className="security-grid">
          {/* Change Password Card */}
          <section className="glass-panel account-card security-feature-card">
            <div className="feature-card-top">
              <div className="feature-icon-bubble">
                <KeyRound size={24} />
              </div>
              <div>
                <h2>Change password</h2>
                <span className="feature-tag">Credential Update</span>
              </div>
            </div>

            <p>
              Choose a new password, then confirm it with a code sent to your
              email. You’ll be signed out on every device.
            </p>

            <ul className="security-check-list">
              <li>
                <Check size={14} />
                <span>Requires at least 12 characters</span>
              </li>
              <li>
                <Check size={14} />
                <span>One-time security code sent to verified email</span>
              </li>
              <li>
                <Check size={14} />
                <span>Safely invalidates older browser sessions</span>
              </li>
            </ul>

            <button
              className="btn btn-primary security-action-btn"
              onClick={() => setAction('password')}
            >
              <KeyRound size={16} />
              <span>Change password</span>
            </button>
          </section>

          {/* Delete Account Card */}
          <section className="glass-panel account-card danger-card security-feature-card">
            <div className="feature-card-top">
              <div className="feature-icon-bubble danger-bubble">
                <Trash2 size={24} />
              </div>
              <div>
                <h2>Delete account</h2>
                <span className="feature-tag danger-tag">Irreversible Action</span>
              </div>
            </div>

            <p>
              Permanently remove your sign-in access and profile details. This
              action requires email verification.
            </p>

            <ul className="security-check-list danger-check-list">
              <li>
                <AlertTriangle size={14} />
                <span>Revokes all logins and API access immediately</span>
              </li>
              <li>
                <Shield size={14} />
                <span>Retains compliance, inspection & audit logs</span>
              </li>
              <li>
                <Clock size={14} />
                <span>Requires 2FA code authorization before deletion</span>
              </li>
            </ul>

            <button
              className="btn btn-danger security-action-btn"
              onClick={() => setShowDeleteConfirm(true)}
            >
              <Trash2 size={16} />
              <span>Delete account</span>
            </button>
          </section>
        </div>
      ) : (
        /* Security Flow Sub-Panel (Password Change / Account Deletion) */
        <section
          className={`glass-panel account-card security-flow ${
            action === 'account-deletion' ? 'danger-flow-card' : ''
          }`}
        >
          {/* Flow Header with Back Button */}
          <div className="flow-header">
            <button
              type="button"
              className="flow-back-btn"
              onClick={reset}
              disabled={busy}
            >
              <ArrowLeft size={16} />
              <span>Back to security options</span>
            </button>

            <div className="flow-title-row">
              <div
                className={`flow-icon-bubble ${
                  action === 'account-deletion' ? 'danger-bubble' : ''
                }`}
              >
                {action === 'password' ? (
                  <KeyRound size={22} />
                ) : (
                  <AlertTriangle size={22} />
                )}
              </div>
              <div>
                <h2>
                  {action === 'password'
                    ? 'Set a new password'
                    : 'Confirm account deletion'}
                </h2>
                <p className="flow-subtitle">
                  {action === 'password'
                    ? 'Enter your new credentials below. All active sessions will end after email confirmation.'
                    : 'Please review the consequences of deleting your account.'}
                </p>
              </div>
            </div>
          </div>

          {/* Error Banner */}
          {error && (
            <div className="account-alert account-alert-error" role="alert">
              <CircleAlert size={18} />
              <span>{error}</span>
            </div>
          )}

          {/* Email Verification Form (Challenge) */}
          {challenge ? (
            <div className="challenge-form-wrapper">
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
            </div>
          ) : action === 'password' ? (
            /* Change Password Interactive Form with Validations */
            <form
              className="account-form"
              noValidate
              onSubmit={(e) => {
                e.preventDefault();
                void requestCode();
              }}
            >
              {/* New Password Field */}
              <div className="form-group">
                <div className="label-row">
                  <label htmlFor="new-password">New password</label>
                  <span className="field-hint-tag">12–64 characters</span>
                </div>
                <div className="input-wrap">
                  <Lock size={17} className="input-icon-left" />
                  <input
                    id="new-password"
                    name="new-password"
                    type={showPassword ? 'text' : 'password'}
                    className={`input-field has-left-icon ${
                      touchedPassword && !hasMinLength && password.length > 0
                        ? 'input-error'
                        : ''
                    }`}
                    autoComplete="new-password"
                    minLength={12}
                    maxLength={64}
                    required
                    placeholder="Enter your new password"
                    value={password}
                    disabled={busy}
                    onChange={(e) => {
                      setPassword(e.target.value);
                      if (error) setError('');
                    }}
                    onBlur={() => setTouchedPassword(true)}
                  />
                  <button
                    type="button"
                    className="password-toggle-btn"
                    onClick={() => setShowPassword(!showPassword)}
                    aria-label={showPassword ? 'Hide password' : 'Show password'}
                    tabIndex={-1}
                  >
                    {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                  </button>
                </div>

                {/* Password Strength Meter */}
                {password.length > 0 && (
                  <div className={`password-strength-meter ${strengthClass}`}>
                    <div className="strength-header">
                      <span>Password strength:</span>
                      <strong className="strength-label">
                        {strengthLabels[strengthScore]}
                      </strong>
                    </div>
                    <div className="strength-bar-track">
                      <div
                        className="strength-bar-fill"
                        style={{ width: `${(strengthScore / 4) * 100}%` }}
                      />
                    </div>
                  </div>
                )}

                {/* Password Requirements Checklist */}
                <div className="password-requirements-card">
                  <p className="requirements-title">
                    <Sparkles size={13} />
                    <span>Password requirements:</span>
                  </p>
                  <ul className="requirements-list">
                    <li className={hasMinLength ? 'is-met' : ''}>
                      {hasMinLength ? (
                        <CheckCircle2 size={14} className="req-icon met" />
                      ) : (
                        <span className="req-bullet" />
                      )}
                      <span>At least 12 characters (required)</span>
                    </li>
                    <li className={hasUpper && hasLower ? 'is-met' : ''}>
                      {hasUpper && hasLower ? (
                        <CheckCircle2 size={14} className="req-icon met" />
                      ) : (
                        <span className="req-bullet" />
                      )}
                      <span>Uppercase & lowercase letters</span>
                    </li>
                    <li className={hasNumber ? 'is-met' : ''}>
                      {hasNumber ? (
                        <CheckCircle2 size={14} className="req-icon met" />
                      ) : (
                        <span className="req-bullet" />
                      )}
                      <span>At least one number (0–9)</span>
                    </li>
                    <li className={hasSpecial ? 'is-met' : ''}>
                      {hasSpecial ? (
                        <CheckCircle2 size={14} className="req-icon met" />
                      ) : (
                        <span className="req-bullet" />
                      )}
                      <span>At least one symbol (!@#$...)</span>
                    </li>
                  </ul>
                </div>
              </div>

              {/* Confirm Password Field */}
              <div className="form-group">
                <div className="label-row">
                  <label htmlFor="confirm-password">Confirm new password</label>
                  {passwordsMatch && (
                    <span className="match-tag match-success">
                      <Check size={12} /> Passwords match
                    </span>
                  )}
                  {passwordsMismatch && (
                    <span className="match-tag match-error">
                      <CircleAlert size={12} /> Passwords do not match
                    </span>
                  )}
                </div>
                <div className="input-wrap">
                  <Lock size={17} className="input-icon-left" />
                  <input
                    id="confirm-password"
                    name="confirm-password"
                    type={showConfirm ? 'text' : 'password'}
                    className={`input-field has-left-icon ${
                      passwordsMismatch ? 'input-error' : passwordsMatch ? 'input-success' : ''
                    }`}
                    autoComplete="new-password"
                    required
                    placeholder="Re-enter your new password"
                    value={confirm}
                    disabled={busy}
                    onChange={(e) => {
                      setConfirm(e.target.value);
                      if (error) setError('');
                    }}
                    onBlur={() => setTouchedConfirm(true)}
                  />
                  <button
                    type="button"
                    className="password-toggle-btn"
                    onClick={() => setShowConfirm(!showConfirm)}
                    aria-label={
                      showConfirm ? 'Hide confirm password' : 'Show confirm password'
                    }
                    tabIndex={-1}
                  >
                    {showConfirm ? <EyeOff size={18} /> : <Eye size={18} />}
                  </button>
                </div>
                {touchedConfirm && passwordsMismatch && (
                  <p className="field-validation-error">
                    <CircleAlert size={13} /> Your passwords do not match.
                  </p>
                )}
              </div>

              {/* Security Hint */}
              <div className="security-notice-callout">
                <ShieldCheck size={16} />
                <span>
                  All current web & mobile sessions will be terminated once your new
                  password is verified.
                </span>
              </div>

              {/* Action Buttons */}
              <div className="form-actions">
                <button
                  type="submit"
                  className="btn btn-primary flow-submit-btn"
                  disabled={busy}
                >
                  <Send size={16} />
                  <span>
                    {busy ? 'Sending code…' : 'Send verification code'}
                  </span>
                </button>

                <button
                  className="text-button"
                  type="button"
                  onClick={reset}
                  disabled={busy}
                >
                  Cancel
                </button>
              </div>
            </form>
          ) : (
            /* Delete Account Form */
            <form
              className="account-form danger-form"
              noValidate
              onSubmit={(e) => {
                e.preventDefault();
                if (!acknowledged) {
                  setError(
                    'Please confirm that you understand account deletion cannot be undone.',
                  );
                  return;
                }
                void requestCode();
              }}
            >
              <div className="danger-explanation-box">
                <AlertTriangle size={22} className="danger-box-icon" />
                <div className="danger-box-content">
                  <strong>Critical: irreversible deletion</strong>
                  <p>
                    Your login and profile contact details will be removed.
                    Installation, survey, safety and approval records will remain in
                    the project’s audit history. This does not cancel an
                    installation or remove information already included in those
                    records.
                  </p>
                </div>
              </div>

              <div className="checkbox-container">
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
                  <span>
                    I understand that deleting my account cannot be undone.
                  </span>
                </label>
              </div>

              {/* Action Buttons */}
              <div className="form-actions">
                <button
                  type="submit"
                  className="btn btn-danger flow-submit-btn"
                  disabled={busy}
                >
                  <Trash2 size={16} />
                  <span>
                    {busy ? 'Sending code…' : 'Send verification code'}
                  </span>
                </button>

                <button
                  className="text-button"
                  type="button"
                  onClick={reset}
                  disabled={busy}
                >
                  Cancel
                </button>
              </div>
            </form>
          )}
        </section>
      )}

      <DestructiveConfirmDialog
        open={showDeleteConfirm}
        title="Delete account?"
        subject={user?.email}
        confirmLabel="Continue to verification"
        onCancel={() => setShowDeleteConfirm(false)}
        onConfirm={() => {
          setShowDeleteConfirm(false);
          setAction('account-deletion');
        }}
      >
        <p>This permanently removes your sign-in access and profile details. You will review retained compliance records and verify this action by email next.</p>
      </DestructiveConfirmDialog>
    </main>
  );
}
