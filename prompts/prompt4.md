Continue the SE3090 Smart Solar Installation & Grid Compliance Platform.

COMPLETED:
- Phase 1 Foundation
- Phase 2 Customer + Solar Survey + Solar Sizing Agent
- Phase 3 Field Technician + Site Inspection + Grid Compliance Agent

DO NOT rebuild previous phases.

FIRST:
1. Inspect current repository and existing architecture.
2. Verify Phase 2 and Phase 3 still work.
3. Inspect current Neon/EF Core migrations.
4. Inspect existing LangGraph workflow/state.
5. Reuse existing patterns.
6. Do not make destructive database changes.

==================================================
PHASE 4
ENGINEERING PROPOSAL + AI GUARDRAIL + HUMAN APPROVAL
==================================================

Implement the THIRD major business vertical slice:

Engineering Proposal & AI Governance.

This phase must integrate:

Neon PostgreSQL
→ EF Core
→ ASP.NET Core
→ React
→ Flutter status
→ Agentic AI
→ deterministic validation
→ human approval

The main goal is to implement the complete high-impact approval workflow.

==================================================
TARGET WORKFLOW
==================================================

Existing SolarSurvey
    +
SiteInspection
    +
ComplianceAssessment
        ↓
ASP.NET Core
        ↓
Create Engineering Proposal
        ↓
Agentic AI Guardrail Agent
        ↓
Validate technical/safety constraints
        ↓
Deterministic validation
        ↓
PENDING_APPROVAL
        ↓
Senior Engineer React Dashboard
        ↓
APPROVE / REJECT / REQUEST_REVISION
        ↓
ASP.NET Core
        ↓
Neon transaction
        ↓
Final Proposal Status
        ↓
Flutter homeowner status update

==================================================
1. DATABASE
==================================================

Extend existing Neon PostgreSQL model.

Create:

EngineeringProposal
ApprovalAuditLog

Reuse existing AgentWorkflow.

Recommended EngineeringProposal:

Id
SolarSurveyId
WorkflowId
RecommendedKw
PanelCount
InverterSizeKw
EstimatedCostLkr
GridComplianceStatus
RiskLevel
SafetyStatus
ProposalStatus
RecommendationSummary
EngineerNotes
CreatedAt
UpdatedAt

ProposalStatus should use controlled values:

DRAFT
PROCESSING
PENDING_APPROVAL
APPROVED
REJECTED
REVISION_REQUESTED
FAILED

ApprovalAuditLog:

Id
EngineeringProposalId
WorkflowId
UserId
Decision
Comment
Timestamp

Decisions:

APPROVED
REJECTED
REVISION_REQUESTED

Use proper FK relationships, indexes and audit fields.

Create a new EF Core migration.

Do not delete existing Phase 2/3 records.

==================================================
2. PROPOSAL CREATION
==================================================

Create an engineering proposal using existing:

- SolarSurvey
- SolarSizing result
- SiteInspection
- SiteTelemetry
- ComplianceAssessment

Do not duplicate the original survey data unnecessarily.

The proposal should summarize the validated technical information.

==================================================
3. GUARDRAIL AGENT
==================================================

Implement the THIRD/FUNCTIONAL Agentic AI responsibility:

SafetyGuardrailAgent

Its responsibility:

- inspect the proposed solar system
- identify safety/compliance concerns
- determine whether high-impact approval is required
- produce structured safety findings
- never directly approve the proposal

Input:

- proposal data
- survey data
- inspection data
- compliance assessment

Structured output example:

{
  "safetyStatus": "REQUIRES_APPROVAL",
  "riskLevel": "HIGH",
  "requiresApproval": true,
  "issues": [],
  "recommendations": []
}

Use Pydantic validation.

Do not trust free-form text.

==================================================
4. HIGH-IMPACT APPROVAL RULE
==================================================

Implement the project-defined rule:

IF recommendedKw > 10.0
OR gridComplianceStatus is non-compliant

THEN:

requiresApproval = true

and:

ProposalStatus = PENDING_APPROVAL

The AI must not bypass this rule.

Use deterministic backend validation as the authoritative decision.

==================================================
5. DETERMINISTIC VALIDATION
==================================================

Implement a validator outside the LLM.

Validate:

- recommended kW
- panel count
- inverter size
- compliance status
- cost consistency
- required proposal fields
- safety status
- approval requirement

Examples:

IF:
recommendedKw = 12

THEN:
requiresApproval = true

IF:
gridComplianceStatus = NON_COMPLIANT

THEN:
requiresApproval = true

If AI says approval is not needed but deterministic rules say it is:

REJECT AI RESULT

Set:

PENDING_APPROVAL

Do not allow the AI to approve a high-impact action.

==================================================
6. APPROVAL STATE MACHINE
==================================================

Implement:

DRAFT
 ↓
PROCESSING
 ↓
PENDING_APPROVAL
 ↓
APPROVED

Alternative branches:

PENDING_APPROVAL
 ↓
REJECTED

PENDING_APPROVAL
 ↓
REVISION_REQUESTED
 ↓
PROCESSING
 ↓
PENDING_APPROVAL

Invalid transitions must be rejected.

Only authorized SENIOR_ENGINEER users may approve/reject/request revision.

==================================================
7. APPROVAL API
==================================================

Implement at minimum:

GET  /api/proposals
GET  /api/proposals/{id}
GET  /api/proposals/pending
POST /api/proposals/{id}/approve
POST /api/proposals/{id}/reject
POST /api/proposals/{id}/revise

Optional additional endpoints are allowed if useful.

Requirements:

- JWT
- role authorization
- DTOs
- validation
- correct status codes
- async operations
- ownership/access checks
- safe errors

Approve/reject/revise endpoints must NOT allow unauthorized users.

==================================================
8. APPROVAL TRANSACTION
==================================================

Approval must be transactional.

When APPROVE occurs:

1. Verify authenticated user has SENIOR_ENGINEER permission.
2. Verify proposal status is PENDING_APPROVAL.
3. Re-run deterministic validation.
4. Verify approval requirement is still satisfied.
5. Update proposal status to APPROVED.
6. Write ApprovalAuditLog.
7. Update workflow state.
8. Commit transaction.

If any step fails:

ROLL BACK.

Do not partially approve the proposal.

==================================================
9. REJECT
==================================================

Reject must require a reason/comment.

Example:

POST /api/proposals/{id}/reject

{
  "comment": "Grid configuration requires correction."
}

Store the decision in ApprovalAuditLog.

Set:

ProposalStatus = REJECTED

==================================================
10. REQUEST REVISION
==================================================

Revision request must require a comment.

Example:

{
  "comment": "Update inverter size and provide additional site evidence."
}

Set:

REVISION_REQUESTED

Store audit record.

Do not silently modify the proposal.

==================================================
11. HUMAN APPROVAL UI — REACT
==================================================

Build the engineering approval dashboard.

Pages:

Proposal List
Pending Approvals
Proposal Details
Approval History

Proposal details must show:

- customer/site summary
- recommended kW
- panels
- inverter
- estimated cost
- grid compliance
- safety status
- risk level
- detected issues
- AI execution summary
- deterministic validation result
- audit history

Provide buttons:

APPROVE
REJECT
REQUEST REVISION

Reject and revision require a comment.

Do not show APPROVE as available when proposal is not PENDING_APPROVAL.

==================================================
12. APPROVAL UX
==================================================

Before approval display an explicit confirmation:

"This action will approve the engineering proposal."

Require the engineer to confirm.

Display validation status before allowing approval.

If deterministic validation fails:

disable approval.

Display:

"Approval blocked because validation failed."

==================================================
13. FLUTTER STATUS
==================================================

Extend homeowner Flutter screens.

Homeowner should see:

Proposal status
AI recommendation
Estimated system size
Estimated cost
Approval status

Example:

PENDING_APPROVAL
APPROVED
REJECTED
REVISION_REQUESTED

The homeowner must not have approval controls.

Flutter communicates only with ASP.NET Core.

==================================================
14. AUDIT LOGGING
==================================================

Every decision must be auditable.

Record:

WorkflowId
ProposalId
UserId
Decision
Comment
Timestamp

Also record relevant workflow events:

PROPOSAL_CREATED
VALIDATION_COMPLETED
APPROVAL_PENDING
APPROVED
REJECTED
REVISION_REQUESTED
APPROVAL_BLOCKED

Do not store hidden chain-of-thought.

==================================================
15. AGENT WORKFLOW
==================================================

Extend LangGraph.

Target:

Load proposal context
        ↓
SafetyGuardrailAgent
        ↓
DeterministicValidator
        ↓
Set Approval Requirement
        ↓
Persist Workflow
        ↓
PENDING_APPROVAL

The AI must NOT directly approve.

Human approval occurs through ASP.NET Core.

==================================================
16. CROSS-PLATFORM WORKFLOW
==================================================

Demonstrate:

Flutter/Homeowner
→ ASP.NET Core
→ Neon
→ Agentic AI
→ deterministic validation
→ PENDING_APPROVAL
→ React/Senior Engineer
→ APPROVE/REJECT/REVISION
→ ASP.NET Core
→ Neon
→ Flutter updated status

This must use real shared data, not mock frontend state.

==================================================
17. SECURITY
==================================================

Enforce:

- JWT
- SENIOR_ENGINEER role
- proposal status validation
- server-side approval authorization
- deterministic validation before approval
- no direct client → Neon
- no direct client → AI
- safe errors
- no secrets in code/logs

Never trust a role, user ID or approval status supplied by the client.

==================================================
18. APPROVAL BYPASS TEST
==================================================

Create a test proving that an engineer cannot approve:

- REJECTED proposal
- DRAFT proposal
- PROCESSING proposal
- already APPROVED proposal

Only:

PENDING_APPROVAL

can be approved.

==================================================
19. IMPORTANT AI SAFETY TEST
==================================================

Test:

recommendedKw = 12
AI says:
requiresApproval = false

Expected:

deterministic validator rejects AI result.

Final state:

PENDING_APPROVAL

The AI cannot bypass the approval rule.

==================================================
20. TEST CASES
==================================================

Backend:

- proposal creation
- proposal retrieval
- pending proposals
- engineer authorization
- approve
- reject
- revision
- invalid transition
- approval transaction rollback
- unauthorized approval

Agentic AI:

- high-risk proposal
- low-risk proposal
- AI incorrectly says no approval
- malformed output
- timeout
- unavailable AI

Database:

- FK integrity
- approval audit log
- transaction behavior
- migration

React:

- pending approvals
- proposal details
- approve dialog
- reject dialog
- revision dialog
- audit history
- disabled approval after validation failure

Flutter:

- proposal status
- updated status
- homeowner cannot approve

==================================================
21. GOLDEN CASES
==================================================

GOLDEN CASE 1:

recommendedKw = 5
grid = Single-Phase
compliance = COMPLIANT

Expected:
proposal may proceed without mandatory high-impact approval unless another rule requires it.

GOLDEN CASE 2:

recommendedKw = 12
grid = Three-Phase
compliance = COMPLIANT

Expected:
PENDING_APPROVAL

GOLDEN CASE 3:

recommendedKw = 8
grid = Single-Phase
compliance = NON_COMPLIANT

Expected:
PENDING_APPROVAL

GOLDEN CASE 4:

AI says:
requiresApproval = false

Input:
12 kW

Expected:
validator rejects AI result.

GOLDEN CASE 5:

Engineer approves proposal while status != PENDING_APPROVAL

Expected:
403/409/appropriate controlled failure.

GOLDEN CASE 6:

Approval database transaction fails midway.

Expected:
no partial approval and audit transaction rolled back.

==================================================
22. DOCUMENTATION
==================================================

Update/create:

docs/database/engineering-proposal-design.md
docs/api/proposal-api.md
docs/architecture/approval-workflow.md
docs/agentic-ai/safety-guardrail-agent.md
docs/testing/phase-4-test-plan.md

Document:

- proposal lifecycle
- approval rules
- deterministic validator
- Guardrail Agent
- audit logging
- authorization
- transaction behavior
- cross-platform workflow

==================================================
23. GIT
==================================================

Use:

feature/engineering-approval

Meaningful commits only.

Examples:

feat: add engineering proposal domain
feat: add proposal API
feat: add safety guardrail agent
feat: add deterministic approval validation
feat: add approval workflow
feat: add approval dashboard
feat: add homeowner proposal status
test: add approval workflow tests
docs: document engineering approval

==================================================
24. DO NOT IMPLEMENT YET
==================================================

Do not build:

- full inventory management
- equipment reservation
- utility filing
- payment system
- final deployment

Those belong to later phases.

==================================================
25. DEFINITION OF DONE
==================================================

DATABASE
[ ] EngineeringProposal works
[ ] ApprovalAuditLog works
[ ] Relationships correct
[ ] EF migration created/applied
[ ] Existing data preserved

BACKEND
[ ] Proposal APIs work
[ ] Pending endpoint works
[ ] Approve works
[ ] Reject works
[ ] Revision works
[ ] Authorization works
[ ] Status transitions enforced
[ ] Approval transaction works

AGENTIC AI
[ ] SafetyGuardrailAgent works
[ ] Structured output
[ ] Deterministic validation
[ ] Approval requirement enforced
[ ] AI cannot bypass rules
[ ] Workflow state persisted
[ ] Execution logs persisted
[ ] Failure handling works

REACT
[ ] Proposal list
[ ] Pending approvals
[ ] Proposal details
[ ] Approve
[ ] Reject
[ ] Revision
[ ] Audit history
[ ] Validation display

FLUTTER
[ ] Proposal status visible
[ ] Updated status visible
[ ] No unauthorized approval controls

SECURITY
[ ] Only authorized engineer can approve
[ ] Invalid transitions blocked
[ ] Deterministic validation enforced
[ ] No direct DB access
[ ] No direct AI access

TESTING
[ ] Backend tests pass
[ ] Agent tests pass
[ ] Database tests pass
[ ] React tests pass
[ ] Flutter tests pass
[ ] Golden cases pass
[ ] Existing Phase 1–3 tests still pass

STOP after Phase 4.