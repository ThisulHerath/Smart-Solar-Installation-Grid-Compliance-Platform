from datetime import datetime, timezone
from typing import Dict, Any, List
from uuid import uuid4

from app.schemas.plan_schemas import PlanStep, WorkflowPlan
from app.tools.tool_registry import permitted_tools

class PlannerAgent:
    """
    Builds an objective-sensitive, typed plan using reviewed domain rules.
    This is deterministic coordination, not language-model reasoning.
    """
    def __init__(self, name: str = "PlannerAgent"):
        self.name = name

    def execute(self, state: Dict[str, Any]) -> Dict[str, Any]:
        objective = str(state.get("objective") or "").strip()
        logs = list(state.get("execution_logs", []))
        completed: List[str] = list(state.get("completed_steps", []))

        if len(objective) < 3 or len(objective) > 500:
            raise ValueError("Objective must contain between 3 and 500 characters.")

        normalized = objective.casefold()
        if any(term in normalized for term in ("price", "pricing", "quote", "equipment cost")):
            workflow_type = "EQUIPMENT_PRICING"
            selected = {"equipment-pricing", "inventory-reservation", "homeowner-update"}
        elif any(term in normalized for term in ("compliance", "inspection", "grid", "safety review")):
            workflow_type = "COMPLIANCE_REVIEW"
            selected = {"site-inspection", "grid-compliance", "safety-review", "engineer-approval", "homeowner-update"}
        elif any(term in normalized for term in ("solar", "roof", "rooftop", "installation", "proposal", "assessment", "system")):
            workflow_type = "FULL_INSTALLATION"
            selected = {
                "solar-sizing", "site-inspection", "grid-compliance", "safety-review",
                "engineer-approval", "equipment-pricing", "inventory-reservation", "homeowner-update",
            }
        else:
            raise ValueError("Unsupported objective. Use a solar assessment, compliance review, or equipment pricing objective.")

        catalogue = [
            PlanStep(step_id="solar-sizing", title="Calculate and validate preliminary solar capacity", agent_name="SolarSizingAgent", required_inputs=["monthly_kwh", "roof_area_sqm", "grid_type"]),
            PlanStep(step_id="site-inspection", title="Collect physical inspection measurements and evidence", agent_name="FieldTechnician", depends_on=["solar-sizing"], required_inputs=["grid_voltage", "grid_frequency", "main_breaker_rating", "inverter_location_suitable"], high_impact=True),
            PlanStep(step_id="grid-compliance", title="Screen measurements against reviewed project guidance", agent_name="GridComplianceAgent", depends_on=["site-inspection"], required_inputs=["grid_voltage", "grid_frequency", "main_breaker_rating", "inverter_location_suitable"], allowed_tools=permitted_tools("GridComplianceAgent")),
            PlanStep(step_id="safety-review", title="Evaluate proposal safety and escalation signals", agent_name="SafetyGuardrailAgent", depends_on=["grid-compliance"], required_inputs=["recommended_kw", "grid_compliance_status", "risk_level"], allowed_tools=permitted_tools("SafetyGuardrailAgent")),
            PlanStep(step_id="engineer-approval", title="Pause for an authorized engineering decision", agent_name="SeniorEngineer", depends_on=["safety-review"], required_inputs=["approval_decision"], high_impact=True),
            PlanStep(step_id="equipment-pricing", title="Build and independently validate the equipment estimate", agent_name="EquipmentPricingAgent", depends_on=["engineer-approval"], required_inputs=["approved_proposal", "catalog_items"], allowed_tools=permitted_tools("EquipmentPricingAgent")),
            PlanStep(step_id="inventory-reservation", title="Recheck and reserve stock transactionally", agent_name="InventoryOfficer", depends_on=["equipment-pricing"], required_inputs=["validated_quote"], high_impact=True),
            PlanStep(step_id="homeowner-update", title="Publish the final project status through the shared API", agent_name="HomeownerNotification", depends_on=["inventory-reservation"]),
        ]
        steps = [step for step in catalogue if step.step_id in selected]
        selected_ids = {step.step_id for step in steps}
        for step in steps:
            step.depends_on = [dependency for dependency in step.depends_on if dependency in selected_ids]
        steps[0].status = "READY"
        structured_plan = WorkflowPlan(objective=objective, workflow_type=workflow_type, steps=steps)
        plan = [f"{index}. {step.agent_name}: {step.title}" for index, step in enumerate(steps, start=1)]

        now = datetime.now(timezone.utc).isoformat()
        logs.append({
            "trace_id": str(state.get("workflow_id") or "planning"),
            "span_id": uuid4().hex,
            "agent_name": self.name,
            "step_name": "objective_planning",
            "status": "completed",
            "started_at": now,
            "completed_at": now,
            "duration_ms": 0,
            "retry_count": 0,
            "output_summary": f"Created {workflow_type} plan with {len(steps)} controlled steps.",
        })

        completed.append("planning")

        return {
            "plan": plan,
            "structured_plan": structured_plan.model_dump(),
            "workflow_type": workflow_type,
            "current_step": "planning_completed",
            "completed_steps": completed,
            "execution_logs": logs
        }
