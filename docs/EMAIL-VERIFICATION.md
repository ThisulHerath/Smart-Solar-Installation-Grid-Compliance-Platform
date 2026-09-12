# Email verification and account security

The web login no longer contains demo account buttons or passwords. Public registration creates HOMEOWNER accounts only, after email verification. Existing accounts and project records are preserved.

## Gmail setup

For a provider that does not need a Google App Password, use [Brevo setup](BREVO-SETUP.md). Select it with `EMAIL_PROVIDER=brevo`; its credentials are stored separately from Gmail credentials. Use `EMAIL_PROVIDER=smtp` for the Gmail instructions below or another STARTTLS SMTP relay.

1. Enable 2-Step Verification on the sending Google account.
2. Create a Google App Password for “Smart Solar” at https://myaccount.google.com/apppasswords.
3. In the root `.env`, set `SMTP_USERNAME` to the sending Gmail address and `SMTP_PASSWORD` to the generated App Password (remove display spaces). Do not use your regular Google password. Keep secrets out of Git and chat.
4. Keep `SMTP_HOST=smtp.gmail.com` and `SMTP_PORT=587`. STARTTLS is required. Leave `SMTP_FROM_EMAIL` unset or use an authorized sender alias.
5. Restart the API after editing `.env`. Hosted environments must configure these as secrets.
6. Register through `/register` using an inbox you control. Verify the received six-digit code, then open Account & security to test password change or deletion on your own disposable account.

Google's instructions: https://support.google.com/accounts/answer/185833

Missing or rejected SMTP credentials produce a safe service-unavailable error. No account is created and no OTP is exposed in API responses or logs. Automated tests inject a private in-memory mailbox; this is not a runtime bypass.

## API contract

- `POST /api/auth/register/request-otp`: name, email, optional phone, password. Returns challenge ID, masked address, expiry and resend delay. It does not create a user.
- `POST /api/auth/register`: challengeId and code. Creates a verified homeowner and returns the session.
- `POST /api/auth/password/request-otp`: authenticated, newPassword. Sends to the current user's email.
- `POST /api/auth/password/confirm`: authenticated, challengeId and code. Changes the password and invalidates every previous session.
- `POST /api/auth/account-deletion/request-otp`: authenticated, empty body.
- `POST /api/auth/account-deletion/confirm`: authenticated, challengeId and code. Disables the account, replaces its email/name, clears profile contact details and invalidates all sessions.

Passwords must contain 12–64 characters and fit BCrypt's 72-byte input limit. Codes are cryptographically random, six digits, HMAC hashed with a server secret, valid for ten minutes and consumed once. Five wrong attempts invalidate a code. Requests are limited to one per address per minute and five per hour, with an additional IP limit of twenty authentication calls per minute. PostgreSQL serializable transactions protect concurrent issuance; concurrency tokens prevent simultaneous replay. Multiple hosting instances should additionally share edge rate limits for IP traffic.

Use `OTP_HASH_KEY` for a separate HMAC secret if desired; otherwise the JWT signing key is used. Changing that key invalidates outstanding codes. No code is stored in plaintext. A cleanup worker clears expired pending credentials every fifteen minutes and removes challenge metadata older than twenty-four hours in bounded batches.

## Deletion scope

Deletion removes login access and account/profile contact fields. The user row remains as an anonymized audit reference. Surveys, inspections, addresses or notes already captured in project records, approvals and installation history are retained. The confirmation screens explicitly explain this before the OTP step. Deletion does not cancel an installation or promise complete erasure of historical records.

## Migration and clients

Apply `20260912043046_AddEmailVerification` before running the new API. It adds the challenge table, email verification date and session version. Legacy tokens without the session-version claim require a fresh login. Both React and Flutter use the same OTP endpoints and expose account security actions.

The local workflow smoke test now uses existing local test identities instead of registering synthetic email addresses without verification. OTP behavior is exercised separately in `EmailVerificationTests` with actual HTTP authentication and an injected mailbox.
