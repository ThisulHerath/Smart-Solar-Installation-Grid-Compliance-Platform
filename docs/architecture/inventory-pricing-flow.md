# Connected Workflow and Human Control
 
**Smart Solar Installation & Grid Compliance Platform** · SE3090 – Software Engineering Frameworks · Group 2026-AI-17
 
This document walks through the platform's single end-to-end workflow — from a homeowner's first survey to reserved equipment — and explains, at each step, what the system automates and where a human decision is deliberately required before the process can continue.
 
---
 
## The Workflow, Step by Step
 
### 1. Survey submission
 
The homeowner registers in the Flutter app and submits a solar survey, optionally attaching a site photo. This creates a `SolarSurvey` record in `Draft` status that the homeowner can still edit — nothing downstream happens until it is explicitly submitted.
 
### 2. Persistence and preliminary sizing
 
ASP.NET Core persists the survey and workflow state, then calls the internal sizing graph (the Solar Sizing Agent, run through LangGraph). The planner's output and its execution logs are persisted alongside the survey, not just returned and discarded — so the reasoning behind a sizing result can be inspected later, not only the final number.
 
Because the AI service and the API run as independent processes (and PostgreSQL requires UTC), **every incoming timestamp is normalized to UTC** before being written. This matters specifically because the sizing graph's execution logs carry their own start/complete timestamps; without normalization, a log written from a differently-configured process could silently corrupt duration calculations or violate the database's UTC expectations.
 
### 3. Field inspection
 
An engineer assigns a field job to a technician. The technician then records a **real device check-in** (geolocation), photos, observed installation values (roof tilt, orientation, breaker rating, phase count), and electrical readings (Voc, Isc, Vmp, Imp, irradiance, grid voltage/frequency) through the Flutter app's camera and GPS integrations. This is the point where the system moves from homeowner-reported estimates to technician-verified, on-site measurements.
 
### 4. Compliance screening
 
The Grid Compliance specialist and its validator screen the measured readings against documented grid-connection rules. If an inspection is later corrected and compliance is re-evaluated, **the latest readings are used** for the new decision — but earlier readings are not deleted or overwritten; they remain as **audit evidence** of what was measured and assessed at each point in time.
 
### 5. Proposal request
 
Once a survey has completed analysis, the homeowner can request an engineering proposal. At this point the Safety Guardrail agent's findings and the deterministic validation result are saved onto the proposal — the proposal is not approved yet, but the evidence it will be judged on is already locked in.
 
### 6. Human approval — the pause point
 
**This is the step where the workflow stops and waits.** The proposal enters `PendingApproval` status, and **only a Senior Engineer or Administrator can move it forward** — by approving, rejecting, or requesting a revision (`ProposalsController.Approve/Reject/Revise`, each restricted with `[Authorize(Roles = ...)]`).
 
Two conditions actively block approval rather than merely warning about them:
- **Missing compliance evidence** — a proposal cannot be approved without a completed compliance assessment behind it.
- **A blocked safety finding** — if the Safety Guardrail agent's result requires human review, the proposal cannot proceed to approval until that's resolved.
The decision itself is not a simple field update. Approval, rejection, and revision requests each run inside a **`Serializable` database transaction** (`IsolationLevel.Serializable` in `ProposalService.cs`), so the status change and its audit log entry **commit together or not at all**. There's no window in which a proposal could end up `Approved` without a matching audit record, even under concurrent requests.
 
### 7. Pricing and reservation
 
An inventory officer prices an approved proposal through a **controlled exchange-rate tool** — "controlled" meaning the pricing agent calls a specific, allow-listed exchange-rate API, and the resulting quote is independently re-validated server-side (recomputing every line total against the live catalog) before being trusted. A validated quote can then be **reserved atomically**, incrementing reserved stock in a way that is safe under concurrent reservation attempts and idempotent on replay.
 
### 8. Status visibility
 
The homeowner can read the equipment status and estimated cost at any point. It's worth being explicit about what "reserved" means here: **reserved equipment means the system has set stock aside and is ready for installation planning — it does not mean the installation has happened, and it does not mean the utility (CEB/LECO) has approved a grid connection.** Both of those remain outside this platform's scope, by design (see [`docs/sri-lanka-scope.md`](../sri-lanka-scope.md)).
 
---
 
## Reconstructing the Workflow: `GET /api/workflows/surveys/{id}`
 
A single endpoint, `WorkflowOverviewController.Get`, reconstructs the **entire** shared workflow state for a survey purely from durable database records — no in-memory workflow state is required:
 
- The sizing objective, plan, and specialist results
- The latest compliance assessment
- The safety guardrail result and its validation
- The human approval decision and full audit history (`approvalHistory`)
- Any errors recorded along the way
- The equipment quote/reservation outcome
Because every piece of this comes from the database rather than from a running process, **restarting either the ASP.NET Core API or the AI service does not lose the human approval pause** — a proposal sitting in `PendingApproval` stays exactly there, waiting for an engineer, regardless of how many times the services behind it have been redeployed or restarted.
 
This also means the platform is **a set of coordinated, request-driven workflows — not a continuously running autonomous process.** Each stage runs only when a specific client request triggers it (submit a survey, submit an inspection, request a proposal, approve a proposal, price a proposal). The sizing graph itself only handles sizing; it does not reach forward and execute compliance, approval, or pricing on its own. Progress through the full lifecycle always depends on the next explicit action — frequently a human one.
 
---
 
## Revisions and Immutability
 
Two rules govern how corrections flow back through an already-started workflow:
 
- **Proposal decisions are never erased.** When an engineer requests a revision, that decision is written to the proposal's audit log (`ApprovalAuditLog`) and lifecycle events (`REVISION_REQUESTED`) rather than replacing or deleting the prior state. After the technician corrects and resubmits the inspection, and compliance is re-evaluated, the homeowner can request an **updated proposal under the same survey** — the old decision remains visible in that proposal's history as a permanent record of what happened and why.
- **Submitted surveys are immutable.** `SurveyService` enforces that a survey can only be edited or resubmitted while it is still in `Draft` status (`"Only draft surveys can be edited"` / `"Only draft surveys can be submitted"`). If the homeowner's actual consumption or roof requirements change after submission, that is treated as a **new survey**, not an edit to the old one — preserving the original as an accurate record of what was assessed at the time, rather than allowing it to silently drift from the data a past decision was based on.
---
 
## Summary: What's Automated vs. What Requires a Human
 
| Stage | Automated | Requires a human decision |
|---|---|---|
| Survey submission | — | Homeowner submits |
| Preliminary sizing | Solar Sizing Agent | — |
| Field job assignment | — | Engineer assigns, technician inspects |
| Compliance screening | Grid Compliance Agent + validator | — |
| Proposal request | Safety Guardrail + deterministic validation | Homeowner requests |
| **Approval** | — | **Engineer/Administrator approves, rejects, or requests revision** |
| Pricing | Equipment Pricing Agent + exchange-rate tool | Inventory officer triggers pricing |
| Reservation | Reservation logic (atomic, idempotent) | Inventory officer reserves |
 
The single irreducible human checkpoint in this chain is step 6 — proposal approval. Every other stage either executes deterministic/agentic logic automatically or is a human-initiated action that simply advances the workflow to its next stage; approval is the one point where a human must exercise judgment the system cannot make on its own.
