# Member 2 — Field operations and grid compliance

Owns technician assignment, job status, customer navigation, GPS check-in, draft inspections, site photos, electrical telemetry, submission, and grid-compliance evaluation.

- Backend: `backend/SolarPlatform.Api/Features/FieldOperations`
- React: `frontend-web/src/features/field-operations`
- Flutter: `frontend-mobile/lib/features/field_operations`
- AI: `agentic-ai/app/features/field_operations`
- Backend tests: `backend/SolarPlatform.Tests/Features/FieldOperations`

The `GridComplianceAgent` evaluates the submitted inspection with retrieved project guidance. The compliance validator independently checks required readings and limits before the result is accepted. This feature also demonstrates tool use through `ProjectKnowledgeTool`.

Demo: assign a technician, open directions, record GPS, save and reopen an incomplete draft, upload four photo types, submit telemetry, and show the compliance result and cited rules.
