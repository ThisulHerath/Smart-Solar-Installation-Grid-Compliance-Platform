from typing import Dict, Any, List
from app.schemas.compliance_schemas import ComplianceEvaluationInput

class GridComplianceAgent:
    """
    Screens measurements using documented university-project thresholds.
    These rules do not certify compliance with utility or installation standards.
    Evaluates:
    - Grid voltage tolerance (230V +/- 6% for single-phase, 400V +/- 6% for three-phase)
    - Grid frequency tolerance (50Hz +/- 1%)
    - Main breaker sizing
    - Inverter location & thermal suitability
    - PV string voltages (Voc, Vmp) and currents (Isc, Imp)
    """
    def __init__(self, name: str = "GridComplianceAgent"):
        self.name = name

    def execute(self, state: Dict[str, Any]) -> Dict[str, Any]:
        logs: List[str] = state.get("execution_logs", [])
        tool_results: Dict[str, Any] = state.get("tool_results", {})
        completed: List[str] = state.get("completed_steps", [])

        logs.append(f"[{self.name}] Inspection inputs required before compliance screening.")
        grid_eval = {
            "compliance_status": "INPUT_REQUIRED",
            "anti_islanding_certified": None
        }
        tool_results["grid_compliance"] = grid_eval

        return {
            "tool_results": tool_results,
            "completed_steps": completed,
            "execution_logs": logs
        }

    def evaluate(self, data: ComplianceEvaluationInput) -> Dict[str, Any]:
        violations: List[str] = []
        recommendations: List[str] = []

        for field in ('grid_voltage', 'grid_frequency', 'main_breaker_rating', 'inverter_location_suitable'):
            if getattr(data, field) is None:
                violations.append(f"Missing {field}: complete the inspection before a compliant assessment.")

        is_three_phase = data.grid_type.lower() in ("threephase", "three_phase", "3phase")

        # 1. Voltage Check
        if data.grid_voltage is not None:
            nominal_v = 400.0 if is_three_phase else 230.0
            min_v = nominal_v * 0.94  # -6%
            max_v = nominal_v * 1.06  # +6%
            if data.grid_voltage < min_v or data.grid_voltage > max_v:
                violations.append(
                    f"Grid voltage {data.grid_voltage}V is outside the project screening range ({min_v:.1f}V - {max_v:.1f}V) for {data.grid_type}."
                )
                recommendations.append("Request a qualified engineer and utility review of the voltage readings.")
            else:
                recommendations.append(f"Grid voltage {data.grid_voltage}V passes the project screening threshold.")

        # 2. Frequency Check
        if data.grid_frequency is not None:
            if data.grid_frequency < 49.5 or data.grid_frequency > 50.5:
                violations.append(
                    f"Grid frequency {data.grid_frequency}Hz falls outside the project screening limits (49.5Hz - 50.5Hz)."
                )
                recommendations.append("Ask the engineer to verify protection settings against the applicable utility agreement and equipment certification.")
            else:
                recommendations.append(f"Grid frequency {data.grid_frequency}Hz is within synchronous operating tolerances.")

        # 3. Inverter Location Suitability
        if data.inverter_location_suitable is False:
            violations.append("Proposed inverter installation location is deemed unsuitable (insufficient ventilation, direct weather exposure, or fire risk).")
            recommendations.append("Have the engineer assess a suitable location using the manufacturer's installation instructions.")

        # 4. Main Breaker Rating
        if data.main_breaker_rating is not None:
            if data.main_breaker_rating < 30.0:
                violations.append(f"Main service breaker rating ({data.main_breaker_rating}A) is insufficient for solar export backfeed.")
                recommendations.append("Have a qualified engineer review breaker sizing; the app does not specify an upgrade.")
            elif data.main_breaker_rating > 200.0 and not is_three_phase:
                recommendations.append("Consider upgrading connection to three-phase for large service ratings exceeding 63A.")

        # 5. PV String DC Telemetry
        if data.voc is not None and data.voc <= 0:
            violations.append("Measured open-circuit voltage (Voc) is invalid (<= 0V).")
        if data.isc is not None and data.isc <= 0:
            violations.append("Measured short-circuit current (Isc) is invalid (<= 0A).")

        # Determine compliance and risk
        is_compliant = len(violations) == 0
        if is_compliant:
            status = "COMPLIANT"
            risk = "LOW"
        elif len(violations) == 1 and not (data.inverter_location_suitable is False or (data.grid_voltage and (data.grid_voltage < 200 or data.grid_voltage > 270))):
            status = "CONDITIONAL"
            risk = "MEDIUM"
        else:
            status = "NON_COMPLIANT"
            risk = "HIGH" if len(violations) <= 2 else "CRITICAL"

        return {
            "grid_compliant": is_compliant,
            "compliance_status": status,
            "risk_level": risk,
            "violations": violations,
            "recommendations": recommendations,
            "notes": "Preliminary screening using documented project rules. Utility approval, certified protection settings, and installation design require separate professional review."
        }
