# AI assistance disclosure draft

During this development session, OpenAI Codex assisted with Phase 5 inventory/catalog/pricing, the controlled exchange-rate integration, transactional stock reservations, workflow overview, dashboard, Flutter registration and equipment views, Android scaffolding, GPS/camera fixes, tests, CI configuration and technical documentation. It also reviewed and corrected UTC timestamp persistence, missing compliance approval checks, technician data access, telemetry selection and misleading simulated results.

Verification: automated backend/Python/web/Flutter tests; a real Neon migration and transaction test; live local API workflow; production web build; Android debug APK; rendered web inspection. The initial database test isolation problem and subsequent correction are recorded in database/inventory-design.md.

This file describes tool assistance, not individual student contribution. No student names, signatures, reflections, commit ownership or deployment evidence have been invented. Each student must supply their own contribution statement, commit/PR links, reviewed AI usage log, approximately one-page reflection and signed declaration. The group must verify and sign its own consolidated declaration.

The runtime application uses deterministic specialists orchestrated with LangGraph; it does not call Codex or an LLM during operation. Development assistance and the submitted runtime subsystem are separate.

## 15 September 2026 — assignment audit assistance

OpenAI Codex read the supplied assignment, inspected the implementation and prepared a requirements checklist and proposed Member 1–4 allocation. These labels describe future responsibilities, not historical authorship. Assistance corrected the diagnostic workflow log contract, ASP.NET/Python input mapping, objective propagation, empty-response failure handling and backend CI triggers, with regression tests. It corrected overstated agent documentation. Verification: 95 backend tests including isolated PostgreSQL, 40 Python, 32 React and 16 Flutter tests passed; the updated local live-workflow script passed. See `docs/assessment/assignment-readiness.md` and the linked evidence JSON. Students must review the changes and supply their own truthful reflections and declarations; this note does not replace them.
