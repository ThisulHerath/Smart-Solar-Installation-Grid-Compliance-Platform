from typing import Dict, Any, List

class DeterministicComplianceValidator:
    """
    Independent deterministic validation engine for grid compliance findings.
    Ensures:
    - Compliance status is not marked COMPLIANT if violations exist.
    - Non-compliant status is enforced when critical thresholds are breached.
    - Risk level aligns with count and severity of violations.
    - Structural integrity of compliance response payload.
    """
    def __init__(self, name: str = "DeterministicComplianceValidator"):
        self.name = name

    def validate(self, candidate: Dict[str, Any], raw_inputs: Dict[str, Any]) -> Dict[str, Any]:
        checks: Dict[str, bool] = {}
        violations: List[str] = candidate.get("violations", [])
        is_compliant: bool = candidate.get("grid_compliant", False)
        status: str = candidate.get("compliance_status", "")
        risk: str = candidate.get("risk_level", "")

        # 1. Zero violation rule: If compliant, violations MUST be 0
        checks["zero_violations_if_compliant"] = (not is_compliant) or (len(violations) == 0)

        # 2. Status consistency
        if is_compliant:
            checks["status_consistent"] = status == "COMPLIANT"
            checks["risk_level_consistent"] = risk == "LOW"
        else:
            checks["status_consistent"] = status in ("NON_COMPLIANT", "CONDITIONAL")
            checks["risk_level_consistent"] = risk in ("MEDIUM", "HIGH", "CRITICAL")

        # 3. Critical threshold checks against raw inputs
        grid_voltage = raw_inputs.get("grid_voltage")
        if grid_voltage is not None:
            grid_type = str(raw_inputs.get("grid_type", "SinglePhase")).lower()
            nom = 400.0 if "three" in grid_type or "3" in grid_type else 230.0
            if (grid_voltage < nom * 0.94 or grid_voltage > nom * 1.06) and is_compliant:
                checks["voltage_bounds_enforced"] = False
            else:
                checks["voltage_bounds_enforced"] = True

        inverter_suitable = raw_inputs.get("inverter_location_suitable")
        if inverter_suitable is False and is_compliant:
            checks["inverter_suitability_enforced"] = False
        else:
            checks["inverter_suitability_enforced"] = True

        # 4. Schema completeness
        required_keys = ["grid_compliant", "compliance_status", "risk_level", "violations", "recommendations"]
        checks["schema_complete"] = all(k in candidate for k in required_keys)

        valid = all(checks.values())
        return {
            "valid": valid,
            "checks": checks,
            "validation_status": "PASSED" if valid else "FAILED_DETERMINISTIC_CHECK"
        }
