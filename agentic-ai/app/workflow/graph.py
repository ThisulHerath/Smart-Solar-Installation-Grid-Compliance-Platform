"""Phase 2 sizing graph: Planner -> SolarSizingAgent -> DeterministicValidator."""
from typing import Any, Dict
from datetime import datetime, timezone
import uuid
from app.agents.planner_agent import PlannerAgent
from app.agents.solar_sizing_agent import SolarSizingAgent
from app.schemas.state import SolarSizingInput, WorkflowStateDict

planner, sizing_agent = PlannerAgent(), SolarSizingAgent()

def _event(state: Dict[str, Any], agent: str, step: str, status: str, summary: str, validation=None, error=None):
    now = datetime.now(timezone.utc).isoformat()
    return [entry for entry in state.get("execution_logs", []) if isinstance(entry, dict)] + [{"agent_name": agent, "step_name": step, "status": status, "started_at": now, "completed_at": now, "retry_count": 0, "output_summary": summary, "validation_result": validation, "error_message": error}]

def node_planner(state: Dict[str, Any]) -> Dict[str, Any]:
    output = planner.execute(state)
    return {**output, "current_step": "SolarSizingAgent", "completed_steps": state.get("completed_steps", []) + ["Planner"], "execution_logs": _event(state, "Planner", "planning", "completed", "Sizing plan created.")}

def node_sizing(state: Dict[str, Any]) -> Dict[str, Any]:
    survey = SolarSizingInput.model_validate({"workflow_id": state["workflow_id"], "customer_id": state.get("customer_id") or "", **state["input_data"]})
    candidate = sizing_agent.execute(survey).model_dump()
    return {"candidate_recommendation": candidate, "current_step": "DeterministicValidator", "completed_steps": state.get("completed_steps", []) + ["SolarSizingAgent"], "execution_logs": _event(state, "SolarSizingAgent", "sizing", "completed", "Structured sizing candidate created.")}

def node_validator(state: Dict[str, Any]) -> Dict[str, Any]:
    data, candidate = state["input_data"], state.get("candidate_recommendation", {})
    expected_kw = round(float(data["monthly_kwh"]) / 120.0, 2)
    expected_panels = max(1, round(expected_kw * 1000 / 400))
    checks = {"monthly_kwh_valid": float(data["monthly_kwh"]) > 0, "roof_area_valid": float(data["roof_area_sqm"]) > 0, "recommended_kw_consistent": candidate.get("recommended_kw") == expected_kw, "panel_count_reasonable": candidate.get("estimated_panel_count") == expected_panels, "inverter_size_consistent": candidate.get("estimated_inverter_kw") == expected_kw, "schema_valid": all(k in candidate for k in ("recommended_kw", "estimated_panel_count", "estimated_inverter_kw", "reason", "assumptions"))}
    valid = all(checks.values())
    errors = [] if valid else ["Deterministic solar sizing validation failed."]
    return {"validation_results": {"valid": valid, "checks": checks}, "errors": errors, "final_result": candidate if valid else {}, "current_step": "COMPLETE" if valid else "FAILED", "final_outcome": "Preliminary solar sizing completed." if valid else "Solar sizing was rejected by deterministic validation.", "completed_steps": state.get("completed_steps", []) + ["DeterministicValidator"], "execution_logs": _event(state, "DeterministicValidator", "validation", "completed" if valid else "failed", "Independent sizing validation completed.", checks, errors[0] if errors else None)}

def build_workflow():
    from langgraph.graph import StateGraph, END
    graph = StateGraph(WorkflowStateDict)
    graph.add_node("Planner", node_planner); graph.add_node("SolarSizingAgent", node_sizing); graph.add_node("DeterministicValidator", node_validator)
    graph.set_entry_point("Planner"); graph.add_edge("Planner", "SolarSizingAgent"); graph.add_edge("SolarSizingAgent", "DeterministicValidator"); graph.add_edge("DeterministicValidator", END)
    return graph.compile()

compiled_workflow = build_workflow()

def run_solar_sizing_workflow(payload: Dict[str, Any]) -> Dict[str, Any]:
    state = {"workflow_id": payload.get("workflow_id", str(uuid.uuid4())), "customer_id": payload.get("customer_id"), "objective": "Preliminary solar system sizing", "input_data": payload, "plan": [], "current_step": "START", "completed_steps": [], "validation_results": {}, "errors": [], "final_outcome": "", "execution_logs": []}
    try: return compiled_workflow.invoke(state)
    except Exception:
        state.update({"current_step": "FAILED", "errors": ["Solar sizing workflow could not be completed."], "final_outcome": "Solar sizing processing failed."})
        return state

def run_solar_workflow(objective: str, customer_id: str = None, input_data: Dict[str, Any] = None) -> Dict[str, Any]:
    payload = {"workflow_id": str(uuid.uuid4()), "customer_id": customer_id or "test-customer", "monthly_kwh": 1200, "roof_area_sqm": 80, "grid_type": "SinglePhase", **(input_data or {})}
    result = run_solar_sizing_workflow(payload)
    # Retain the legacy test-workflow response convention while survey sizing uses COMPLETE/FAILED internally.
    result["current_step"] = "completed" if result["current_step"] == "COMPLETE" else "failed"
    result["approval_status"] = "pending_engineer_review"
    return result
