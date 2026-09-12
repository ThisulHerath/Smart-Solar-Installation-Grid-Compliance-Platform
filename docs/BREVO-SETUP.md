# Brevo OTP email setup

The application supports Brevo SMTP for registration, password-change and account-deletion codes. No Google App Password is needed.

1. Create your own account at https://www.brevo.com/ and complete any requested account verification.
2. In Brevo, add a sender and verify its email address. Complete domain authentication if requested. For public deployment, use an authenticated domain you control. A free-address sender may be rewritten by Brevo to meet delivery requirements.
3. Confirm transactional email sending is activated for the account.
4. Open Brevo's SMTP settings. Copy the **SMTP login** and create an **SMTP key**. The SMTP login may differ from your sign-in email. Do not use the Brevo account password or an API key.
5. Fill these values in the project's private root `.env`:

```dotenv
EMAIL_PROVIDER=brevo
BREVO_SMTP_LOGIN=your-SMTP-login-from-Brevo
BREVO_SMTP_KEY=your-generated-SMTP-key
BREVO_FROM_EMAIL=your-verified-sender-address
```

6. Restart the API. Register with an inbox you control and verify receipt of the code. Successful SMTP authentication alone does not prove inbox delivery; check Brevo's transactional logs if sending is accepted but no email arrives.

The application connects to `smtp-relay.brevo.com:587` with required STARTTLS. It never falls back to Gmail credentials while Brevo is selected. Missing Brevo configuration fails closed: no account is created and no OTP is exposed. Existing OTP expiry, attempt limits, single-use checks and session revocation remain unchanged.

Store secrets only in `.env` or your hosting provider's secret settings. No credentials or emails were sent to Brevo while preparing this integration. Provider authentication and actual delivery still require your account settings.

Official references:
- https://help.brevo.com/hc/en-us/articles/7924908994450-Send-transactional-emails-using-Brevo-SMTP
- https://help.brevo.com/hc/en-us/articles/208836149-Create-a-new-sender-From-name-and-From-email
- https://help.brevo.com/hc/en-us/articles/115000188150-Troubleshooting-Issues-with-Brevo-SMTP
