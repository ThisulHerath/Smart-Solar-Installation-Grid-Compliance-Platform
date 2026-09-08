import unittest
import sys
import os

# Ensure app is in path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.workflow.graph import run_solar_workflow
from app.agents.planner_agent import PlannerAgent
from app.agents.grid_compliance_agent import GridComplianceAgent
from app.agents.equipment_pricing_agent import EquipmentPricingAgent
from app.agents.safety_guardrail_agent import SafetyGuardrailAgent
from app.schemas.state import WorkflowExecutionRequest, WorkflowExecutionResponse
from app.workflow.solar_sizing import run_solar_sizing

class TestAgenticAI(unittest.TestCase):
    def test_planner_agent(self):
        agent = PlannerAgent()
        state = {"objective": "Install 5kW solar system", "execution_logs": [], "completed_steps": []}
        result = agent.execute(state)

        self.assertIn("plan", result)
        self.assertGreater(len(result["plan"]), 0)
        self.assertIn("planning", result["completed_steps"])

    def test_grid_compliance_agent(self):
        agent = GridComplianceAgent()
        state = {"execution_logs": [], "tool_results": {}, "completed_steps": []}
        result = agent.execute(state)

        self.assertIn("grid_compliance", result["tool_results"])
        self.assertEqual(result["tool_results"]["grid_compliance"]["compliance_status"], "COMPLIANT_PROVISIONAL")

    def test_equipment_pricing_agent(self):
        agent = EquipmentPricingAgent()
        state = {"execution_logs": [], "tool_results": {}, "completed_steps": []}
        result = agent.execute(state)

        self.assertIn("equipment_pricing", result["tool_results"])
        self.assertGreater(result["tool_results"]["equipment_pricing"]["estimated_hardware_cost_lkr"], 0)

    def test_safety_guardrail_agent(self):
        agent = SafetyGuardrailAgent()
        state = {"execution_logs": [], "validation_results": {}, "completed_steps": []}
        result = agent.execute(state)

        self.assertIn("safety_guardrails", result["validation_results"])
        self.assertTrue(result["validation_results"]["safety_guardrails"]["roof_setback_met"])

    def test_full_workflow_execution(self):
        result = run_solar_workflow(objective="Design 10kW residential solar array with CEB grid export")

        self.assertEqual(result["current_step"], "completed")
        self.assertEqual(result["approval_status"], "pending_engineer_review")
        self.assertTrue(result["validation_results"]["valid"])
        self.assertEqual(result["final_result"]["recommended_kw"], 10.0)
        self.assertEqual([log["agent_name"] for log in result["execution_logs"]], ["Planner", "SolarSizingAgent", "DeterministicValidator"])

    def test_pydantic_schema_validation(self):
        req = WorkflowExecutionRequest(objective="Test solar validation")
        self.assertEqual(req.objective, "Test solar validation")
        self.assertEqual(req.input_data, {})

        res = WorkflowExecutionResponse(objective=req.objective, plan=["Step 1"])
        self.assertEqual(res.objective, "Test solar validation")
        self.assertEqual(len(res.plan), 1)

    def test_solar_sizing_uses_deterministic_rule(self):
        result = run_solar_sizing({"workflow_id": "w1", "customer_id": "c1", "monthly_kwh": 1200, "roof_area_sqm": 80, "grid_type": "SinglePhase"})
        self.assertEqual(result.status, "completed")
        self.assertEqual(result.recommendation.recommended_kw, 10.0)
        self.assertTrue(result.validation_results["valid"])

    def test_solar_sizing_rejects_invalid_state(self):
        result = run_solar_sizing({"workflow_id": "w1", "customer_id": "c1", "monthly_kwh": -1, "roof_area_sqm": 80, "grid_type": "SinglePhase"})
        self.assertEqual(result.status, "failed")
        self.assertIsNotNone(result.errors)

if __name__ == '__main__':
    unittest.main()
