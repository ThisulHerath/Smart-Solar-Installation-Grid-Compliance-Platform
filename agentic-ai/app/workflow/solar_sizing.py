from typing import Any, Dict
from app.schemas.state import SolarSizingResponse, SolarSizingRecommendation
from app.workflow.graph import run_solar_sizing_workflow

def run_solar_sizing(payload: Dict[str, Any]) -> SolarSizingResponse:
    try:
        result = run_solar_sizing_workflow(payload)
        valid = result.get("current_step") == "COMPLETE"
        structured_plan = result.get("structured_plan", {})
        if valid:
            for step in structured_plan.get("steps", []):
                if step.get("step_id") == "solar-sizing":
                    step["status"] = "COMPLETED"
                elif step.get("step_id") == "site-inspection":
                    step["status"] = "READY"
        return SolarSizingResponse(
            workflow_id=result["workflow_id"],
            status="completed" if valid else "failed",
            plan=result.get("plan", []),
            structured_plan=structured_plan,
            current_step_id="site-inspection" if valid else "solar-sizing",
            workflow_status="WAITING_FOR_INSPECTION" if valid else "FAILED",
            recommendation=SolarSizingRecommendation.model_validate(result["final_result"]) if valid else None,
            validation_results=result.get("validation_results", {}),
            errors=result.get("errors", []),
            execution_logs=result.get("execution_logs", []),
        )
    except Exception:
        return SolarSizingResponse(workflow_id=str(payload.get("workflow_id", "")), status="failed", workflow_status="FAILED", errors=["Solar sizing workflow could not be completed."])
