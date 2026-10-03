"""Recoverable deterministic orchestration for the complete installation journey.

ASP.NET Core persists the returned state. The Python service never authorizes users,
approves proposals, or mutates inventory; it only validates events and selects the
next controlled stage.
"""

from copy import deepcopy
from datetime import datetime, timezone
from typing import Any
from uuid import uuid4

from app.shared.agents.planner_agent import PlannerAgent
from app.features.inventory.schemas.pricing_schemas import PricingRequest
from app.features.field_operations.schemas.compliance_schemas import ComplianceEvaluationInput
from app.features.field_operations.workflows.compliance_workflow import run_compliance_evaluation
from app.features.inventory.workflows.pricing_workflow import run_pricing_workflow
from app.features.engineering.workflows.proposal_workflow import run_guardrail_workflow
from app.features.assessment.workflows.solar_sizing import run_solar_sizing


def _set_step(state: dict[str, Any], step_id: str, status: str) -> None:
    for step in state.get("structured_plan", {}).get("steps", []):
        if step.get("step_id") == step_id:
            step["status"] = status


def _record_event(
    state: dict[str, Any], agent: str, step: str, summary: str,
    status: str = "completed", tool_name: str | None = None,
) -> None:
    now = datetime.now(timezone.utc).isoformat()
    event = {
        "trace_id": state.get("workflow_id", "workflow"),
        "span_id": uuid4().hex,
        "agent_name": agent,
        "step_name": step,
        "status": status,
        "started_at": now,
        "completed_at": now,
        "duration_ms": 0,
        "retry_count": int(state.get("retry_count", 0)),
        "output_summary": summary,
    }
    if tool_name:
        event["tool_name"] = tool_name
    state.setdefault("execution_logs", []).append(event)


def _safe_failure(state: dict[str, Any], message: str, step_id: str | None = None) -> dict[str, Any]:
    failed = deepcopy(state)
    if step_id:
        _set_step(failed, step_id, "FAILED")
        failed.setdefault("failed_steps", []).append(step_id)
    failed.update(workflow_status="FAILED", current_step_id=step_id or "planning", final_outcome="Workflow stopped safely.")
    failed.setdefault("errors", []).append({"step_id": step_id or "planning", "message": message})
    return failed


def start_master_workflow(payload: dict[str, Any]) -> dict[str, Any]:
    workflow_id = str(payload.get("workflow_id") or f"wf-{uuid4().hex[:12]}")
    objective = str(payload.get("objective") or "")
    base: dict[str, Any] = {
        "workflow_id": workflow_id,
        "customer_id": payload.get("customer_id"),
        "objective": objective,
        "input_data": dict(payload.get("input_data") or {}),
        "workflow_status": "PLANNING",
        "current_step_id": "planning",
        "completed_steps": [],
        "failed_steps": [],
        "agent_outputs": {},
        "tool_results": {},
        "validation_results": {},
        "errors": [],
        "approval_status": "NOT_REQUESTED",
        "retry_count": 0,
        "execution_logs": [],
        "final_outcome": "",
    }
    try:
        planned = PlannerAgent().execute(base)
        base.update(planned)
        base["completed_steps"] = ["planning"]
        base["current_step_id"] = base["structured_plan"]["steps"][0]["step_id"]
    except Exception:
        return _safe_failure(base, "The objective is unsupported or invalid.", "planning")

    if base["current_step_id"] != "solar-sizing":
        base["workflow_status"] = "WAITING_FOR_INSPECTION" if base["current_step_id"] == "site-inspection" else "WAITING_FOR_PRICING_INPUT"
        return base

    _set_step(base, "solar-sizing", "RUNNING")
    sizing = run_solar_sizing({
        "workflow_id": workflow_id,
        "objective": objective,
        "customer_id": payload.get("customer_id") or "",
        **base["input_data"],
    })
    base["execution_logs"].extend(sizing.execution_logs)
    base["validation_results"]["solar-sizing"] = sizing.validation_results
    if sizing.status != "completed" or sizing.recommendation is None:
        return _safe_failure(base, "Solar sizing failed deterministic validation.", "solar-sizing")
    _set_step(base, "solar-sizing", "COMPLETED")
    _set_step(base, "site-inspection", "READY")
    base["agent_outputs"]["solar-sizing"] = sizing.recommendation.model_dump(mode="json")
    base["completed_steps"].append("solar-sizing")
    base.update(workflow_status="WAITING_FOR_INSPECTION", current_step_id="site-inspection", final_outcome="Preliminary sizing completed; site inspection is required.")
    return base


def resume_master_workflow(state: dict[str, Any], event: str, event_data: dict[str, Any] | None = None) -> dict[str, Any]:
    current = deepcopy(state)
    data = dict(event_data or {})
    event = event.strip().upper()

    if event == "INSPECTION_COMPLETED":
        if current.get("workflow_status") not in {"WAITING_FOR_INSPECTION", "WAITING_FOR_CORRECTION"}:
            return _safe_failure(current, "Inspection cannot be applied in the current workflow state.", current.get("current_step_id"))
        _set_step(current, "site-inspection", "COMPLETED")
        _set_step(current, "grid-compliance", "RUNNING")
        current.setdefault("completed_steps", []).append("site-inspection")
        allowed_compliance_fields = set(ComplianceEvaluationInput.model_fields)
        compliance_payload = {
            key: value for key, value in {"workflow_id": current["workflow_id"], **data}.items()
            if key in allowed_compliance_fields
        }
        try:
            compliance = run_compliance_evaluation(compliance_payload)
        except Exception:
            current["retry_count"] = int(current.get("retry_count", 0)) + 1
            _set_step(current, "grid-compliance", "FAILED")
            _set_step(current, "site-inspection", "READY")
            current.update(workflow_status="WAITING_FOR_CORRECTION", current_step_id="site-inspection", final_outcome="Inspection evidence was incomplete or invalid; corrected evidence is required.")
            current.setdefault("errors", []).append({"step_id": "grid-compliance", "message": "Compliance input validation failed."})
            return current
        current["execution_logs"].extend(compliance.execution_logs)
        current["agent_outputs"]["grid-compliance"] = compliance.model_dump(mode="json")
        current["validation_results"]["grid-compliance"] = {"status": compliance.validation_status, "valid": compliance.validation_status == "PASSED"}
        if not compliance.grid_compliant or compliance.validation_status != "PASSED":
            current["retry_count"] = int(current.get("retry_count", 0)) + 1
            _set_step(current, "grid-compliance", "FAILED")
            _set_step(current, "site-inspection", "READY")
            current.setdefault("errors", []).append({
                "step_id": "grid-compliance",
                "message": "Compliance evidence did not pass deterministic validation.",
            })
            current.update(workflow_status="WAITING_FOR_CORRECTION", current_step_id="site-inspection", final_outcome="Compliance findings require corrected inspection evidence.")
            return current

        _set_step(current, "grid-compliance", "COMPLETED")
        current["completed_steps"].append("grid-compliance")
        sizing = current.get("agent_outputs", {}).get("solar-sizing", {})
        guardrail_payload = {
            "workflow_id": current["workflow_id"],
            "proposal_id": data.get("proposal_id"),
            "recommended_kw": data.get("recommended_kw", sizing.get("recommended_kw")),
            "panel_count": data.get("panel_count", sizing.get("estimated_panel_count")),
            "inverter_size_kw": data.get("inverter_size_kw", sizing.get("estimated_inverter_kw")),
            "estimated_cost_lkr": data.get("estimated_cost_lkr", 1),
            "grid_compliance_status": compliance.compliance_status,
            "risk_level": compliance.risk_level,
            "grid_type": data.get("grid_type", current.get("input_data", {}).get("grid_type", "SinglePhase")),
            "monthly_kwh": current.get("input_data", {}).get("monthly_kwh", 0),
            "roof_area_sqm": current.get("input_data", {}).get("roof_area_sqm", 0),
            "safety_notes": data.get("safety_notes"),
            "compliance_notes": compliance.notes,
        }
        try:
            _set_step(current, "safety-review", "RUNNING")
            safety = run_guardrail_workflow(guardrail_payload)
        except Exception:
            return _safe_failure(current, "Safety review could not produce a validated result.", "safety-review")
        current["execution_logs"].extend(safety.execution_logs)
        current["agent_outputs"]["safety-review"] = safety.model_dump(mode="json")
        current["validation_results"]["safety-review"] = {"valid": safety.safety_status != "BLOCKED", "requires_approval": safety.requires_approval}
        if safety.safety_status == "BLOCKED":
            current["retry_count"] = int(current.get("retry_count", 0)) + 1
            _set_step(current, "safety-review", "FAILED")
            _set_step(current, "site-inspection", "READY")
            current.update(workflow_status="WAITING_FOR_CORRECTION", current_step_id="site-inspection", approval_status="NOT_REQUESTED", final_outcome="Safety validation blocked the proposal; corrected evidence is required.")
            return current
        _set_step(current, "safety-review", "COMPLETED")
        _set_step(current, "engineer-approval", "PAUSED")
        current["completed_steps"].append("safety-review")
        current.update(workflow_status="WAITING_FOR_APPROVAL", current_step_id="engineer-approval", approval_status="PENDING", final_outcome="Validated proposal is waiting for an authorized engineering decision.")
        return current

    if event in {"ENGINEER_APPROVED", "ENGINEER_REJECTED", "REVISION_REQUESTED"}:
        if current.get("workflow_status") != "WAITING_FOR_APPROVAL":
            return _safe_failure(current, "Engineering decision cannot be applied in the current workflow state.", current.get("current_step_id"))
        if event == "ENGINEER_APPROVED":
            _set_step(current, "engineer-approval", "COMPLETED")
            _set_step(current, "equipment-pricing", "READY")
            current.setdefault("completed_steps", []).append("engineer-approval")
            current.update(workflow_status="WAITING_FOR_PRICING_INPUT", current_step_id="equipment-pricing", approval_status="APPROVED", final_outcome="Engineer approved; validated catalog input is required for pricing.")
            _record_event(current, "SeniorEngineer", "engineer-approval", "Authorized engineering approval recorded.")
        elif event == "REVISION_REQUESTED":
            _set_step(current, "engineer-approval", "PAUSED")
            _set_step(current, "site-inspection", "READY")
            current.update(workflow_status="WAITING_FOR_CORRECTION", current_step_id="site-inspection", approval_status="REVISION_REQUESTED", final_outcome="Engineer requested corrected evidence or proposal details.")
            _record_event(current, "SeniorEngineer", "revision-requested", "Authorized engineering revision request recorded.")
        else:
            _set_step(current, "engineer-approval", "COMPLETED")
            current.update(workflow_status="COMPLETED", current_step_id="completed", approval_status="REJECTED", final_outcome="Proposal was rejected by the authorized engineer.")
            _record_event(current, "SeniorEngineer", "engineer-rejection", "Authorized engineering rejection recorded.")
        return current

    if event == "PRICING_REQUESTED":
        if current.get("workflow_status") != "WAITING_FOR_PRICING_INPUT" or current.get("approval_status") != "APPROVED":
            return _safe_failure(current, "Pricing requires an approved proposal and validated catalog input.", current.get("current_step_id"))
        try:
            _set_step(current, "equipment-pricing", "RUNNING")
            pricing = run_pricing_workflow(PricingRequest.model_validate(data))
        except Exception:
            return _safe_failure(current, "Equipment pricing failed; no quote or reservation was created.", "equipment-pricing")
        current["agent_outputs"]["equipment-pricing"] = pricing.model_dump(mode="json")
        current["tool_results"]["ExchangeRateTool"] = {"status": "VALIDATED", "timestamp": pricing.rateTimestamp.isoformat()}
        _record_event(current, "EquipmentPricingAgent", "equipment-pricing", "Equipment requirements, exchange rate, catalog arithmetic, and availability snapshot were validated.", tool_name="ExchangeRateTool")
        _set_step(current, "equipment-pricing", "COMPLETED")
        _set_step(current, "inventory-reservation", "READY")
        current["completed_steps"].append("equipment-pricing")
        current.update(workflow_status="WAITING_FOR_INVENTORY", current_step_id="inventory-reservation", final_outcome="Validated quote is waiting for inventory review.")
        return current

    if event == "INVENTORY_RESERVED":
        if current.get("workflow_status") != "WAITING_FOR_INVENTORY":
            return _safe_failure(current, "Inventory reservation cannot be applied in the current workflow state.", current.get("current_step_id"))
        _set_step(current, "inventory-reservation", "COMPLETED")
        _set_step(current, "homeowner-update", "COMPLETED")
        current.setdefault("completed_steps", []).extend(["inventory-reservation", "homeowner-update"])
        current.update(workflow_status="COMPLETED", current_step_id="completed", final_outcome="Approved equipment was reserved and the project status is ready for the homeowner.")
        _record_event(current, "InventoryOfficer", "inventory-reservation", "Backend-confirmed inventory reservation recorded; homeowner status is ready.")
        return current

    return _safe_failure(current, "Unsupported workflow event.", current.get("current_step_id"))
