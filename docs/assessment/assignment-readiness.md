# SE3090 assignment readiness

**15 September 2026.** Reviewed against the supplied 17-page assignment specification. Page references below refer to that document. This is a development audit, not a signed submission or an awarded grade.

**The assignment requires at least four distinct agents and at least one complete assessed agentic workflow (page 6). It does not prescribe four named workflows.** A standard group also needs four primary business components.

Legend: `[x]` = verified at the stated scope; `PARTIAL` = implementation exists but a required part or proof is missing; `TODO` = outstanding; `UNVERIFIED` = not established. Passing tests do not prove every feature works.

## Requirements checklist

### Platform and business logic — pages 2–5

- [x] ASP.NET Core API, PostgreSQL/EF Core/Npgsql, React and Flutter are implemented and integrated.
- [x] Both clients use ASP.NET as their gateway; Python is internal.
- [x] Five roles: homeowner, field technician, senior engineer, inventory officer and administrator.
- [x] Four business components: customer assessment; field operations/compliance; engineering proposals/approval; inventory/pricing.
- [x] Each component has at least four meaningful API routes and non-CRUD business operations. Evidence: SurveysController, FieldJobsController/TechnicianController, ProposalsController and InventoryController.
- [x] Services, DTOs, DI, async operations, validation, exception handling, JWT/password hashing, CORS, health and Swagger exist.
- [x] CRUD and controlled lifecycle operations exist. Audited records use workflow transitions where destructive deletion would be inappropriate.
- [ ] PARTIAL — Search/filter/sort/pagination/reporting exist, but complete usability across every role and list is not exhaustively verified here.
- [x] Entities, relationships, migrations, indexes/constraints, seeds, audit timestamps and database design/ERDs exist.
- [x] A real PostgreSQL test passed: migrations, constraints, concurrent reservation, replay/idempotency, rollback/release and email replay concurrency in an isolated schema.
- [ ] PARTIAL — Add equivalent integrity/transaction evidence for the other components; current database test coverage is strongest around inventory and authentication.

### React and Flutter — pages 5–7

- [x] React routing, role navigation, forms, staff approval and equipment operations are implemented; 32 tests passed.
- [x] Flutter homeowner/technician screens, authenticated API access, token storage and reusable widgets are implemented; 16 tests passed.
- [x] Distinct purposes: React emphasizes staff work; Flutter emphasizes homeowner updates and field work.
- [x] Mobile location and camera/gallery integrations are implemented.
- [ ] UNVERIFIED — Physical-device permissions, camera and GPS were not tested in this audit. Edge cannot prove native-device behaviour.
- [ ] PARTIAL — A debug Android APK exists. Rebuild using the final API URL and verify the exact submitted APK on a clean device.
- [ ] PARTIAL — The common API workflow passed end to end, but this run used an HTTP script. Record a continuous Flutter → React approval → Flutter status scenario with the same survey ID.
- [ ] UNVERIFIED — Exhaustive mobile navigation/error-state, keyboard, screen-reader and contrast testing across all screens.

### Agentic acceptance — page 6

- [x] Four different domain specialists: SolarSizingAgent, GridComplianceAgent, SafetyGuardrailAgent and EquipmentPricingAgent; PlannerAgent is an additional coordinator.
- [x] Domain agents have identifiable responsibilities and input/output validation boundaries in `agentic-ai/app/agents`, `schemas` and `validators`.
- [ ] PARTIAL — Consolidate evidence of each agent's contracts, permitted tools and participation. The coordinator's contract/planning is less developed than the specialist contracts.
- [x] A domain objective can enter the workflow; the diagnostic route and sizing request now preserve it.
- [ ] PARTIAL — PlannerAgent emits a fixed eight-step list. It does not analyse the objective to create structured step objects with dependencies, tool permissions and conditional delegation. Do not present it as an autonomous planner.
- [x] Specialist stages execute in the business process. Sizing, safety and pricing use LangGraph; compliance is a procedural pipeline.
- [x] Pricing calls a real allowlisted USD/LKR tool with currency/rate/freshness validation, timeout, caching and structured output. No agent can directly mutate stock.
- [x] Deterministic sizing, compliance, safety, price and availability checks run before outputs/actions are accepted.
- [x] Proposals pause for authorized engineer approval; approval/rejection/revision and audit records exist. Homeowner approval was rejected live.
- [x] Results and approvals persist in PostgreSQL and appear in an authorized overview.
- [ ] PARTIAL — State is distributed across workflow, compliance, proposal and quote records. Some completed steps/outcomes are derived. Strengthen correlation and durable recovery; a canonical execution/step model would make acceptance easier to demonstrate.
- [ ] PARTIAL — Logs exist but timing/retry/tool traces are inconsistent across stages. Some timestamps are generated after execution, so they are not measured agent latency.
- [x] Tested failures include invalid inputs, unsafe results, stale pricing, downstream errors and unauthorized actions. Internal endpoint authentication is enforced.
- [ ] PARTIAL — Inert catalog-instruction text is tested; extend the golden evaluation to objective abuse, tool timeouts/rate limits, retry bounds and interrupted-run recovery.
- [ ] PARTIAL — Overall minimum agentic acceptance: substantial working implementation, with planning, recovery and trace-completeness gaps. Do not claim full marks from class count alone.

### Testing, CI, security and submission — pages 8–17

- [x] Fresh results: **95 backend, 40 Python, 32 React and 16 Flutter tests passed**. Zero backend tests skipped; PostgreSQL was exercised.
- [x] Fresh live local workflow passed: sizing → inspection → compliance → safety → engineer approval → pricing → reservation/release.
- [x] Live negative checks: homeowner approval forbidden, repeated reservation idempotent, reservation after release rejected.
- [x] A limited performance sample records 20 report requests at concurrency 5 with statuses and timings in the evidence JSON.
- [ ] PARTIAL — Add separate database and agent/tool latency, concurrent-write and failure-rate evidence. This small report sample is not a capacity benchmark.
- [x] Backend CI configuration now covers every push and every PR to main without path filters. Other component workflows exist.
- [ ] UNVERIFIED — GitHub has not run these local changes; no commit or push was made. Keep real green CI evidence after you choose to push.
- [ ] TODO — Four-person ownership, regular contributions, issues, PR reviews and board evidence. The user says the work so far is theirs alone.
- [x] README, API/architecture/database documents and six ADRs exist. Agent documentation was corrected to match the implementation.
- [ ] PARTIAL — Final documentation needs current setup verification, agent-state schema justification, URLs and individual evidence. Older documents may need further alignment.
- [x] Managed PostgreSQL is reachable and tested; credentials were not copied into this report.
- [ ] UNVERIFIED — Cloud database least privilege, backups and evaluator-access settings were not audited.
- [ ] TODO — Public ASP.NET health/Swagger and React URLs. Localhost does not meet deployment evidence requirements.
- [ ] PARTIAL — Local AI operation is allowed on page 9; final startup and evaluator instructions need clean-machine verification.
- [ ] PARTIAL — Protect bills/site photos with authorized access and durable storage before public deployment; static local uploads are intended for demo data.
- [ ] TODO — One consolidated PDF with group report, four individual reports, evidence and references.
- [ ] TODO — Actual student AI-use logs, student-written reflections and signed declarations. `docs/AI-USAGE.md` is a draft, not four individuals' evidence.
- [ ] TODO — Accessible ten-minute demo video; the user confirmed none exists yet.
- [ ] TODO — Final naming, links and evaluator access through 21 October 2026. The PDF states a deadline of 30 September 2026, 23:50.
- [ ] TODO — Each member must explain, test, modify and debug their contribution in the viva; naming existing code does not establish ownership.

## Proposed Member 1–4 allocation

These are **future responsibilities**, not claims about authorship. Every member needs genuine work in API, database, React, Flutter, testing, Git and documentation, plus their distinct agent. Do not divide the team into backend-only, web-only, mobile-only and testing-only roles.

### Member 1 — Customer assessment and sizing

Own survey/profile APIs; CustomerProfile/SolarSurvey/workflow records; web survey screens; Flutter survey/photo/status screens; SolarSizingAgent and coordination-plan improvements. Implement structured plan steps with objective validation, dependencies and allowed tools. Add regression tests across these layers and real PR evidence. Explain usage input → preliminary calculation → validation → durable result.

### Member 2 — Field operations and compliance

Own assignment/check-in/inspection/telemetry APIs; FieldJob/SiteInspection/SiteTelemetry/ComplianceAssessment records; React dispatch/review screens; Flutter technician screens; GridComplianceAgent. Improve missing/out-of-range input handling, execution traces and permission-denial UX. Supply real GPS/photo device evidence and database/API/agent/UI tests. Explain why screening is not utility certification.

### Member 3 — Engineering proposals and approval

Own proposal/create/approve/reject/revise APIs; proposal/approval/lifecycle records; React engineer workspace; Flutter proposal history; SafetyGuardrailAgent. Strengthen interrupted-run/revision recovery and audit presentation. Test unauthorized, concurrent and stale decisions. Explain why server checks and the authorized engineer determine approval, not the agent.

### Member 4 — Equipment pricing and inventory

Own catalog/supplier/quote/reserve/release APIs; inventory/quote/reservation records; React inventory/pricing screens; Flutter equipment status; EquipmentPricingAgent. Improve measured tool traces, timeout/rate-limit tests and quote recovery. Explain exchange validation, stock rechecks, transaction rollback and idempotency. Provide real cross-layer changes and tests.

All four should review another member's PR, document their own work, run the integrated scenario and prepare a small viva change/debugging example. Preserve actual Git history; do not backdate or fabricate contributions.

## How the process connects

1. A homeowner submits usage, roof details and photos in Flutter or React. ASP.NET checks identity/ownership and stores the survey in PostgreSQL.
2. ASP.NET calls internal Python using its server-held key. PlannerAgent lists the steps; SolarSizingAgent calculates a preliminary system; an independent validator checks it. ASP.NET stores the outcome/logs.
3. An engineer assigns field work. A technician submits measurements, normally from Flutter. GridComplianceAgent screens them and another validator checks the result.
4. Proposal creation invokes SafetyGuardrailAgent and validation. It remains pending until an authorized engineer approves, rejects or requests revision in React. The agent cannot approve.
5. After approval, inventory staff request pricing. The Python graph combines catalog selection and a real USD/LKR rate, then checks prices and availability.
6. Staff explicitly reserve stock. ASP.NET rechecks approval, permissions and quantities in a PostgreSQL transaction. The homeowner reads updated status using the same API.

This is a request-driven, multi-stage process with human pauses. The four specialist workflows are **sizing, compliance, safety review and equipment pricing**. `/api/agent-workflows/test` exercises sizing only, not all four.

## Highest-value work for the rubric

The rubric gives **30 group marks and 70 individual marks**. Group: business logic 10, integration/agent orchestration/state 10, documentation/deployment 10. Individual: API 10, database 10, React 10, Flutter 10, agent contribution 12, integration/security 10, testing/CI/Git 8. A predicted grade would be misleading without deployment, ownership and viva evidence.

1. **Agree genuine ownership now.** Create forward-looking issues and have each member implement meaningful cross-layer improvements. This affects the 70 individual marks.
2. **Strengthen agent acceptance.** Add objective-sensitive structured plans, consistent correlated traces and recovery. Keep authorization, calculations and stock changes deterministic. Justify the runtime in the ADR; no LLM currently runs.
3. **Deploy and verify access.** Provide public API/Swagger/health and React links plus a tested APK. Secure uploads before using real documents.
4. **Record a continuous golden scenario.** Flutter start → persisted state and all four specialists → React approval → Flutter status for the same survey. Include an unauthorized attempt and one safe failure. Add agent/tool/database performance evidence.
5. **Finish evidence and rehearsal.** Consolidated report, genuine individual sections, ADRs, dated AI logs, personal reflections/signatures, video and green CI links. Every member must explain and modify their own contribution.

## Fixes and evidence from this audit

- Reproduced Python `/workflow/test` HTTP 500: dictionary logs violated its legacy string-log contract. Fixed serialization and added an endpoint regression test.
- Fixed ASP.NET forwarding: camelCase customer/input fields now map explicitly to Python snake_case; backend contract tests cover it.
- Preserved objective through sizing and forwarded the persisted survey objective. Tested non-default consumption.
- Empty downstream diagnostic responses now return safe failure instead of misleading completion; tested both outcomes.
- Added the omitted SolarSizingAgent to the health agent list.
- Corrected backend CI triggers and extended the live runner to verify the repaired cross-service diagnostic contract.

Fresh evidence: [live workflow JSON](../testing/assignment-audit-live-2026-09-15.json). It records statuses/durations, workflow output, approval history, pricing and a small concurrency sample without tokens or connection strings.

The script leaves labelled synthetic demo records for inspection and releases its reservation. This audit did not send OTP email, test a physical device, deploy, record video, commit or push.
