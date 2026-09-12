# Account security update — 12 September 2026

## Verified

- Backend: 91 tests passed, zero skipped with PostgreSQL enabled. The isolated PostgreSQL test applies migrations and confirms that concurrent attempts to verify the same code create exactly one user. The test schema is removed afterward.
- Authentication regression: 14 focused tests passed again after aligning token configuration and rejecting inactive profile requests.
- React: 23 tests passed. Coverage includes registration-before-login, password matching, invalid-code feedback, resend cooldown, password changes, deletion acknowledgement and homeowner assessment submission.
- Python: 38 workflow tests passed, covering workflow tools, compliance input contracts, internal authorization and guardrails.
- Flutter: 14 existing tests and one new OTP-registration widget test passed. Static analysis passed; the updated Android debug APK built successfully.
- Web production build passed. Browser checks confirmed login-to-registration navigation, phone-width content without horizontal overflow, homeowner project loading and account security controls. The browser test account was signed out afterward.
- Migration `20260912043046_AddEmailVerification` was applied to the configured project database.

## Live agent integration

`otp-update-workflow-evidence.json` records a successful local HTTP run, tag `DEMO-DBD2DE8A`, covering sizing, technician readings, compliant field assessment, proposal guardrails, engineer approval, live equipment pricing, reservation, replay protection and release. The workflow uses existing local test identities. It does not bypass registration verification. Synthetic test records are labelled with that tag and remain available for review.

These LangGraph specialists use deterministic rules and tool calls. They are not a hosted LLM. The external exchange-rate call and the configured PostgreSQL database were exercised by the live run.

## Remaining setup

Actual Gmail delivery is not verified: a valid Google App Password must be placed in the private root `.env`. The sender address is configured locally. No regular Gmail password was saved. Until SMTP is configured, account creation fails closed with a service-unavailable message. All OTP HTTP tests use an injected test mailbox; codes are never returned by the application API.

Hosting remains deferred. This is a local application update, not a production deployment. Historical installation and audit records remain after account deletion, as explained on the confirmation screens.
