# Smart Solar: lecture theory audit and presentation guide

Review began 16 September; report completed 19 September 2026 • English report • Local source review and automated verification

## 1. Main findings

The application already applies many of the core framework, React, C#, database and security concepts in the slides. I added several missing practical applications and tested them. It remains runnable without a paid language-model service, as requested.

**The important limitation:** the four classes named “Agent” are currently deterministic domain specialists. Their calculations and next steps are programmed. There is no configured live language model choosing tools, no ReAct reasoning loop, and no full generative RAG. LangGraph provides orchestration; it is not itself the intelligence of a language model. Describe the current implementation as **validated specialist workflows with human approval**, and explain the limitation openly. A no-paid-service requirement can also be met by a local model, but one has not been installed or evaluated here.

This report is an implementation audit, not an awarded grade, safety certification or proof that every screen works. It distinguishes existing work from this change. All source paths are relative to the repository root. Slide references use **PDF page numbers**, which can differ from numbers printed on slides. The two files named `lec5 part2` and `lec5 part3` contain Lecture 06 and Lecture 07 material respectively.

Status key: **✓ Existing** = found in the source; **✓ Added** = implemented in this change and checked at the stated scope; **△ Partial** = a meaningful gap remains; **○ Alternative** = optional design choice, not something to install just to tick a box.

## 2. Lecture-by-lecture review

### Lecture 1 — frameworks, inversion of control and selection

- **✓ Existing — inversion of control (p.13).** ASP.NET receives HTTP requests and invokes controllers; React invokes components during rendering; Flutter runs the widget lifecycle. Application code fills framework extension points. `backend/SolarPlatform.Api/Program.cs` and `frontend-web/src/App.tsx` show this clearly.
- **✓ Existing — separation and reuse.** Controllers, services, DTOs, database entities, client API services and reusable widgets have distinct roles. This is more than using a library: framework lifecycles control execution.
- **✓ Added — justified selection (pp.29–31).** ADR-007 records the no-paid-model constraint, alternatives, benefits and limits. Existing ADR-001–006 cover client state, Flutter state, orchestration, persistence, deployment and transactions. A written decision is evidence of reasoning; it is not a performance benchmark.
- **△ Partial — cloud-native delivery (p.39).** Docker and CI definitions exist. That does not prove public deployment, production observability, backup recovery or current green GitHub runs. Localhost URLs are not public deployment evidence.
- **○ Alternative — microservices/serverless.** The current ASP.NET business API plus internal Python service fits the project. Splitting every business component into a separate deployed service would add operational work without proving better design.

### Lecture 2 — advanced React

- **✓ Existing — composition, controlled inputs and routing (pp.8, 16–19, 37–38).** Reusable fields, search, record references, photo galleries and layout components are composed into screens. Auth Context supplies shared login state. `ProtectedRoute.tsx` improves navigation; backend authorization remains the security boundary.
- **✓ Added — UI / hook / service separation (pp.12, 20–23, 32).** `hooks/useInventoryCatalog.ts` owns inventory server state, loading/error handling, a 250 ms debounce and AbortController cleanup. `InventoryPage.tsx` renders filters and results, while `services/inventoryService.ts` owns HTTP access. Aborted responses cannot overwrite newer results.
- **✓ Existing — accessible validation and keyboard search.** `AuthField.tsx`, `ValidatedForm.tsx`, `SearchBox.tsx` and validation helpers already provide reusable behavior. This audit does not claim an exhaustive accessibility certification across every page.
- **✓ Added — lazy route loading and Suspense (p.37, p.44).** Staff/workspace pages now load as separate route chunks. The production build confirms separate Inventory, Proposal, Field and Profile chunks. No before/after load-time benchmark was taken, so do not claim a percentage speedup.
- **✓ Added — render error boundary (p.39).** `PageErrorBoundary.tsx` offers reload/home recovery without rendering the exception text. It handles render/lazy-import failures; event-handler and asynchronous request errors still need their own handling.
- **○ Alternative — Redux, Zustand, React Hook Form, Zod, TanStack Query, Next.js (pp.27–28, 33–35, 39, 46).** These are possible solutions, not seven compulsory dependencies. Existing Context/local state and reusable validators suit current needs. Inventory has a focused hook, not a complete query cache. Other large pages can still be decomposed further.

### Lecture 3 — C#, OOP, ASP.NET and REST

- **✓ Existing — encapsulation and interfaces (pp.16–19).** Business rules belong in services rather than UI buttons. Interfaces such as `IAgenticAiService` permit substitute implementations in tests. Meaningful abstraction matters more than inventing inheritance hierarchies.
- **✓ Existing — dependency injection (p.26).** `Program.cs` registers services and the EF context; controllers request dependencies through constructors. Scoped services/context follow request lifetimes. A singleton should not capture a request-scoped context.
- **✓ Existing — middleware pipeline (p.27).** Authentication, authorization and exception handling form request-processing stages. Middleware ordering affects both protection and error handling.
- **✓ Existing — REST and layered design (pp.30–35, 38–42).** Survey, field-job, proposal and inventory resources have DTOs and resource routes. Workflow actions such as submit/approve/reserve represent business operations. Controllers delegate to services; clients do not query PostgreSQL directly.
- **✓ Existing — async operations, Swagger and testing (pp.45–51).** Async database/HTTP access avoids unnecessarily blocking request threads. Swagger describes contracts; it is not proof that authorization and business behavior are correct. Automated tests cover those separately.
- **✓ Added — standard exception responses.** The global exception handler now emits Problem Details with a trace identifier and a compatible `message` field for existing clients. Unknown failures and wrapped infrastructure errors do not return provider details. This standardization applies to middleware-handled exceptions; controller-specific responses are not all rewritten.

### Lecture 4 — persistence, transactions and authorization

- **✓ Existing — relational modeling (pp.16–25, 31–37).** `Data/AppDbContext.cs`, inventory configuration and migrations model users, surveys, jobs, inspections, proposals, decisions, equipment and quotes. UUID keys identify records; SKU is a business identifier. Foreign keys, indexes and constraints complement application checks.
- **✓ Existing — transaction integrity (pp.9–10).** `Services/InventoryService.cs` checks quote/approval state and stock inside transactional reservation logic. Serializable isolation, concurrency checks and replay handling protect against double reservation. This is a concrete ACID example.
- **△ Partial — integrity evidence.** The database integration test was skipped in this audit because its isolated database was not configured. Earlier audit evidence is historical, not a fresh result. Normalization should be justified per entity; stored quote/result snapshots intentionally preserve historical decisions rather than always recomputing current values.
- **✓ Existing — authentication versus authorization (pp.40–46, 49–53).** JWT establishes identity; role and ownership checks decide permission. Hiding a web button is insufficient. An authenticated homeowner must still be denied another homeowner's survey or an engineer-only approval operation.
- **✓ Added — Problem Details and safe failures (p.54).** Middleware responses include `status`, `title`, `detail`, `instance`, `traceId` and compatibility `message`. Tests verify generic 500 and wrapped 503 responses do not expose synthetic secret strings.
- **△ Partial — deployment security.** Browser token storage, token lifecycle/refresh design and authorized delivery of stored photos need hardening before real public use. Protected metadata routes do not automatically protect a public static image URL. Native secure storage does not remove browser XSS risks. Database least privilege and recovery have not been audited here.
- **○ Alternative — CAP and sticky sessions (pp.11–12, 42).** Do not say PostgreSQL “guarantees all CAP properties.” Session-affinity solutions are not automatically necessary for this JWT-based API. These theories guide tradeoffs; they are not standalone features to add.

### Lecture 5 part 1 — LLMs and agent fundamentals

- **✓ Existing — structured contracts, specialist responsibilities, guardrails and human approval.** Pydantic validates Python input/output; backend DTOs and services independently control actions. These are useful foundations for an agent framework.
- **△ Partial — actual agent autonomy (pp.22–25, 29, 32).** The lecture's LLM-directed loop observes tool results and chooses a next action. The present PlannerAgent emits a fixed eight-step roadmap. It does not reinterpret a goal, choose tools dynamically or replan after failure. Its docstring now states this honestly.
- **✓ Existing / ✓ Added — simplest suitable workflow (p.25).** Deterministic arithmetic and explicit approval dependencies are preserved. No language model should replace stock arithmetic or authorize installation.
- **△ Partial — six framework components (p.36).** Tools, some state/history, monitoring and orchestration exist. Model inference and runtime prompts for such inference are absent. Prompt files or class names alone do not establish model execution.

### Lecture 5 part 2 — retrieval, RAG and memory

- **✓ Added — source-backed retrieval foundations (pp.6, 22, 25, 43).** `app/tools/project_knowledge.py` indexes six reviewed project passages. A deterministic lexical score selects matching passages and returns a title, source ID, version and score. The compliance pipeline retrieves grid/inspection guidance and includes references in its notes and structured response.
- **✓ Added — evidence boundaries.** Empty matches return no evidence; overlong queries are rejected; no arbitrary path, web URL, upload or customer record is a source. These passages describe project rules, not official utility regulations. Retrieval does not change the numerical validator or grant clearance.
- **✓ Added — small retrieval evaluation (p.22).** Six deliberately small queries each expect one passage at rank 1. All six pass. On this fixture only, Hit@1 and MRR are 1.0. This is a regression set, not proof of general language understanding or Sinhala retrieval quality.
- **△ Partial — full RAG (pp.6, 15–21, 32, 37).** There are no embeddings, vector store, semantic search, hybrid reranking or language-model answer generation. Therefore this feature is lexical retrieval with cited project guidance, not full generative RAG. No claim of answer faithfulness evaluation is made because no model generates answers.
- **△ Partial — memory (p.47).** Request/graph state resembles working memory; persisted decisions resemble episodic history; reviewed passages resemble semantic facts; validators/roadmaps resemble procedural knowledge. These are conceptual mappings, not a model memory subsystem that automatically recalls and learns from conversations.

### Lecture 5 part 3 — coordination, reliability, middleware and MCP

- **✓ Existing — pipeline coordination (pp.12–16).** A survey precedes sizing; an inspection precedes compliance; validated proposals precede human approval; approval precedes reservation. These dependencies make a pipeline suitable.
- **✓ Existing — structured handoffs and persisted IDs (pp.19–20).** ASP.NET exchanges typed payloads with Python and stores business results. Survey/job/proposal/quote identifiers connect stages. The whole workflow is not one long in-memory LLM conversation.
- **✓ Added — bounded external-tool recovery (p.21).** Exchange-rate access retries once for selected transient failures: timeout/network failure or HTTP 429/502/503/504. It waits 200 ms before the retry and still validates response/currency/freshness. Ordinary 4xx and invalid response data do not receive this retry. Failure is surfaced; a fictional fallback exchange rate is never used.
- **✓ Added — actual stage timing (pp.24, 27–31).** Sizing and compliance stages now capture start/end, measured duration, workflow trace ID and unique span ID. A failed sizing stage retains its failure event. The sizing graph has an eight-step recursion cap. Proposal/pricing trace formats are still less complete; these are not full distributed OpenTelemetry traces.
- **✓ Added — evidence-required input.** An omitted inverter-location suitability value is now unknown rather than silently true. Compliance cannot become clear just because this evidence was absent.
- **✓ Existing — least privilege and human approval (pp.23, 30).** Python does not reserve stock or approve a proposal. Backend services enforce authorized actions. A reassuring AI sentence cannot bypass a failed validation result.
- **○ Alternative — router/parallel/supervisor and MCP (pp.12, 18, 33–36).** Not every coordination pattern is useful here. The internal FastAPI HTTP API is REST, not an MCP server. No MCP support is claimed.

## 3. What exactly changed in this audit?

1. Extracted debounced/cancellable inventory fetching into a reusable React hook; retained existing page behavior.
2. Added lazy loading for workspace routes, a loading fallback and a safe page-crash recovery screen.
3. Changed middleware-handled backend exceptions to Problem Details while preserving client compatibility.
4. Added six versioned project-policy passages, lexical retrieval and compliance references.
5. Replaced synthetic timing for sizing/compliance with measured stage events; retained failures and capped sizing graph steps.
6. Added a single bounded retry for transient exchange-tool failures, without a made-up fallback rate.
7. Rejected non-finite sizing values and stopped treating missing inverter-location evidence as suitable.
8. Added focused regression tests, ADR-007 and these bilingual reports. No paid inference dependency, database migration, commit or push was added.

## 4. How the complete workflow connects

**React / Flutter → ASP.NET API → business services → PostgreSQL.** Where calculation or screening is needed, ASP.NET calls **internal FastAPI → specialist workflow → independent validator**, receives structured results, then persists the appropriate state. An internal service key protects the Python boundary. Client JWTs and backend role/ownership checks protect user actions.

The browser and phone share record IDs through the API. They do not call Python or PostgreSQL directly. PostgreSQL holds durable business records; Python evaluates bounded requests. Engineer approval is a persisted business pause, not a sleeping Python process. After approval, pricing and reservation are separate authorized operations.

### Worked example: a hypothetical 600 kWh home

This is test data and a calculation explanation, not a live installation recommendation.

1. **Homeowner:** create a survey with monthly use **600 kWh**, roof area **80 m²**, grid type **ThreePhase**, and a clearly labelled test address. Submit the survey. The sizing rule produces **600 ÷ 120 = 5.00 kW**; preliminary 400 W sizing currently returns **12 panels** using the existing rounding rule. Record the survey reference.
2. **Administrator / engineer:** create or open its field job and assign a technician. Assignment connects the technician to this survey; it is not a new unrelated survey.
3. **Technician:** inspect the same site, record measurements and add photos. For a synthetic compliant example, use **400 V**, **50 Hz**, **63 A**, and inverter location **suitable**. Complete any other fields requested by the form. These values are demonstration inputs, not instructions to measure unsafe equipment yourself.
4. **Compliance workflow:** validate input → retrieve grid/inspection project guidance → apply screening rules → independently check the candidate. With the example measurements it reports **COMPLIANT / LOW** under the project's rules and includes versioned references. Missing evidence or out-of-range values produce issues instead.
5. **Homeowner / proposal workflow:** request a proposal using the completed assessment. SafetyGuardrailAgent produces structured findings and the deterministic validator checks them. If the proposal was created before inspection, its stored result may still describe the old state: request a fresh proposal using the completed assessment, rather than bypassing validation.
6. **Senior engineer / authorized administrator:** review technical details, site evidence and technician photos, then approve, reject or request revision. A “safe” specialist result is not the engineer's approval. An invalid proposal must remain blocked.
7. **Inventory officer:** calculate the equipment estimate for the approved proposal. The catalog policy uses **500 W panels**, so a 5 kW quote selects **10 panels** plus a compatible inverter. At illustrative prices **USD 100 × 10 + USD 500**, and an illustrative **300 LKR/USD**, the equipment subtotal is **LKR 450,000**. Actual UI totals use catalog prices and the validated current provider rate. Installation and taxes are excluded.
8. **Reserve equipment:** ASP.NET rechecks approval, quote expiry and stock inside the reservation transaction. On success, reserved/available quantities change. A repeated successful reservation must not deduct stock twice. The homeowner can then see the updated shared status.

**Panel-count caveat:** preliminary sizing assumes 400 W and catalog pricing assumes 500 W. Therefore 12 and 10 are not the same bill of materials. The current preliminary rounding also does not guarantee that 12 × 400 W exactly supplies 5 kW. Explain the stages and assumptions; harmonizing preliminary sizing with final equipment selection is an outstanding domain-design improvement before calling this a final engineering design.

### Failure examples worth demonstrating

- Leave a required inspection value absent: no compliance clearance.
- Try to approve as a homeowner: backend denies the action, even if a handcrafted request is sent.
- Open an old pre-inspection proposal: validation can remain blocked; use a newly evaluated proposal.
- Exchange provider unavailable after the bounded retry: pricing fails visibly; no invented rate and no automatic reservation.
- Stock changes after quote generation: reservation rechecks stock and can reject/conflict; the quote is not a stock guarantee.
- Invalid sizing such as NaN: workflow fails with a recorded failed stage rather than returning a successful estimate.

## 5. The different “four parts” — do not mix them up

### Four coordination patterns in the lecture

`lec5 part3.pdf`, p.12 names **Router, Pipeline, Parallel, Supervisor**.

1. **Router:** choose one specialist based on the request. A future help request might route to billing or field support. Existing HTTP routing is not evidence of an LLM router.
2. **Pipeline:** each stage feeds the next. This is the main implemented pattern, because approval must follow inspection/validation.
3. **Parallel:** independent specialists run together, then results merge. It could suit independent document checks, but dependent approval/reservation stages should not be parallelized. No runtime parallel-agent workflow is claimed.
4. **Supervisor:** a coordinator dynamically chooses specialists and next steps from results. The fixed PlannerAgent is not such a supervisor.

These are coordination choices, not a rule that every project must implement all four.

### Four domain specialists in this project

1. **SolarSizingAgent:** survey electricity use → preliminary capacity, panel and inverter estimates.
2. **GridComplianceAgent:** technician measurements → project-rule screening, violations and recommendations.
3. **SafetyGuardrailAgent:** proposal data → safety findings and escalation signals; cannot grant human approval.
4. **EquipmentPricingAgent:** compatible equipment plus the exchange tool → structured equipment cost; cannot write inventory.

PlannerAgent adds a fixed roadmap. Independent validators check outputs rather than relying only on the specialist that produced them. Four class names alone do not prove four LLM agents.

### Four memory types and six framework components

`lec5 part2.pdf`, p.47 lists **working, episodic, semantic and procedural memory**. The mappings are graph input/state, stored events/decisions, reviewed knowledge passages, and rules/roadmaps. Those mappings explain architecture; they do not establish autonomous learning.

`lec5 part1.pdf`, p.36 actually lists **six** components: **Models, Tools, Memory, Monitoring, Prompts, Middleware/Orchestration**. Model inference and runtime prompting remain missing here; the other areas exist to differing degrees.

For a simple demo narrative you may group this application into four stages — **assess → inspect → review → prepare equipment** — but label them business stages, not the lecturer's universal definition of an agent.

## 6. Four members: four end-to-end business components

This is a proposed allocation. The user said work so far was done alone. It is not a claim that four members already authored the code. Do not divide only by technology layer; each member needs genuine work, tests, review and explanation across their component.

### Member 1 — Customer assessment and sizing

Own surveys, profile-related assessment inputs and preliminary sizing. React: survey review and useful references. Flutter: homeowner survey/photo/status flow. Backend/data: survey DTOs, ownership, validation and workflow records. Python: SolarSizingAgent and sizing validation. Demonstrate 600 kWh → 5 kW, invalid input rejection and a user unable to read someone else's record. Next useful work: resolve the preliminary/final panel-policy inconsistency and improve structured plan contracts with tested dependencies.

### Member 2 — Field operations and compliance

Own assignment, technician jobs, inspections, photos, location and electrical measurements. React: dispatch and inspection review. Flutter: assigned-job capture, camera/gallery and location experience. Backend/data: job/inspection/telemetry/photo access. Python: GridComplianceAgent, source-backed policy evidence and independent compliance validation. Demonstrate compliant data and one missing/unsafe reading. Next useful work: authenticated photo delivery and real-device camera/GPS tests.

### Member 3 — Engineering proposal and approval

Own proposal generation, evidence review, safety findings, revision/rejection/approval and decision history. React: engineer review with technician photos. Flutter: homeowner proposal outcome. Backend/data: proposal lifecycle, authorization and audit records. Python: SafetyGuardrailAgent and deterministic proposal validation. Demonstrate that invalid input blocks approval and a homeowner cannot approve. Next useful work: clarify stale proposals after new inspections and extend actual timing/failure retention through this subgraph.

### Member 4 — Equipment, pricing and reservation

Own equipment CRUD/search, supplier/stock information, estimates, currency conversion and reservation/release. React: professional catalog and quotation workflow. Flutter: equipment status and quotation presentation. Backend/data: catalog, quotes, stock transactions and concurrency. Python: EquipmentPricingAgent and bounded exchange-rate tool. Demonstrate correct arithmetic, outage behavior and repeated reservation without double deduction. Next useful work: run isolated PostgreSQL concurrency tests and extend tool-attempt traces.

Each member should make genuine issues, commits, tests and peer reviews, and write their own reflection. Shared architecture can be documented jointly. Do not fabricate contribution history, signatures or evaluation evidence.

## 7. Verification in this audit

- **Python:** 55 tests passed. Includes six small retrieval cases, safe compliance failure, missing location evidence, measured sizing events, failed-stage retention and bounded tool retries. A dependency deprecation warning remains.
- **ASP.NET:** 98 tests passed; 1 PostgreSQL integration test skipped. The skipped test is not a pass and provides no fresh database-concurrency proof.
- **React:** 47 tests passed across 12 files. The intentional error-boundary test causes expected development error output; an existing account-flow test also warns that its test router has no dashboard route.
- **Web production build:** TypeScript and Vite succeeded; separate route chunks were emitted.
- **Flutter (19 September):** 20 tests passed; `flutter analyze` reported no issues. No Flutter source was changed in this lecture audit. Package-update notices are informational, not analyzer failures.

These are automated local checks. They do not establish production uptime, physical-device behavior, load capacity or a fresh browser-to-phone end-to-end run. Earlier evidence in `assignment-readiness.md` is dated separately and must not be relabelled as this run.

Useful reruns from the repository: `dotnet test backend/SolarPlatform.Tests -c Release`; run `npm test` and `npm run build` inside `frontend-web`; run `..\.venv\Scripts\python.exe -m pytest -q` inside `agentic-ai`; run `flutter analyze` and `flutter test` inside `frontend-mobile`.

## 8. What remains for a stronger submission

1. Resolve agentic acceptance explicitly. If the lecturer expects LLM-selected tools, the current deterministic workflow is partial. An evaluated local model could satisfy no-paid-inference operation; it still needs resource planning, typed tool contracts, bounded steps, safe failure and actual evidence. Do not simply change labels.
2. Extend trace consistency and durable interrupted-run recovery across all four components. Current measured timing improvements cover sizing and compliance, not the entire business process.
3. Finish deployment security: protected image delivery, token lifecycle review, HTTPS, real configuration, least-privilege database access and recovery evidence.
4. Run a clean end-to-end demonstration with the same survey ID through Flutter submission, React assignment/review, pricing/reservation and mobile status. Record negative cases as well as the happy path.
5. Harmonize and explain sizing/catalog assumptions. The application is a planning prototype; do not present its project thresholds as certified CEB/LECO requirements.
6. Supply actual public URLs, a tested final mobile build, the demo video, genuine four-member contributions, individual reflections and the assignment's final report format. No report or test total guarantees a mark.

### Short presentation explanation

“Our platform connects homeowner assessment, technician inspection, engineer approval and equipment preparation through one secured API. Four specialists produce structured results. Independent rules validate those results; authorized humans approve proposals, and database transactions protect stock. We apply React composition and hooks, ASP.NET dependency injection and middleware, EF relationships and transactions, and measured workflow logging. The current no-paid-model version is a deterministic pipeline with cited project guidance. We do not claim autonomous LLM reasoning or full RAG.”

## 9. Source register

- `lec1.pdf` — 47 pages; cited pp.13, 29–31, 39–40.
- `lec2.pdf` — 52 pages; cited pp.8, 12, 16–23, 27–28, 32–39, 42–46.
- `lec3.pdf` — 57 pages; cited pp.16–19, 26–27, 30–35, 38–42, 45–51.
- `lec4.pdf` — 60 pages; cited pp.9–12, 16–25, 31–46, 49–54.
- `lec5 part1.pdf` — 40 pages; cited pp.22–25, 29, 32, 36.
- `lec5 part2.pdf` — 57 pages; cited pp.6, 15–25, 32, 37, 43, 47.
- `lec5 part3.pdf` — 37 pages; cited pp.12–24, 27–36.

All seven were supplied from the user's `YEAR3SEM1/SE3090-Software Engineering Frameworks/lec` folder. Text was extracted and representative theory diagrams were visually inspected. The source-to-code mapping above is this audit's interpretation; examples are labelled synthetic. No external legal or utility-standard verification was performed.
