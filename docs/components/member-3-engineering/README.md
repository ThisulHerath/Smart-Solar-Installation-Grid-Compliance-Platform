# Member 3 — Engineering proposal and approval

Owns proposal generation and display, technician evidence review, safety assessment, deterministic validation, revision requests, approval/rejection, and the approval audit history.

- Backend: `backend/SolarPlatform.Api/Features/Engineering`
- React: `frontend-web/src/features/engineering`
- Flutter: `frontend-mobile/lib/features/engineering`
- AI: `agentic-ai/app/features/engineering`
- Backend tests: `backend/SolarPlatform.Tests/Features/Engineering`

The `SafetyGuardrailAgent` explains safety and approval risk. The deterministic proposal validator enforces mandatory compliance and engineering rules. A human engineer makes the final recorded decision, so agent output cannot silently approve a project.

Demo: open a proposal, inspect the technician's Cloudinary photographs, explain the safety result, show a blocked invalid approval, request a revision, then approve a valid proposal and display the audit entry.
