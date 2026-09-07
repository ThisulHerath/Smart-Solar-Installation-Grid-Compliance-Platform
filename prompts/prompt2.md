You are continuing development of the SE3090 Software Engineering Frameworks Assignment 1 project.

PROJECT:
Smart Solar Installation & Grid Compliance Platform

The repository has already completed PHASE 1 FOUNDATION.

IMPORTANT:
Do NOT rebuild or replace Phase 1.

Before modifying anything:
1. Inspect the current repository.
2. Inspect the existing backend, Neon/EF Core setup, React, Flutter, Agentic AI and tests.
3. Verify that Phase 1 components are present.
4. Preserve existing working code.
5. Identify the exact files that need to change.
6. Then implement Phase 2.

The official assignment specification remains the source of truth.

==================================================
PHASE 2
CUSTOMER ONBOARDING + SOLAR SURVEY + SOLAR SIZING
==================================================

Phase 2 implements the FIRST complete business vertical slice.

Primary component:

Customer Onboarding & Solar Survey Management

This component must have technical ownership across:

- PostgreSQL / Neon
- Entity Framework Core
- ASP.NET Core Web API
- React
- Flutter
- testing
- Agentic AI

Do not create a frontend-only feature.

Do not create a backend-only feature.

Do not implement the other three major business components yet.

==================================================
PHASE 2 BUSINESS OBJECTIVE
==================================================

A homeowner should be able to submit a solar installation survey containing:

- electricity consumption information
- roof information
- property details
- grid type
- optional electricity bill image
- optional roof/site image
- location information where available
- preferred installation information where appropriate

The system stores the survey in Neon PostgreSQL and allows the homeowner to track its status.

The survey can then initiate the first Agentic AI workflow.

==================================================
PHASE 2 END-TO-END WORKFLOW
==================================================

Implement this workflow:

HOMEOWNER FLUTTER
        ↓
Create Survey
        ↓
ASP.NET CORE API
        ↓
Validate JWT
        ↓
Validate homeowner ownership
        ↓
Validate input
        ↓
Save SurveyRequest in Neon PostgreSQL
        ↓
Create workflow record
        ↓
Start Agentic AI
        ↓
SOLAR SIZING AGENT
        ↓
Structured result
        ↓
Deterministic validation
        ↓
Save workflow/result
        ↓
React dashboard
        ↓
Engineer/Admin can inspect result
        ↓
Flutter homeowner sees updated status

This is NOT yet the final approval workflow.

Do not implement human approval in Phase 2.

Approval belongs to a later phase.

==================================================
1. DATABASE MODEL
==================================================

Expand the Neon PostgreSQL schema using EF Core migrations.

Create the minimum entities required for the Customer Survey component.

Recommended entities:

User
CustomerProfile
SolarSurvey
SolarSurveyImage
AgentWorkflow

Use existing User/Role entities from Phase 1 where possible.

Do not duplicate authentication tables.

Suggested model:

CustomerProfile
- Id
- UserId
- FullName
- PhoneNumber
- Address
- CreatedAt
- UpdatedAt

SolarSurvey
- Id
- CustomerId
- MonthlyKwh
- RoofAreaSqm
- GridType
- RoofOrientation
- RoofTilt
- PropertyAddress
- Latitude
- Longitude
- SurveyStatus
- Notes
- CreatedAt
- UpdatedAt

SolarSurveyImage
- Id
- SolarSurveyId
- ImageType
- FileUrl
- FileName
- CreatedAt

AgentWorkflow
- Id
- WorkflowId
- SolarSurveyId
- Objective
- Status
- PlanJson
- ResultJson
- ValidationJson
- ErrorMessage
- StartedAt
- CompletedAt
- CreatedAt
- UpdatedAt

Use appropriate relationships.

Example:

User
  1
  |
  1
CustomerProfile
  1
  |
  *
SolarSurvey
  1
  |
  *
SolarSurveyImage

SolarSurvey
  1
  |
  *
AgentWorkflow

Do not over-normalize.

Use proper PostgreSQL data types.

Add:
- primary keys
- foreign keys
- indexes
- constraints
- CreatedAt
- UpdatedAt

Use EF Core migrations.

Do not drop existing production data.

==================================================
2. SURVEY STATUS WORKFLOW
==================================================

Create a controlled status model.

For example:

DRAFT
SUBMITTED
PROCESSING
ANALYSIS_COMPLETE
FAILED
CANCELLED

Do not allow arbitrary strings from the client to change status.

Status transitions must be controlled by backend business logic.

Example:

DRAFT
 ↓
SUBMITTED
 ↓
PROCESSING
 ↓
ANALYSIS_COMPLETE

Failure:

PROCESSING
 ↓
FAILED

Only allow valid transitions.

Document the state machine.

==================================================
3. CUSTOMER API
==================================================

Create REST API endpoints.

At minimum:

GET /api/customer/profile
PUT /api/customer/profile

POST /api/surveys
GET /api/surveys
GET /api/surveys/{id}
PUT /api/surveys/{id}
POST /api/surveys/{id}/submit
GET /api/surveys/{id}/status

Additional endpoints may be created where genuinely necessary.

Minimum individual component requirement:
at least four meaningful API endpoints.

All endpoints must:

- use DTOs
- validate input
- use authorization
- use async operations
- return correct HTTP status codes
- follow REST conventions

==================================================
4. AUTHORIZATION
==================================================

A HOMEOWNER may:

- create their own survey
- view their own surveys
- edit their own DRAFT survey
- submit their own survey
- view their own workflow status

A homeowner must NOT:

- view another customer's survey
- edit another customer's survey
- change system-controlled status
- approve proposals
- access technician information

Use JWT claims and authorization.

Always enforce ownership server-side.

Never trust customerId supplied by the client.

Determine the authenticated user from the JWT.

==================================================
5. SURVEY VALIDATION
==================================================

Implement server-side validation.

At minimum validate:

MonthlyKwh > 0

RoofAreaSqm > 0

Roof measurements are reasonable.

Latitude range:

-90 to 90

Longitude range:

-180 to 180

GridType must be a supported enum/value.

Required customer information must be present.

Do not trust client-side validation alone.

Validate all input again in ASP.NET Core.

Return useful validation errors.

==================================================
6. SOLAR SIZING BUSINESS LOGIC
==================================================

Implement the first Agentic AI domain calculation.

Use the project specification's initial sizing rule:

Recommended kW = Monthly kWh / 120.0

Round to two decimal places.

Example:

Monthly consumption:
1200 kWh

Recommended system:
1200 / 120 = 10.00 kW

IMPORTANT:

Do not let the LLM freely invent this calculation.

The result must ultimately be checked using deterministic business logic.

The AI may plan and produce structured results, but the backend/domain validator must independently verify the calculated value.

==================================================
7. AGENTIC AI — SOLAR SIZING AGENT
==================================================

Phase 2 introduces the FIRST REAL AGENT.

Implement:

PlannerAgent

and/or

SolarSizingAgent

according to the existing architecture from Phase 1.

The agent must have a distinct responsibility.

Responsibility:

Analyze the submitted solar survey and produce a structured preliminary solar system sizing recommendation.

Input contract:

- workflow ID
- customer/survey ID
- monthly kWh
- roof area
- grid type
- relevant survey information

Output contract should contain structured information such as:

{
  "recommendedKw": 10.0,
  "reason": "...",
  "estimatedPanelCount": ...,
  "estimatedInverterKw": ...,
  "assumptions": [...]
}

Do not allow free-form output to become trusted application state.

Use Pydantic schemas.

==================================================
8. AGENTIC AI WORKFLOW
==================================================

Expand the Phase 1 LangGraph skeleton.

Implement at least:

START
 ↓
Planner
 ↓
SolarSizingAgent
 ↓
DeterministicValidator
 ↓
COMPLETE / FAILED

The workflow state must preserve:

workflow_id
customer_id
objective
input_data
plan
current_step
completed_steps
tool_results
validation_results
errors
final_outcome
execution_logs

Do not implement the other three production agents yet.

Create their architecture/interfaces if they already exist, but only SolarSizingAgent becomes functional in Phase 2.

==================================================
9. DETERMINISTIC VALIDATION
==================================================

Implement a deterministic validator outside the LLM.

It must verify:

1. Monthly kWh is valid.
2. Roof area is valid.
3. Recommended kW is mathematically consistent.
4. Panel count is reasonable according to the defined project calculation.
5. Inverter size follows the defined project rule.
6. Required fields are present.
7. Output matches the required schema.

If AI output conflicts with deterministic calculation:

- reject the output
- record validation failure
- mark workflow FAILED or require revision
- do not accept the AI value silently

Do not use LLM-as-judge as the only validator.

==================================================
10. WORKFLOW PERSISTENCE
==================================================

Persist the workflow to Neon.

Store:

- workflow ID
- objective
- survey ID
- plan
- current status
- completed steps
- validation results
- final result
- errors
- timestamps

Do NOT store:
- hidden chain-of-thought
- model private reasoning
- passwords
- access tokens
- unnecessary sensitive information

Store only structured execution information needed for auditability.

==================================================
11. EXECUTION LOGGING
==================================================

Create execution records for:

Planner
SolarSizingAgent
Validator

Record:

AgentName
StepName
Status
StartedAt
CompletedAt
DurationMs
OutputSummary
ValidationResult
ErrorMessage
RetryCount

Do not store secret prompts or sensitive personal information unnecessarily.

==================================================
12. REACT WEB APPLICATION
==================================================

Extend the React application.

Create pages/components for authorized staff to inspect customer surveys.

At minimum implement:

Survey list
Survey details
Survey status
AI analysis result
Validation result
Workflow execution summary

Add:

- loading states
- empty states
- error states
- success states

Use the existing state-management solution from Phase 1.

Do not create a second state-management framework.

Use the ASP.NET Core API only.

React must NEVER connect directly to Neon.

==================================================
13. FLUTTER MOBILE APPLICATION
==================================================

Extend the Flutter application for HOMEOWNER functionality.

Create:

Customer dashboard
New survey form
Survey details
Survey history
Survey status
AI recommendation result

The form should collect:

- monthly electricity usage
- roof area
- grid type
- property address
- location where available
- optional image upload

Prepare image upload architecture.

If image storage is not yet fully deployed, design the API so it can later integrate with a proper object/file storage service.

Do not store large binary images directly in database columns unless there is a justified design decision.

==================================================
14. DEVICE FEATURES
==================================================

Implement at least one meaningful device feature in Phase 2.

Prefer:

Camera/image picker

Allow the homeowner to attach an electricity bill image or roof/site image.

The application should:

- request permission appropriately
- select/capture image
- upload through ASP.NET Core
- associate image metadata with SolarSurvey

Do not expose direct access to storage/database from Flutter.

==================================================
15. FILE UPLOAD SECURITY
==================================================

Validate uploads server-side.

Validate:

- file type
- file extension
- MIME type
- file size

Only allow explicitly permitted image formats.

Reject unsupported files.

Do not trust filename extensions.

Do not allow arbitrary executable uploads.

Do not expose server filesystem paths to users.

Design the storage layer so the storage provider can be changed later.

==================================================
16. CUSTOMER REACT / FLUTTER WORKFLOW
==================================================

Demonstrate this complete process:

1. Homeowner logs in using Flutter.
2. Homeowner creates survey.
3. Survey reaches ASP.NET Core.
4. ASP.NET Core validates JWT and ownership.
5. ASP.NET Core saves survey to Neon.
6. ASP.NET Core creates AgentWorkflow.
7. ASP.NET Core calls internal Agentic AI service.
8. SolarSizingAgent processes the survey.
9. Deterministic validator validates result.
10. Workflow state is persisted.
11. React staff dashboard can inspect result.
12. Flutter homeowner can see updated survey status/result.

React and Flutter must consume the same API and shared data.

==================================================
17. API → AGENTIC AI SECURITY
==================================================

Continue using:

AGENTIC_AI_BASE_URL
AGENTIC_AI_INTERNAL_KEY

ASP.NET Core is the only service allowed to call Agentic AI.

The client applications must never receive direct access to the Agentic AI service.

Protect the internal service with an internal authentication mechanism where appropriate.

Validate all AI service responses.

Set request timeouts.

Handle:

- AI service unavailable
- timeout
- malformed JSON
- validation failure
- unexpected exception

==================================================
18. ERROR AND SAFE FAILURE
==================================================

If AI analysis fails:

Do NOT:
- mark survey as successful
- create fake recommendation
- silently continue

Instead:

Survey:
PROCESSING
     ↓
FAILED

Persist:

- error type
- safe error message
- timestamp

Allow the workflow to be inspected from React.

Do not expose internal stack traces to homeowners.

==================================================
19. TESTING
==================================================

Create meaningful tests for Phase 2.

Backend:

- create survey
- get own survey
- cannot access another user's survey
- update draft survey
- cannot update submitted survey
- submit survey
- invalid monthly kWh
- invalid roof area
- invalid coordinates
- invalid grid type
- status transition tests

Agentic AI:

- valid sizing calculation
- invalid state
- malformed output
- deterministic validation failure
- AI service timeout
- AI service unavailable

Database:

- foreign keys
- migration
- constraints
- relationship integrity

React:

- survey list
- survey details
- loading state
- error state
- protected route

Flutter:

- survey form
- validation
- navigation
- authentication
- image selection/upload where practical

==================================================
20. SECURITY TESTS
==================================================

Test:

- unauthenticated access
- wrong role
- customer accessing another customer's survey
- invalid JWT
- tampered customer ID
- invalid upload
- oversize upload
- malformed request
- invalid Agentic AI result

The server must enforce ownership and authorization.

==================================================
21. DOCUMENTATION
==================================================

Update README.

Add Phase 2 documentation.

Create/update:

docs/database/customer-survey-design.md

docs/api/customer-survey-api.md

docs/architecture/customer-survey-flow.md

docs/agentic-ai/solar-sizing-agent.md

docs/testing/phase-2-test-plan.md

Document:

- business purpose
- entities
- API endpoints
- workflow
- state transitions
- validation rules
- Agentic AI responsibility
- deterministic validation
- Flutter flow
- React flow
- failure behavior

Do not invent test statistics.

==================================================
22. DATABASE MIGRATION SAFETY
==================================================

Use EF Core migrations.

Create a new migration for Phase 2.

Do not:
- drop the database
- reset Neon
- delete production data
- recreate the Neon project

Do not run destructive database commands automatically.

==================================================
23. GIT WORKFLOW
==================================================

Do not work directly in a giant single commit.

Use a feature branch such as:

feature/customer-solar-survey

Make meaningful commits.

Suggested commits:

feat: add customer survey domain
feat: add survey API
feat: add solar sizing agent
feat: add deterministic survey validation
feat: add React survey dashboard
feat: add Flutter survey workflow
test: add customer survey tests
docs: document customer survey workflow

Do not artificially generate commits.

==================================================
24. DEFINITION OF DONE
==================================================

Phase 2 is complete ONLY when:

DATABASE
[ ] CustomerProfile implemented
[ ] SolarSurvey implemented
[ ] SolarSurveyImage implemented
[ ] AgentWorkflow updated
[ ] Relationships correct
[ ] EF Core migration created
[ ] Neon migration applied successfully

BACKEND
[ ] Customer profile endpoints work
[ ] Survey CRUD works
[ ] Survey submission works
[ ] Survey ownership enforced
[ ] Validation works
[ ] Status transitions enforced
[ ] Agent workflow endpoint works
[ ] Errors handled safely

AGENTIC AI
[ ] SolarSizingAgent works
[ ] LangGraph workflow works
[ ] Structured input/output works
[ ] Deterministic validation works
[ ] Workflow state persisted
[ ] Execution logs persisted
[ ] AI failure handled safely

REACT
[ ] Survey dashboard works
[ ] Survey details works
[ ] AI result visible
[ ] Workflow status visible
[ ] Protected routes work
[ ] Error/loading states work

FLUTTER
[ ] New survey works
[ ] Survey history works
[ ] Survey status works
[ ] Image selection/upload works
[ ] AI result visible

TESTING
[ ] Backend tests pass
[ ] AI tests pass
[ ] React tests pass where configured
[ ] Flutter tests pass where configured
[ ] Authorization tests pass
[ ] Validation tests pass

INTEGRATION
[ ] Flutter → ASP.NET Core works
[ ] ASP.NET Core → Neon works
[ ] ASP.NET Core → Agentic AI works
[ ] Agentic AI → ASP.NET Core works
[ ] React → ASP.NET Core works
[ ] Shared data is visible in both clients

==================================================
25. IMPORTANT
==================================================

Do NOT implement:

- field technician component
- full CEB/LECO compliance agent
- full inventory system
- utility filing
- final quotation system
- manager approval
- final multi-agent orchestration
- production deployment

Those belong to later phases.

Do not automatically start Phase 3.

STOP after Phase 2.

==================================================
FINAL REPORT FROM CODEX
==================================================

After implementation, provide:

A. What existed before Phase 2
B. Files created
C. Files modified
D. Neon database changes
E. New API endpoints
F. New React features
G. New Flutter features
H. SolarSizingAgent architecture
I. Deterministic validation rules
J. Tests executed and actual results
K. Known issues
L. Phase 2 checklist
M. Exact recommended Phase 3 work

Do not claim anything works unless it was actually tested.