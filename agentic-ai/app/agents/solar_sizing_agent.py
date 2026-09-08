from typing import Any, Dict
from app.schemas.state import SolarSizingInput, SolarSizingRecommendation

class SolarSizingAgent:
    """Produces a preliminary recommendation; the validator remains authoritative."""
    def execute(self, survey: SolarSizingInput) -> SolarSizingRecommendation:
        recommended_kw = round(survey.monthly_kwh / 120.0, 2)
        panel_count = max(1, round(recommended_kw * 1000 / 400))
        inverter_kw = round(recommended_kw, 2)
        return SolarSizingRecommendation(
            recommended_kw=recommended_kw,
            reason=f"Monthly consumption of {survey.monthly_kwh} kWh maps to the project sizing rule.",
            estimated_panel_count=panel_count,
            estimated_inverter_kw=inverter_kw,
            assumptions=["400 W panels", "Inverter size follows recommended system size"]
        )
