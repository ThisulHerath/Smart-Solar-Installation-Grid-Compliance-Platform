from app.shared.agents.planner_agent import PlannerAgent
from app.shared.tools.tool_registry import authorize_tool
from app.shared.orchestration.master_workflow import start_master_workflow, resume_master_workflow
import pytest


def valid_start():
    return start_master_workflow({
        "workflow_id": "wf-master-test",
        "objective": "Prepare an approved rooftop solar installation plan",
        "customer_id": "customer-1",
        "input_data": {
            "monthly_kwh": 600,
            "roof_area_sqm": 80,
            "grid_type": "SinglePhase",
        },
    })


def test_planner_creates_typed_objective_sensitive_plan():
    full = PlannerAgent().execute({"objective": "Plan a rooftop solar installation"})
    pricing = PlannerAgent().execute({"objective": "Calculate equipment pricing quote"})

    assert full["workflow_type"] == "FULL_INSTALLATION"
    assert len(full["structured_plan"]["steps"]) == 8
    assert pricing["workflow_type"] == "EQUIPMENT_PRICING"
    assert [step["step_id"] for step in pricing["structured_plan"]["steps"]] == [
        "equipment-pricing", "inventory-reservation", "homeowner-update"
    ]
    assert pricing["structured_plan"]["steps"][0]["allowed_tools"] == ["ExchangeRateTool"]


def test_unsupported_objective_fails_closed():
    result = start_master_workflow({"objective": "Delete every user", "input_data": {}})
    assert result["workflow_status"] == "FAILED"
    assert result["current_step_id"] == "planning"
    assert result["errors"]


def test_start_runs_sizing_and_pauses_for_real_inspection():
    result = valid_start()
    assert result["workflow_status"] == "WAITING_FOR_INSPECTION"
    assert result["current_step_id"] == "site-inspection"
    assert result["agent_outputs"]["solar-sizing"]["recommended_kw"] == 5.0
    assert result["validation_results"]["solar-sizing"]["valid"]


def test_valid_inspection_runs_compliance_and_safety_then_pauses_for_human():
    result = resume_master_workflow(valid_start(), "INSPECTION_COMPLETED", {
        "grid_type": "SinglePhase",
        "grid_voltage": 230,
        "grid_frequency": 50,
        "main_breaker_rating": 63,
        "inverter_location_suitable": True,
        "estimated_cost_lkr": 1_700_000,
    })
    assert result["workflow_status"] == "WAITING_FOR_APPROVAL"
    assert result["current_step_id"] == "engineer-approval"
    assert result["approval_status"] == "PENDING"
    assert "grid-compliance" in result["completed_steps"]
    assert "safety-review" in result["completed_steps"]

    approved = resume_master_workflow(result, "ENGINEER_APPROVED")
    assert approved["workflow_status"] == "WAITING_FOR_PRICING_INPUT"
    assert approved["approval_status"] == "APPROVED"


def test_non_compliant_inspection_waits_for_correction():
    result = resume_master_workflow(valid_start(), "INSPECTION_COMPLETED", {
        "grid_type": "SinglePhase",
        "grid_voltage": 290,
        "grid_frequency": 50,
        "main_breaker_rating": 63,
        "inverter_location_suitable": True,
    })
    assert result["workflow_status"] == "WAITING_FOR_CORRECTION"
    assert result["current_step_id"] == "site-inspection"
    assert result["retry_count"] == 1


def test_incomplete_inspection_fails_closed_and_can_be_corrected():
    result = resume_master_workflow(valid_start(), "INSPECTION_COMPLETED", {
        "grid_type": "SinglePhase",
        "grid_voltage": 230,
    })
    assert result["workflow_status"] == "WAITING_FOR_CORRECTION"
    assert result["current_step_id"] == "site-inspection"
    assert result["retry_count"] == 1
    assert result["errors"][-1]["step_id"] == "grid-compliance"


def test_master_workflow_logs_are_structured_for_backend_persistence():
    result = valid_start()
    assert result["execution_logs"]
    assert all(isinstance(log, dict) for log in result["execution_logs"])
    assert all(log.get("trace_id") == "wf-master-test" for log in result["execution_logs"])


def test_tool_registry_denies_cross_agent_tool_use():
    authorize_tool("GridComplianceAgent", "ProjectKnowledgeTool")
    with pytest.raises(PermissionError):
        authorize_tool("SolarSizingAgent", "ExchangeRateTool")
