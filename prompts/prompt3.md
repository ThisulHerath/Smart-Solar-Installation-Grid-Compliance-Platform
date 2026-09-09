Continue the SE3090 Smart Solar Installation & Grid Compliance Platform.

Phase 1 and Phase 2 are already implemented. DO NOT rebuild or replace them.

FIRST:
1. Inspect the current repository.
2. Inspect existing Neon/EF Core migrations, entities, services, APIs, React, Flutter, LangGraph workflow and tests.
3. Confirm Phase 2 survey functionality still works.
4. Reuse existing patterns/components.
5. Do not make destructive DB changes.

==================================================
PHASE 3 — FIELD TECHNICIAN + GRID COMPLIANCE
==================================================

Build the second complete vertical slice:

Field Technician Site Operations & Grid Compliance.

The feature must span:
Neon PostgreSQL → EF Core → ASP.NET Core → React → Flutter → Agentic AI → tests.

DO NOT build the inventory, utility filing, quotation or final approval systems yet.

==================================================
BUSINESS FLOW
==================================================

Phase 2 SolarSurvey
→ FieldJob
→ Technician Flutter app
→ Accept job
→ GPS check-in
→ Site inspection
→ Electrical/site telemetry
→ Site photos
→ Submit inspection
→ ASP.NET Core
→ Neon
→ GridComplianceAgent
→ deterministic compliance validation
→ ComplianceAssessment
→ React engineering dashboard
→ updated status visible to technician.

==================================================
DATABASE
==================================================

Extend the existing EF Core model with:

FieldJob
- Id
- SolarSurveyId
- TechnicianId
- AssignedAt
- ScheduledAt
- Status
- Priority
- CreatedAt
- UpdatedAt

SiteInspection
- Id
- FieldJobId
- CheckInLatitude
- CheckInLongitude
- CheckInAt
- RoofAreaMeasuredSqm
- RoofOrientation
- RoofTilt
- GridTypeObserved
- PhaseCount
- MainBreakerRating
- InverterLocationSuitable
- SafetyNotes
- TechnicianNotes
- InspectionStatus
- CreatedAt
- UpdatedAt

SiteTelemetry
- Id
- SiteInspectionId
- MeasurementType
- MeasurementValue
- Unit
- RecordedAt

SitePhoto
- Id
- SiteInspectionId
- PhotoType
- FileUrl
- FileName
- CreatedAt

ComplianceAssessment
- Id
- SiteInspectionId
- WorkflowId
- GridCompliant
- ComplianceStatus
- RiskLevel
- ComplianceNotes
- ValidationStatus
- CreatedAt
- UpdatedAt

Use proper FK relationships, indexes, constraints and audit fields.

Create a new EF Core migration.

Use Neon PostgreSQL. Do not create or switch to another database.

==================================================
FIELD JOB STATUS
==================================================

Use controlled transitions such as:

ASSIGNED
→ ACCEPTED
→ IN_PROGRESS
→ SUBMITTED
→ COMPLIANCE_PROCESSING
→ COMPLIANCE_COMPLETE

Failure:
→ FAILED

Technicians must not arbitrarily set system status.

==================================================
API
==================================================

Implement at least:

GET  /api/technician/jobs
GET  /api/technician/jobs/{id}
POST /api/technician/jobs/{id}/accept
POST /api/technician/jobs/{id}/checkin
POST /api/technician/jobs/{id}/inspection
POST /api/technician/jobs/{id}/telemetry
POST /api/technician/jobs/{id}/photos
POST /api/technician/jobs/{id}/submit
GET  /api/technician/jobs/{id}/compliance

Requirements:
- JWT authentication
- FIELD_TECHNICIAN authorization
- server-side ownership checks
- DTOs
- validation
- async operations
- correct HTTP status codes
- safe error handling

Never trust technicianId from the client; derive it from JWT claims.

==================================================
GPS + INSPECTION
==================================================

Flutter technician workflow must support:

- assigned jobs
- job details
- GPS check-in
- site inspection form
- telemetry
- site photo capture/selection
- submission
- compliance status

GPS:
- latitude -90..90
- longitude -180..180
- timestamp required

Inspection should include:
- measured roof area
- orientation
- tilt
- observed grid type
- phase count
- breaker rating
- inverter location suitability
- safety notes
- technician notes

==================================================
TELEMETRY
==================================================

Use structured telemetry.

Example:

{
  "measurementType": "Voc",
  "measurementValue": 420.5,
  "unit": "V"
}

Validate supported types, numeric values and reasonable ranges.

==================================================
PHOTO UPLOAD
==================================================

Allow site evidence photos.

Examples:
- roof
- meter
- electrical panel
- inverter location
- safety issue

Validate MIME type, extension and file size.

Flutter uploads through ASP.NET Core only.

Store metadata in Neon.

Use a file-storage abstraction so storage can be replaced later.

==================================================
AGENTIC AI
==================================================

Implement the SECOND real production agent:

GridComplianceAgent

Reuse the existing LangGraph architecture from Phase 1/2.

Input:
- SolarSurvey
- SiteInspection
- relevant telemetry
- project-defined compliance inputs

Output must be structured/Pydantic validated.

Example:

{
  "gridCompliant": false,
  "complianceStatus": "REQUIRES_REVIEW",
  "riskLevel": "HIGH",
  "issues": [],
  "recommendations": []
}

Do not trust free-form AI output.

==================================================
COMPLIANCE RULE
==================================================

Implement the project-defined rule:

Single-Phase systems > 5 kW are non-compliant / require review.

Example:

Single-Phase + 8 kW
→ gridCompliant = false

Do NOT invent additional CEB/LECO statutory rules.

Any additional rules must be explicitly documented as project assumptions.

==================================================
DETERMINISTIC VALIDATION
==================================================

Create a validator outside the LLM.

It must independently verify:
- grid type
- recommended kW
- 5 kW single-phase limit
- required fields
- telemetry validity
- output schema

Example:

Input:
Single-Phase
8 kW

If AI returns:
gridCompliant = true

The deterministic validator MUST reject the result.

Never allow the LLM to override business rules.

==================================================
LANGGRAPH WORKFLOW
==================================================

Extend the existing workflow:

START
→ load inspection context
→ GridComplianceAgent
→ deterministic validator
→ persist result
→ COMPLETE / FAILED

Persist structured workflow information:
- workflow ID
- objective
- current step
- completed steps
- validation results
- errors
- final outcome
- execution logs

Do not store hidden chain-of-thought.

==================================================
REACT
==================================================

Extend the existing React application.

Add:
- Field Jobs
- Job Details
- Site Inspection
- Telemetry
- Photos
- Compliance Assessment
- AI execution summary

Show:
- status
- technician
- inspection data
- telemetry
- evidence photos
- compliance status
- risk level
- issues
- validation result
- errors/timing where useful

Do NOT implement final approval yet.

==================================================
SECURITY
==================================================

Verify:
- technician cannot access another technician's job
- wrong roles are rejected
- invalid GPS is rejected
- invalid telemetry is rejected
- invalid files are rejected
- clients do not access Neon directly
- clients do not access FastAPI directly
- AI service remains internal to ASP.NET Core

==================================================
TESTING
==================================================

Add meaningful tests for:

Backend:
- technician jobs
- authorization
- ownership
- accept job
- GPS
- inspection
- telemetry
- photo validation
- submit
- status transitions
- compliance retrieval

Agent:
- compliant case
- non-compliant case
- incorrect AI result rejected
- malformed output
- timeout/unavailable AI

React:
- jobs
- details
- compliance result
- loading/error states

Flutter:
- technician navigation
- jobs
- inspection validation
- GPS
- photo flow

==================================================
GOLDEN CASES
==================================================

Case 1:
600 kWh
→ 5.0 kW
→ Single-Phase
→ EXPECT COMPLIANT

Case 2:
960 kWh
→ 8.0 kW
→ Single-Phase
→ EXPECT NON_COMPLIANT / REQUIRES_REVIEW

Case 3:
AI claims 8 kW Single-Phase is compliant
→ deterministic validator MUST reject

Case 4:
Malformed AI response
→ safe failure

Case 5:
AI unavailable
→ controlled failure, no fake compliance result

==================================================
GIT
==================================================

Use a feature branch:

feature/field-technician-compliance

Use meaningful commits. Do not fabricate commit history.

==================================================
DOCUMENTATION
==================================================

Update only the relevant docs:

docs/database/field-technician-design.md
docs/api/technician-api.md
docs/architecture/field-inspection-flow.md
docs/agentic-ai/grid-compliance-agent.md
docs/testing/phase-3-test-plan.md

Document project rules vs actual external regulations clearly.

==================================================
DO NOT IMPLEMENT YET
==================================================

Do not build:
- final human approval
- inventory
- utility filing
- quotation
- equipment reservation
- full final proposal workflow

==================================================
DEFINITION OF DONE
==================================================

[ ] New Neon tables/entities work
[ ] EF migration created and applied
[ ] Technician API works
[ ] Technician ownership enforced
[ ] GPS check-in works
[ ] Inspection works
[ ] Telemetry works
[ ] Photos work
[ ] GridComplianceAgent works
[ ] Deterministic validation works
[ ] Workflow state persisted
[ ] React dashboard works
[ ] Flutter technician workflow works
[ ] Golden cases pass
[ ] AI failure is handled safely
[ ] Backend/AI/frontend/mobile tests pass
[ ] Existing Phase 1/2 functionality still works
[ ] No destructive DB changes
[ ] No secrets committed

IMPORTANT:
Run actual builds and tests after implementation.
Fix real errors.
Do not claim success without verification.
STOP after Phase 3.