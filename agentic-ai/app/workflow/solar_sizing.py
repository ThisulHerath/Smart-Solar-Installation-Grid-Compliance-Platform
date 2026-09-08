from typing import Any, Dict
from app.agents.solar_sizing_agent import SolarSizingAgent
from app.schemas.state import SolarSizingInput, SolarSizingResponse

agent = SolarSizingAgent()

def run_solar_sizing(payload: Dict[str, Any]) -> SolarSizingResponse:
    try:
        survey = SolarSizingInput.model_validate(payload)
        recommendation = agent.execute(survey)
        expected_kw = round(survey.monthly_kwh / 120.0, 2)
        expected_panels = max(1, round(expected_kw * 1000 / 400))
        checks = {
            "monthly_kwh_valid": survey.monthly_kwh > 0,
            "roof_area_valid": survey.roof_area_sqm > 0,
            "recommended_kw_consistent": recommendation.recommended_kw == expected_kw,
            "panel_count_reasonable": recommendation.estimated_panel_count == expected_panels,
            "inverter_size_consistent": recommendation.estimated_inverter_kw == expected_kw,
            "schema_valid": True,
        }
        valid = all(checks.values())
        return SolarSizingResponse(
            workflow_id=survey.workflow_id,
            status="completed" if valid else "failed",
            recommendation=recommendation if valid else None,
            validation_results={"valid": valid, "checks": checks},
            errors=[] if valid else ["Deterministic solar sizing validation failed."],
        )
    except Exception as exc:
        return SolarSizingResponse(workflow_id=str(payload.get("workflow_id", "")), status="failed", errors=[str(exc)])
