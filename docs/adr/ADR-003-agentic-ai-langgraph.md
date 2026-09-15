# ADR-003: Agentic AI Framework & LangGraph Orchestration

## Status
Accepted

## Context
The platform requires an intelligent, multi-agent AI system capable of decomposing solar installation requests, screening measurements against documented project thresholds, computing bill of materials / pricing, and applying safety guardrails.

## Options Considered
1. **Raw LLM Prompt Chains**: Unstructured, difficult to inspect state, prone to hallucination, lacking cycle/state verification.
2. **LangGraph StateGraph**: State machine graph framework providing explicit typed state transitions, cyclical flows, multi-agent delegation, and structured tool validation.
3. **CrewAI / AutoGen**: Higher level abstractions, but less granular deterministic control over university assessment inspection.

## Decision
We adopted **Python FastAPI + LangGraph (`StateGraph`) + Pydantic**. The state schema tracks 13 explicit fields including `plan`, `tool_results`, `validation_results`, and `execution_logs`. The service acts as an internal microservice accessible exclusively by the ASP.NET Core API via a secured internal key header.

## Consequences
- **Positive**: Inspection of persisted execution summaries (not hidden reasoning), deterministic graph execution, strict separation of concerns among specialized agents.
- **Negative**: Requires ASP.NET Core to act as an orchestrating API gateway.

## Implementation review, 15 September 2026

Runtime has no language-model dependency. Sizing, safety and pricing use LangGraph subgraphs; compliance is procedural. ASP.NET coordinates durable business stages and human approval. PlannerAgent emits a fixed ordered plan, not objective-dependent task selection. State is distributed across workflow, compliance, proposal and quote records. Cross-stage timing/retry observability is incomplete. Address or justify these limitations against section 9.1 before claiming the highest rubric band.
