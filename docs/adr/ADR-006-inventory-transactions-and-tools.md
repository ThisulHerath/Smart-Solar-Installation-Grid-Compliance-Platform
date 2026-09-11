# ADR-006: Equipment quotes, stock and external tools

Status: implemented. Group: 2026-AI-17.

Context: several users may attempt to reserve the last panels concurrently, while currency rates and catalog prices change independently. An advisory agent must not directly mutate stock or approve high-impact decisions.

Options: client-computed totals; direct agent database writes; or server-owned immutable quotes and transactional reservations.

Decision: ASP.NET owns catalog selection, authorization, persistence and stock movement. Python's LangGraph specialists calculate and validate an advisory quote using an allowlisted public exchange-rate tool. Quote age is one hour. Both services validate arithmetic. PostgreSQL serializable transactions plus item concurrency tokens, check constraints and active-reservation uniqueness protect writes.

Consequences: a quote does not hold stock. Price/stock changes can make reservation fail safely, requiring a new quote. Replays of successful reservations are idempotent. Equipment totals omit installation and taxes. Tool outages leave persisted failures. No LLM subscription is needed, but deterministic orchestration must be explained honestly in the viva.

Alternatives rejected: trusting a client-supplied rate would enable tampering; direct agent writes would bypass the API boundary and approval controls; only in-memory tests would not establish transaction correctness.
