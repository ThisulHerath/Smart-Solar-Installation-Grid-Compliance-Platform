# ADR-007: No-paid-model operation and honest lecture alignment

## Status
Accepted for the current local university project, 16 September 2026.

## Context
The user requires the project to remain runnable without paid services. The supplied AI lectures distinguish predefined workflows from language-model agents that select their next action. This repository currently uses deterministic specialists; importing LangGraph does not turn them into LLM agents.

## Decision
Keep FastAPI, LangGraph, Pydantic and existing deterministic business rules. Add versioned, read-only lexical retrieval over six reviewed project-policy passages for compliance explanations. Keep calculations and approval checks independent of retrieved prose. Add bounded transient exchange-tool retries, actual sizing/compliance stage timing, input-evidence checks, React hook separation/lazy routes/error recovery, and API Problem Details.

No paid inference provider, model download, vector database, model-generated approval or new secret is required. Live foreign-exchange pricing still needs internet access to the existing public provider; PostgreSQL and email retain their configured service dependencies. This decision means no new paid model dependency, not a claim of fully offline operation or guaranteed free hosting forever.

## Alternatives and tradeoffs
- Paid hosted LLM: rejected under the user's constraint.
- Local open-weight model: potentially compatible with no-paid-inference operation, but no local runtime/model is configured. Hardware, model licence, latency, structured tool-call quality and failure tests need a separate evaluated setup. Do not silently download a large model or claim it is running.
- Full vector RAG: unnecessary for six short reviewed passages. Lexical retrieval is inspectable and has no extra service. It does not provide paraphrase understanding, embeddings or generative answers.
- Redux/TanStack Query/Next.js: useful options, not cumulative requirements. Retain Context for authentication and local state/hooks for this application. Revisit server-state caching if profiling demonstrates need.
- Autonomous supervisor, parallel agents and MCP: not added merely to reproduce slide keywords. The current dependencies naturally form a pipeline and the internal REST API is not MCP.

## Consequences
The demo remains reproducible without paid inference. Deterministic validation, authorized human approval and transactional stock reservation remain authoritative. The report must mark live LLM reasoning, generative RAG, dynamic planning and complete durable trace/recovery as gaps. If the lecturer requires LLM-selected actions for agentic acceptance, a tested local-model extension or an agreed interpretation is still necessary. No full-mark claim follows from this ADR.

## Lecture basis
lec1 PDF pages 29–31 (selection and ADRs); lec2 pages 12, 20–23, 37–46 (separation, hooks and suitable alternatives); lec5 part1 pages 22–25 (agency spectrum); lec5 part2 pages 6, 22, 25, 43 (retrieval, evaluation, sources and trust); lec5 part3 pages 12, 18, 21–24 (coordination, recovery and tracing).
