"""Phase 4 proposal guardrail workflow implemented as a LangGraph StateGraph."""
from typing import Any, Dict, NotRequired, TypedDict
from datetime import datetime, timezone
import time
from uuid import uuid4

from langgraph.graph import END, START, StateGraph

from app.schemas.guardrail_schemas import GuardrailInput, GuardrailResult, GuardrailWorkflowResult
from app.agents.safety_guardrail_agent import SafetyGuardrailAgent
from app.agents.proposal_validator import DeterministicProposalValidator

guardrail_agent = SafetyGuardrailAgent()
validator = DeterministicProposalValidator()


class ProposalWorkflowState(TypedDict, total=False):
    payload: Dict[str, Any]
    workflow_id: str
    proposal_id: str | None
    input_data: GuardrailInput
    input_error: str
    guardrail_result: GuardrailResult
    validation: Dict[str, Any]
    execution_logs: list[dict[str, Any]]
    response: GuardrailWorkflowResult


def _log(logs, agent, step, status, summary, duration_ms=0, error=None):
    now = datetime.now(timezone.utc).isoformat()
    return logs + [{
        "agent_name": agent,
        "step_name": step,
        "status": status,
        "started_at": now,
        "completed_at": now,
        "duration_ms": duration_ms,
        "output_summary": summary,
        "error_message": error,
        "retry_count": 0
    }]


def _safety_guardrail(state: ProposalWorkflowState) -> ProposalWorkflowState:
    payload = state["payload"]
    logs = state.get("execution_logs", [])
    started = time.time()
    try:
        input_data = GuardrailInput.model_validate(payload)
        logs = _log(logs, "GuardrailPlanner", "ingestion", "completed",
                    f"Proposal {state.get('proposal_id') or 'N/A'} — {input_data.recommended_kw:.2f}kW ingested.",
                    int((time.time() - started) * 1000))
        result = guardrail_agent.evaluate(input_data)
        logs = _log(logs, "SafetyGuardrailAgent", "evaluation", "completed",
                f"Safety: {result.safety_status}, AI requires_approval: {result.requires_approval}.")
        return {"input_data": input_data, "guardrail_result": result, "execution_logs": logs}
    except Exception as ex:
        return {"input_error": str(ex), "execution_logs": _log(
            logs, "Guardrail", "ingestion", "failed", "Input validation failed.",
            int((time.time() - started) * 1000), str(ex))}


def _deterministic_validate(state: ProposalWorkflowState) -> ProposalWorkflowState:
    if state.get("input_error"):
        result = GuardrailResult(
            workflow_id=state["workflow_id"], safety_status="REQUIRES_APPROVAL", risk_level="HIGH",
            requires_approval=True, issues=[f"Input validation error: {state['input_error']}"],
            recommendations=["Provide complete proposal data and retry."],
            recommendation_summary="Proposal guardrail could not be evaluated due to invalid input.")
        return {
            "guardrail_result": result,
            "validation": validator.validate(0, 0, 0, 0, "UNKNOWN", True),
        }
    started = time.time()
    result = state["guardrail_result"]
    data = state["input_data"]
    val = validator.validate(
        data.recommended_kw, data.panel_count, data.inverter_size_kw,
        data.estimated_cost_lkr, data.grid_compliance_status, result.requires_approval)
    return {"validation": val, "execution_logs": _log(
        state.get("execution_logs", []), "DeterministicProposalValidator", "validation", "completed",
        f"Final requires_approval: {val['requires_approval']}. Override: {bool(val['override_reason'])}.",
        int((time.time() - started) * 1000), val["override_reason"] or None)}


def _format(state: ProposalWorkflowState) -> ProposalWorkflowState:
    result = state["guardrail_result"]
    val = state["validation"]
    issues = list(result.issues)
    issues.extend(v for v in val["violations"] if v not in issues)
    final_status = "BLOCKED" if not val["valid"] else "REQUIRES_APPROVAL" if val["requires_approval"] else result.safety_status
    logs = _log(state.get("execution_logs", []), "ApprovalRequirementSetter", "persist_format", "completed",
                f"Final decision: {final_status}, requires_approval={val['requires_approval']}.")
    response = GuardrailWorkflowResult(
        workflow_id=state.get("input_data", None).workflow_id if state.get("input_data") else state["workflow_id"],
        proposal_id=state.get("proposal_id"), safety_status=final_status, risk_level=result.risk_level,
        requires_approval=val["requires_approval"], issues=issues,
        recommendations=list(result.recommendations), recommendation_summary=result.recommendation_summary,
        validation_override=bool(val["override_reason"]), override_reason=val["override_reason"],
        execution_logs=logs)
    return {"response": response}


_graph = StateGraph(ProposalWorkflowState)
_graph.add_node("SafetyGuardrailAgent", _safety_guardrail)
_graph.add_node("DeterministicValidator", _deterministic_validate)
_graph.add_node("PersistFormat", _format)
_graph.add_edge(START, "SafetyGuardrailAgent")
_graph.add_edge("SafetyGuardrailAgent", "DeterministicValidator")
_graph.add_edge("DeterministicValidator", "PersistFormat")
_graph.add_edge("PersistFormat", END)
proposal_graph = _graph.compile()


def run_guardrail_workflow(payload: Dict[str, Any]) -> GuardrailWorkflowResult:
    workflow_id = payload.get("workflow_id", f"wf-guard-{uuid4().hex[:8]}")
    try:
        state = proposal_graph.invoke({
            "payload": payload,
            "workflow_id": workflow_id,
            "proposal_id": payload.get("proposal_id"),
            "execution_logs": []
        })
        return state["response"]
    except Exception as ex:
        return GuardrailWorkflowResult(
            workflow_id=workflow_id, proposal_id=payload.get("proposal_id"),
            safety_status="REQUIRES_APPROVAL", risk_level="HIGH", requires_approval=True,
            issues=[f"Workflow exception: {ex}"], recommendations=["Retry guardrail evaluation."],
            recommendation_summary="Guardrail evaluation failed. Manual senior engineer review required.",
            validation_override=False, override_reason="", execution_logs=[])
