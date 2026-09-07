# ADR-003: Agentic AI Framework & LangGraph Orchestration

## Status
Accepted

## Context
The platform requires an intelligent, multi-agent AI system capable of decomposing solar installation requests, verifying statutory CEB/LECO grid compliance, computing bill of materials / pricing, and applying safety guardrails.

## Options Considered
1. **Raw LLM Prompt Chains**: Unstructured, difficult to inspect state, prone to hallucination, lacking cycle/state verification.
2. **LangGraph StateGraph**: State machine graph framework providing explicit typed state transitions, cyclical flows, multi-agent delegation, and structured tool validation.
3. **CrewAI / AutoGen**: Higher level abstractions, but less granular deterministic control over university assessment inspection.

## Decision
We adopted **Python FastAPI + LangGraph (`StateGraph`) + Pydantic**. The state schema tracks 13 explicit fields including `plan`, `tool_results`, `validation_results`, and `execution_logs`. The service acts as an internal microservice accessible exclusively by the ASP.NET Core API via a secured internal key header.

## Consequences
- **Positive**: Complete observability into intermediate reasoning steps, deterministic graph execution, strict separation of concerns among specialized agents.
- **Negative**: Requires ASP.NET Core to act as an orchestrating API gateway.
