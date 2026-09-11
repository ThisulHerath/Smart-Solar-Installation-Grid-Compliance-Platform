import unittest
import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.workflow.proposal_workflow import run_guardrail_workflow
from app.agents.proposal_validator import DeterministicProposalValidator

class TestProposalWorkflow(unittest.TestCase):
    def setUp(self):
        self.validator = DeterministicProposalValidator()

    def test_high_capacity_requires_approval(self):
        """Proposals with recommended kW > 10.0 kW automatically require human approval."""
        payload = {
            "recommended_kw": 12.5,
            "panel_count": 30,
            "inverter_size_kw": 12.5,
            "grid_compliance_status": "COMPLIANT",
            "compliance_notes": "Grid parameters within bounds",
            "risk_level": "MEDIUM",
            "estimated_cost_lkr": 1400000.0
        }

        res = run_guardrail_workflow(payload)

        self.assertTrue(res.requires_approval)
        self.assertEqual(res.safety_status, "REQUIRES_APPROVAL")
        self.assertTrue(any("10.0" in issue for issue in res.issues))

    def test_non_compliant_grid_requires_approval(self):
        """Proposals with NON_COMPLIANT grid status require senior engineer review."""
        payload = {
            "recommended_kw": 6.0,
            "panel_count": 15,
            "inverter_size_kw": 6.0,
            "grid_compliance_status": "NON_COMPLIANT",
            "compliance_notes": "Voltage exceeds ceiling",
            "risk_level": "HIGH",
            "estimated_cost_lkr": 700000.0
        }

        res = run_guardrail_workflow(payload)

        self.assertTrue(res.requires_approval)
        self.assertEqual(res.safety_status, "REQUIRES_APPROVAL")
        self.assertTrue(any("NON_COMPLIANT" in issue for issue in res.issues))

    def test_low_risk_small_capacity_safe(self):
        """Proposals with kW <= 10.0 and COMPLIANT status are marked SAFE."""
        payload = {
            "recommended_kw": 5.0,
            "panel_count": 12,
            "inverter_size_kw": 5.0,
            "grid_compliance_status": "COMPLIANT",
            "compliance_notes": "All checks passed",
            "risk_level": "LOW",
            "estimated_cost_lkr": 600000.0
        }

        res = run_guardrail_workflow(payload)

        self.assertFalse(res.requires_approval)
        self.assertEqual(res.safety_status, "SAFE")

    def test_validator_overrides_ai_bypass_attempt(self):
        """If AI mistakenly evaluates requires_approval=False for a 15kW system, deterministic validator forces requires_approval=True."""
        validated = self.validator.validate(
            recommended_kw=15.0,
            panel_count=36,
            inverter_size_kw=15.0,
            estimated_cost_lkr=1800000.0,
            grid_compliance_status="COMPLIANT",
            ai_says_requires_approval=False
        )

        self.assertTrue(validated["requires_approval"])
        self.assertTrue(len(validated["override_reason"]) > 0)

if __name__ == '__main__':
    unittest.main()
