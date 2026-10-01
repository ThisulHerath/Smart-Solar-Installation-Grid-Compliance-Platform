# SE3090 Assignment Readiness

**Last updated:** 28 September 2026 (original audit 15 September 2026; lecture follow-up 19 September 2026)

> This is a development audit, not a signed submission or an awarded grade. Passing tests do not prove every feature works.

**Legend:** ✅ verified at the stated scope | 🟡 partial | ⬜ to do | ❓ unverified

---

## 1. Summary

The agentic strengthening requested after the first audit is **implemented**:

- PlannerAgent creates objective-sensitive, typed plans.
- A persisted master workflow supports inspection, correction, engineering decision, pricing and inventory pause/resume events.
- A central registry restricts each specialist's tools.
- ASP.NET verifies database business state before accepting high-impact events.
- Correlated trace/tool fields are persisted (migration `StrengthenAgentWorkflowState`).

**Current automated results:** 105 ASP.NET passed (1 PostgreSQL integration test skipped), 63 Python passed, 47 React passed, 20 Flutter passed.

**Still absent by design (no-paid-service decision):** live LLM reasoning and generative RAG.

> Deadline note: the assignment PDF states **30 September 2026, 23:50**. Confirm submission status or an extension with your lecturer immediately. Evaluator access is required through **21 October 2026**.

The assignment requires at least four distinct agents and at least one complete assessed agentic workflow (page 6). A standard group also needs four primary business components.

---

## 2. Requirements Checklist

### Platform and business logic (pages 2–5)

- ✅ ASP.NET Core API, PostgreSQL/EF Core/Npgsql, React and Flutter implemented and integrated.
- ✅ Both clients use ASP.NET as the gateway; Python is internal only.
- ✅ Five roles: homeowner, field technician, senior engineer, inventory officer, administrator.
- ✅ Four business components: customer assessment; field operations/compliance; engineering proposals/approval; inventory/pricing.
- ✅ Each component has at least four meaningful API routes plus non-CRUD operations (`SurveysController`, `FieldJobsController`/`TechnicianController`, `ProposalsController`, `InventoryController`).
- ✅ Services, DTOs, DI, async, validation, exception handling, JWT/password hashing, CORS, health and Swagger.
- ✅ CRUD and controlled lifecycle operations (workflow transitions instead of destructive deletes for audited records).
- 🟡 Search/filter/sort/pagination/reporting exist, but usability across every role and list is not exhaustively verified.
- ✅ Entities, relationships, migrations, indexes/constraints, seeds, audit timestamps and ERDs.
- ✅ Real PostgreSQL test passed: migrations, constraints, concurrent reservation, replay/idempotency, rollback/release, email replay concurrency (isolated schema).
- 🟡 Add equivalent integrity/transaction evidence for the other components. Database test coverage is strongest for inventory and authentication.

### React and Flutter (pages 5–7)

- ✅ React: routing, role navigation, forms, staff approval, equipment operations.
- ✅ Flutter: homeowner/technician screens, authenticated API access, token storage, reusable widgets.
- ✅ Distinct purposes: React for staff work; Flutter for homeowner updates and field work.
- ✅ Mobile location and camera/gallery integrations implemented.
- ❓ Physical-device permissions, camera and GPS not tested.
- 🟡 A debug Android APK exists. Rebuild with the final API URL and verify the exact submitted APK on a clean device.
- 🟡 Common API workflow passed end to end, but via an HTTP script. Record a continuous Flutter → React approval → Flutter status scenario with the **same survey ID**.
- ❓ Exhaustive mobile navigation/error-state, keyboard, screen-reader and contrast testing.

### Agentic acceptance (page 6)

- ✅ Four domain specialists: **SolarSizingAgent, GridComplianceAgent, SafetyGuardrailAgent, EquipmentPricingAgent**; PlannerAgent is an additional coordinator.
- ✅ Identifiable responsibilities and input/output validation boundaries (`agentic-ai/app/agents`, schemas, validators).
- ✅ Typed contracts, per-agent tool permissions and participation evidence.
- ✅ A domain objective can enter the workflow and is preserved through sizing.
- ✅ PlannerAgent classifies reviewed objectives and creates structured steps (dependencies, required inputs, tool permissions, high-impact markers, state). Selection is deterministic; do **not** present it as live LLM reasoning.
- ✅ Specialist stages run in the business process. Sizing, safety and pricing use LangGraph; compliance is a procedural pipeline.
- ✅ Pricing calls a real allowlisted USD/LKR tool with currency/rate/freshness validation, timeout, caching and structured output. No agent can mutate stock.
- ✅ Deterministic sizing, compliance, safety, price and availability checks run before outputs/actions are accepted.
- ✅ Proposals pause for authorized engineer approval; approval/rejection/revision and audit records exist. Homeowner approval was rejected live.
- ✅ Results and approvals persist in PostgreSQL and appear in an authorized overview.
- ✅ Canonical workflow state, current step, approval status and retry count persist in `AgentWorkflow` and resume through authenticated endpoints.
- ✅ Correlated trace/span/tool fields persist. Zero-duration human transition events represent recorded decisions, not model latency.
- ✅ Tested failures: invalid inputs, unsafe results, stale pricing, downstream errors, unauthorized actions. Internal endpoint authentication enforced.
- 🟡 Extend golden evaluation to objective abuse, tool timeouts/rate limits, retry bounds and interrupted-run recovery.
- 🟡 Strong deterministic evidence exists, but live LLM reasoning and generative RAG are absent. **Confirm the lecturer's interpretation before claiming full agentic marks.**

### Testing, CI, security and submission (pages 8–17)

- ✅ Fresh results (15 Sep run): 95 backend, 40 Python, 32 React, 16 Flutter. PostgreSQL exercised. *(Superseded by the 28 Sep counts above.)*
- ✅ Live local workflow passed: sizing → inspection → compliance → safety → engineer approval → pricing → reservation/release.
- ✅ Live negative checks: homeowner approval forbidden, repeated reservation idempotent, reservation after release rejected.
- ✅ Limited performance sample: 20 report requests at concurrency 5 (not a capacity benchmark).
- 🟡 Add separate database and agent/tool latency, concurrent-write and failure-rate evidence.
- ✅ Backend CI covers every push and PR to `main` without path filters. Other component workflows exist.
- ❓ GitHub has not run these local changes (no commit or push). Keep green CI evidence after you push.
- ⬜ Four-person ownership, regular contributions, issues, PR reviews, board evidence. The work so far is yours alone.
- ✅ README, API/architecture/database docs and ADRs exist (ADR-007 added later). Agent documentation corrected.
- 🟡 Final documentation needs current setup verification, agent-state schema justification, URLs and individual evidence.
- ✅ Managed PostgreSQL reachable and tested (credentials not recorded).
- ❓ Cloud database least privilege, backups and evaluator-access settings not audited.
- ⬜ **Public** ASP.NET health/Swagger and React URLs. Localhost does not count.
- 🟡 Local AI operation is allowed (page 9); startup and evaluator instructions need clean-machine verification.
- 🟡 Durable Cloudinary storage implemented, but authorized/private image delivery is still required. **Use synthetic images only** until fixed.
- ⬜ One consolidated PDF: group report, four individual reports, evidence, references.
- ⬜ Real student AI-use logs, reflections and signed declarations (`docs/AI-USAGE.md` is only a draft).
- ⬜ Accessible ten-minute demo video (none exists yet).
- ⬜ Final naming, links and evaluator access through 21 October 2026.
- ⬜ Each member must explain, test, modify and debug their own contribution in the viva.

---

## 3. Proposed Member Allocation

> These are **future** responsibilities, not claims about authorship. Each member needs genuine work across API, database, React, Flutter, testing, Git and documentation, plus their own agent. Do not split into backend-only, web-only, mobile-only or testing-only roles.

| Member | Component | Agent | Focus |
|---|---|---|---|
| **1** | Customer assessment and sizing | SolarSizingAgent | Survey/profile APIs, `CustomerProfile`/`SolarSurvey` records, web survey screens, Flutter survey/photo/status. Structured plan steps with objective validation, dependencies, allowed tools. |
| **2** | Field operations and compliance | GridComplianceAgent | Assignment/check-in/inspection/telemetry APIs, `FieldJob`/`SiteInspection`/`ComplianceAssessment`, React dispatch/review, Flutter technician screens. Missing/out-of-range input handling, traces, real GPS/photo evidence. Explain why screening is not utility certification. |
| **3** | Engineering proposals and approval | SafetyGuardrailAgent | Proposal create/approve/reject/revise APIs, React engineer workspace, Flutter proposal history. Interrupted-run/revision recovery, audit presentation, unauthorized/concurrent/stale decision tests. Explain why server checks and the engineer decide approval, not the agent. |
| **4** | Equipment pricing and inventory | EquipmentPricingAgent | Catalog/supplier/quote/reserve/release APIs, React inventory/pricing, Flutter equipment status. Tool traces, timeout/rate-limit tests, quote recovery. Explain exchange validation, stock rechecks, rollback, idempotency. |

**All four should:** review another member's PR, document their own work, run the integrated scenario, and prepare a small viva change/debugging example. Preserve real Git history. Do not backdate or fabricate contributions.

---

## 4. How the Process Connects

1. **Homeowner** submits usage, roof details and photos in Flutter or React. ASP.NET checks identity/ownership and stores the survey in PostgreSQL.
2. ASP.NET calls internal Python with a server-held key. **PlannerAgent** lists steps, **SolarSizingAgent** calculates a preliminary system, an independent validator checks it, and ASP.NET stores the outcome and logs.
3. An **engineer assigns** field work. A **technician** submits measurements (normally from Flutter). **GridComplianceAgent** screens them and another validator checks the result.
4. Proposal creation invokes **SafetyGuardrailAgent** and validation. It stays pending until an **authorized engineer** approves, rejects or requests revision in React. The agent cannot approve.
5. After approval, **inventory staff** request pricing. The Python graph combines catalog selection with a real USD/LKR rate, then checks prices and availability.
6. Staff explicitly **reserve stock**. ASP.NET rechecks approval, permissions and quantities in a PostgreSQL transaction. The homeowner sees the updated status through the same API.

This is a request-driven, multi-stage process with human pauses. `/api/agent-workflows/test` exercises sizing only, not all four specialists.

---

## 5. Marks Breakdown

**Total: 100** (30 group + 70 individual)

| Group (30) | Marks | Individual (70) | Marks |
|---|---|---|---|
| Business logic | 10 | API | 10 |
| Integration, agent orchestration, state | 10 | Database | 10 |
| Documentation and deployment | 10 | React | 10 |
| | | Flutter | 10 |
| | | Agent contribution | 12 |
| | | Integration and security | 10 |
| | | Testing, CI, Git | 8 |

A predicted grade would be misleading without deployment, ownership and viva evidence.

---

## 6. Highest-Value Work (in priority order)

1. **Confirm the deadline / extension** with your lecturer (30 September 23:50 has passed).
2. **Agree genuine ownership now.** Create forward-looking issues; each member implements meaningful cross-layer improvements. This affects the 70 individual marks.
3. **Strengthen agent acceptance.** Add objective-abuse, timeout/rate-limit, retry-bound and interrupted-run tests. Keep authorization, calculations and stock changes deterministic. Justify the runtime in the ADR (no LLM currently runs).
4. **Deploy and verify access.** Public API/Swagger/health and React links, plus a tested APK. Secure uploads before using real documents.
5. **Record one continuous golden scenario.** Flutter start → persisted state and all four specialists → React approval → Flutter status, same survey ID. Include an unauthorized attempt and one safe failure. Add agent/tool/database performance evidence.
6. **Finish evidence and rehearsal.** Consolidated PDF, individual sections, ADRs, dated AI logs, personal reflections/signatures, video, green CI links. Every member must explain and modify their own contribution.

---

## 7. Fixes and Evidence from the First Audit

- Reproduced a Python `/workflow/test` HTTP 500 (dictionary logs violated a legacy string-log contract). Fixed serialization and added a regression test.
- Fixed ASP.NET forwarding: camelCase customer/input fields now map explicitly to Python snake_case; backend contract tests added.
- Preserved the objective through sizing and forwarded the persisted survey objective. Tested with non-default consumption.
- Empty downstream diagnostic responses now return a safe failure instead of a misleading completion.
- Added the omitted SolarSizingAgent to the health agent list.
- Corrected backend CI triggers; extended the live runner to verify the repaired cross-service contract.
- Fresh evidence JSON records statuses/durations, workflow output, approval history, pricing and a small concurrency sample (no tokens or connection strings).

The script leaves labelled synthetic demo records for inspection and releases its reservation. The audit did **not** send OTP email, test a physical device, deploy, record video, commit or push.

---

## 8. Related Documents

- English lecture audit, Sinhala lecture audit and bilingual presentation report (19 September 2026) distinguish deterministic specialists from LLM agents and record their own verification scope.
- Dated test results in older sections are historical evidence, not fresh runs.
