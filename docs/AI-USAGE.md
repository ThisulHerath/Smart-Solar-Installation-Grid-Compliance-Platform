 · MD
# AI Assistance Disclosure
 
**Smart Solar Installation & Grid Compliance Platform** · SE3090 – Software Engineering Frameworks · Group 2026-AI-17
 
---
 
## Purpose and Scope of This Document
 
This file discloses how AI tooling (OpenAI Codex) was used **during development** of this repository. It is a tool-usage log, not a contribution record.
 
> **This file describes tool assistance, not individual student contribution.**
> No student names, signatures, reflections, commit ownership, or deployment evidence have been invented here. Each student must independently supply their own contribution statement, commit/PR links, reviewed AI-usage log, an approximately one-page reflection, and a signed declaration. The group must verify and sign its own consolidated declaration. See [`CONTRIBUTIONS.md`](../CONTRIBUTIONS.md) for the member-by-member record this file does not replace.
 
### Status of This Document
 
This file is a **draft disclosure**, not four individuals' evidence. That status is also recorded independently in the assignment audit:
 
> "TODO — Actual student AI-use logs, student-written reflections and signed declarations. `docs/AI-USAGE.md` is a draft, not four individuals' evidence."
> — [`docs/assessment/assignment-readiness.md`](assessment/assignment-readiness.md)
 
This document and the audit are kept consistent deliberately: this file records what tooling did, the audit records what is still outstanding for submission.
 
### Raw Evidence
 
The session prompts referenced in this disclosure are retained in [`prompts/`](../prompts/) (`startpromt.md`, `prompt2.md`, `prompt2correction.md`, `prompt2correction2.md`, `prompt3.md`, `prompt3checking1`, `prompt4.md`) as the underlying record behind the summaries below. Each student's own reviewed AI-usage log, required separately, should reference the specific prompts and sessions relevant to their own work.
 
### Runtime vs. Development — Important Distinction
 
| | Development tooling | Runtime system |
|---|---|---|
| **What it is** | OpenAI Codex, used by the team while writing code | `agentic-ai/` — deterministic specialist agents orchestrated with LangGraph |
| **When it acts** | During this development session only | Every time the deployed application processes a survey, inspection, or proposal |
| **Calls an LLM?** | Yes (Codex, as a coding assistant) | **No** — the submitted application does not call Codex or any hosted LLM during operation |
 
Development assistance and the submitted runtime subsystem are entirely separate; nothing in this document implies the running product depends on an external AI service.
 
---
 
## Session 1 — Development Assistance (Phase 5 and Corrections)
 
**Scope of assistance:**
 
OpenAI Codex assisted with:
- Phase 5 inventory, catalog, and pricing functionality
- The controlled (allow-listed) exchange-rate integration
- Transactional stock reservations
- The workflow overview dashboard
- Flutter registration and equipment-status views
- Android scaffolding
- GPS/camera fixes
- Automated tests and CI configuration
- Technical documentation
  
**Corrections identified and applied:**
 
Codex also reviewed the existing implementation and corrected:
- Incorrect UTC timestamp persistence
- A missing compliance-approval check
- Overly broad technician data access
- Incorrect telemetry selection logic
- Misleading simulated ("demo") results that had been presented as real
  
**Verification performed:**

- Automated backend (.NET), Python, web (React), and Flutter test suites
- A real PostgreSQL (Neon) migration and transaction test
- A live local end-to-end API workflow run
- A production web build
- An Android debug APK build
- A rendered web inspection pass
> The initial database test-isolation problem encountered during this work, and its subsequent correction, are recorded in [`database/inventory-design.md`](../database/inventory-design.md).
 
---
 
## Session 2 — 15 September 2026: Assignment Audit Assistance
 
**Scope of assistance:**
 
OpenAI Codex read the supplied assignment specification, inspected the implementation against it, and prepared:
- A requirements checklist
- A proposed Member 1–4 responsibility allocation
> **These labels describe future responsibilities, not historical authorship.** The proposed allocation reflects how work could reasonably be divided going forward — it is not a record of who wrote what in the past.
 
**Corrections identified and applied:**
- The diagnostic workflow log contract
- ASP.NET ↔ Python input mapping
- Objective propagation through the workflow
- Empty-response failure handling
- Backend CI trigger configuration (with regression tests added)
- Overstated claims in the agent documentation were corrected to match actual behavior
  
**Verification performed:**
- 95 backend tests passed, including an isolated PostgreSQL integration test
- 40 Python tests passed
- 32 React tests passed
- 16 Flutter tests passed
- The updated local live-workflow script passed
  
**Evidence references:**
- [`docs/assessment/assignment-readiness.md`](assessment/assignment-readiness.md)
- The linked workflow evidence JSON referenced from that document
> Students must review these changes themselves and supply their own truthful reflections and declarations in their individual submissions. This disclosure note does not replace that requirement.
 
---
 
## What Students Still Need to Provide
 
This disclosure intentionally stops short of individual accountability. Each group member must separately submit:
 
- [ ] A personal contribution statement
- [ ] Links to their own commits / pull requests
- [ ] A reviewed AI-usage log for their own work (if applicable)
- [ ] An approximately one-page personal reflection
- [ ] A signed individual declaration
The group as a whole must:
 
- [ ] Verify and sign a consolidated group declaration
---
 
## Summary Timeline
 
| Date | Assistance | Primary output |
|---|---|---|
| Development session (undated) | Phase 5 inventory/pricing build + correctness fixes | Working inventory/pricing subsystem, bug corrections, passing test suites |
| 15 September 2026 | Assignment-specification audit | Requirements checklist, proposed role allocation, workflow/CI fixes, [`assignment-readiness.md`](assessment/assignment-readiness.md) |
 
---
 
*This document reflects tool usage as accurately as known at the time of writing. It should be updated if further AI-assisted sessions occur before submission.*
