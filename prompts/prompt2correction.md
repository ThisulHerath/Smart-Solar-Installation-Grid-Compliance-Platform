PHASE 2 FIX / COMPLETION

The previous Phase 2 verification found several incomplete or unsafe areas.

DO NOT start Phase 3.

Inspect the current repository and fix ONLY the issues identified below.

Before modifying files, inspect the existing implementation and preserve working code.

==================================================
1. SECURITY FIXES
==================================================

A. PUBLIC REGISTRATION ROLE ESCALATION

Fix AuthService/public registration so the client cannot select privileged roles.

Public registration must always create:

HOMEOWNER

Do not trust a role value supplied by the client.

Only an authorized ADMINISTRATOR workflow may assign:
- FIELD_TECHNICIAN
- SENIOR_ENGINEER
- INVENTORY_OFFICER
- ADMINISTRATOR

Add/update tests proving that a normal registration cannot create privileged roles.

B. AGENT WORKFLOW TEST ENDPOINT

Protect:

POST /api/agent-workflows/test

with appropriate authorization.

Do not expose an unauthenticated AI execution endpoint.

C. SECRETS

Remove committed/default usable secrets from:
- appsettings.json
- Program.cs
- main.py
- other source files

Use environment variables/configuration for:
DATABASE_CONNECTION_STRING
JWT_KEY
JWT_ISSUER
JWT_AUDIENCE
AGENTIC_AI_BASE_URL
AGENTIC_AI_INTERNAL_KEY

Update .env.example with placeholders only.

Ensure .gitignore excludes .env and other secret files.

Do not print secrets in logs.

==================================================
2. FLUTTER SURVEY SUBMISSION
==================================================

Fix the Flutter homeowner flow.

The existing UI must actually call:

submitSurvey()

after creating/editing a draft.

The intended flow is:

Login
→ New Survey
→ Save/submit
→ POST/submit endpoint
→ backend validation
→ workflow creation
→ AI processing
→ persisted result
→ updated survey status

Do not leave submitted surveys stuck in DRAFT.

Add clear UI feedback:
- submitting
- success
- failure

==================================================
3. SOLAR SIZING WORKFLOW
==================================================

The survey processing path currently bypasses LangGraph and directly calls run_solar_sizing().

Refactor it so the real Phase 2 survey analysis uses the LangGraph workflow.

Required flow:

START
→ Planner
→ SolarSizingAgent
→ DeterministicValidator
→ COMPLETE / FAILED

Do not remove the deterministic validator.

The deterministic validator must independently verify:
- monthly kWh
- recommended kW
- panel count
- inverter size
- schema correctness

Do not allow AI output to silently override deterministic calculations.

==================================================
4. WORKFLOW STATE PERSISTENCE
==================================================

Persist the important structured workflow state.

At minimum retain:

workflow_id
survey_id
objective
plan
current_step
completed_steps
validation_results
final_outcome
errors
status
timestamps

Do NOT store hidden chain-of-thought.

==================================================
5. AGENT EXECUTION LOGGING
==================================================

Add persistent agent execution records.

Create an appropriate entity/table such as:

AgentExecutionLog

Fields:

Id
WorkflowId
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

Record execution for:
- Planner
- SolarSizingAgent
- Validator

Use EF Core migration.

Do not store secrets or unnecessary personal data in logs.

==================================================
6. FAILURE HANDLING
==================================================

Fix Python AI service failure behaviour.

Do not expose raw exception details to API clients.

Handle:
- AI unavailable
- timeout
- malformed output
- validation failure

Return safe structured failures.

The workflow must not become successful when AI processing fails.

==================================================
7. REACT
==================================================

Improve the existing React survey dashboard.

Add:
- workflow status
- AI recommendation
- validation result
- execution summary
- error state

Add manual refresh or lightweight polling so the dashboard can detect a workflow moving from PROCESSING to ANALYSIS_COMPLETE.

Require appropriate staff authorization for staff-only survey views.

Use the existing state-management solution.

Do not introduce another state-management library.

==================================================
8. FLUTTER AI RESULT
==================================================

After a survey is processed, Flutter must be able to display:

- survey status
- recommended kW
- panel count
- inverter size
- validation status
- safe error message if processing fails

Use the existing ASP.NET Core API.

Do not access the AI service directly.

==================================================
9. IMAGE UPLOAD
==================================================

Improve the current image workflow.

Before saving/uploading:
- validate ownership
- validate survey status
- validate file type
- validate MIME type
- validate file size

Avoid leaving orphan files when database validation fails.

Do not expose unsafe filesystem paths.

Keep storage behind an abstraction.

==================================================
10. TESTING
==================================================

Add actual automated tests for the missing areas.

Backend:
- privileged role registration blocked
- protected AI endpoint
- survey ownership
- survey update
- submit survey
- status transitions
- invalid survey
- AI failure

AI:
- LangGraph workflow
- valid sizing
- malformed output
- deterministic validation
- conflicting output
- failure handling

Database:
- migration
- relationships
- foreign keys

React:
- survey rendering
- AI result rendering
- workflow status

Flutter:
- survey submission
- validation
- AI result state

Run the actual tests and report real results.

==================================================
11. END-TO-END VERIFICATION
==================================================

Verify this actual flow:

Flutter
→ ASP.NET Core
→ Neon PostgreSQL
→ LangGraph
→ Planner
→ SolarSizingAgent
→ DeterministicValidator
→ Neon workflow persistence
→ React staff dashboard
→ Flutter result/status

Do not claim this is complete unless it has actually been tested.

==================================================
12. DEFINITION OF DONE
==================================================

Do not mark Phase 2 complete until:

[ ] Public registration cannot assign privileged roles
[ ] AI test endpoint is protected
[ ] No secrets are committed
[ ] Flutter actually submits surveys
[ ] Submitted survey reaches processing
[ ] LangGraph workflow is actually executed
[ ] SolarSizingAgent runs
[ ] Deterministic validator runs
[ ] Workflow state persists
[ ] Agent execution logs persist
[ ] React displays AI result
[ ] Flutter displays AI result
[ ] Workflow failure is handled safely
[ ] Ownership tests pass
[ ] Authorization tests pass
[ ] Survey tests pass
[ ] AI tests pass
[ ] React tests are configured and run
[ ] Flutter tests are configured and run
[ ] End-to-end workflow is verified

Do NOT start Phase 3.

At the end provide:
- files modified
- migrations created
- tests run and actual results
- remaining issues
- final Phase 2 status