import unittest
import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.schemas.compliance_schemas import ComplianceEvaluationInput
from app.agents.grid_compliance_agent import GridComplianceAgent
from app.agents.compliance_validator import DeterministicComplianceValidator
from app.workflow.compliance_workflow import run_compliance_evaluation

class TestComplianceWorkflow(unittest.TestCase):
    def setUp(self):
        self.agent = GridComplianceAgent()
        self.validator = DeterministicComplianceValidator()

    def test_golden_case_1_ideal_single_phase_compliant(self):
        """Golden Case 1: Ideal 230V single-phase grid installation complies with all parameters."""
        payload = {
            "inspection_id": "00000000-0000-0000-0000-000000000001",
            "field_job_id": "11111111-1111-1111-1111-111111111111",
            "grid_type": "SinglePhase",
            "phase_count": 1,
            "main_breaker_rating": 40.0,
            "inverter_location_suitable": True,
            "roof_area_sqm": 60.0,
            "roof_tilt": 12.0,
            "roof_orientation": "South",
            "grid_voltage": 230.0,
            "grid_frequency": 50.0,
            "voc": 450.0,
            "isc": 11.5,
            "vmp": 380.0,
            "imp": 10.2
        }

        res = run_compliance_evaluation(payload)

        self.assertTrue(res.grid_compliant)
        self.assertEqual(res.compliance_status, "COMPLIANT")
        self.assertEqual(res.risk_level, "LOW")
        self.assertEqual(len(res.violations), 0)
        self.assertEqual(res.validation_status, "PASSED")
        self.assertGreater(len(res.execution_logs), 0)

    def test_golden_case_2_over_voltage_violation(self):
        """Golden Case 2: Grid voltage 258V exceeds +6% ceiling (243.8V) for 230V nominal."""
        payload = {
            "grid_type": "SinglePhase",
            "grid_voltage": 258.0,
            "grid_frequency": 50.0,
            "inverter_location_suitable": True,
            "main_breaker_rating": 40.0
        }

        res = run_compliance_evaluation(payload)

        self.assertFalse(res.grid_compliant)
        self.assertIn(res.compliance_status, ("NON_COMPLIANT", "CONDITIONAL"))
        self.assertTrue(any("voltage" in v.lower() for v in res.violations))
        self.assertEqual(res.validation_status, "PASSED")

    def test_golden_case_3_frequency_deviation_violation(self):
        """Golden Case 3: Frequency 48.8Hz violates standard 49.5Hz - 50.5Hz tolerance."""
        payload = {
            "grid_type": "SinglePhase",
            "grid_voltage": 230.0,
            "grid_frequency": 48.8,
            "inverter_location_suitable": True,
            "main_breaker_rating": 40.0
        }

        res = run_compliance_evaluation(payload)

        self.assertFalse(res.grid_compliant)
        self.assertTrue(any("frequency" in v.lower() for v in res.violations))

    def test_golden_case_4_unsuitable_inverter_location(self):
        """Golden Case 4: Inverter location unsuitable creates severe safety non-compliance."""
        payload = {
            "grid_type": "SinglePhase",
            "grid_voltage": 230.0,
            "grid_frequency": 50.0,
            "inverter_location_suitable": False,
            "main_breaker_rating": 40.0
        }

        res = run_compliance_evaluation(payload)

        self.assertFalse(res.grid_compliant)
        self.assertEqual(res.compliance_status, "NON_COMPLIANT")
        self.assertTrue(any("inverter" in v.lower() or "location" in v.lower() for v in res.violations))

    def test_golden_case_5_underrated_main_breaker(self):
        """Golden Case 5: 20A main breaker is below minimum 30A threshold for solar interconnect."""
        payload = {
            "grid_type": "SinglePhase",
            "grid_voltage": 230.0,
            "grid_frequency": 50.0,
            "inverter_location_suitable": True,
            "main_breaker_rating": 20.0
        }

        res = run_compliance_evaluation(payload)

        self.assertFalse(res.grid_compliant)
        self.assertTrue(any("breaker" in v.lower() for v in res.violations))

    def test_deterministic_validator_catches_false_compliant(self):
        """Ensures validator rejects a candidate marked compliant when voltage violation exists."""
        fake_candidate = {
            "grid_compliant": True,
            "compliance_status": "COMPLIANT",
            "risk_level": "LOW",
            "violations": [],
            "recommendations": []
        }
        raw_inputs = {
            "grid_voltage": 260.0,  # clearly out of range
            "grid_type": "SinglePhase"
        }

        val = self.validator.validate(fake_candidate, raw_inputs)
        self.assertFalse(val["valid"])
        self.assertEqual(val["validation_status"], "FAILED_DETERMINISTIC_CHECK")

if __name__ == '__main__':
    unittest.main()
