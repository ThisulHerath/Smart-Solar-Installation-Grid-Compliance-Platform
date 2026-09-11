from typing import Any, Dict
from app.schemas.state import SolarSizingResponse, SolarSizingRecommendation
from app.workflow.graph import run_solar_sizing_workflow

def run_solar_sizing(payload: Dict[str, Any]) -> SolarSizingResponse:
    try:
        result = run_solar_sizing_workflow(payload)
        valid = result.get("current_step") == "COMPLETE"
        return SolarSizingResponse(
            workflow_id=result["workflow_id"],
            status="completed" if valid else "failed",
            plan=result.get("plan", []),
            recommendation=SolarSizingRecommendation.model_validate(result["final_result"]) if valid else None,
            validation_results=result.get("validation_results", {}),
            errors=result.get("errors", []),
            execution_logs=result.get("execution_logs", []),
        )
    except Exception:
        return SolarSizingResponse(workflow_id=str(payload.get("workflow_id", "")), status="failed", errors=["Solar sizing workflow could not be completed."])
