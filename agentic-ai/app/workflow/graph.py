from typing import Dict, Any, List
import uuid

from app.agents.planner_agent import PlannerAgent
from app.agents.grid_compliance_agent import GridComplianceAgent
from app.agents.equipment_pricing_agent import EquipmentPricingAgent
from app.agents.safety_guardrail_agent import SafetyGuardrailAgent
from app.schemas.state import WorkflowStateDict

# Agent instances
planner = PlannerAgent()
grid_agent = GridComplianceAgent()
pricing_agent = EquipmentPricingAgent()
safety_agent = SafetyGuardrailAgent()

def node_planning(state: Dict[str, Any]) -> Dict[str, Any]:
    return planner.execute(state)

def node_delegation(state: Dict[str, Any]) -> Dict[str, Any]:
    logs: List[str] = state.get("execution_logs", [])
    completed: List[str] = state.get("completed_steps", [])
    
    logs.append("[Orchestrator] Delegating sub-tasks to GridComplianceAgent and EquipmentPricingAgent.")
    completed.append("delegation")

    # Delegate to sub-agents
    grid_res = grid_agent.execute(state)
    pricing_res = pricing_agent.execute(state)

    tool_results = state.get("tool_results", {})
    tool_results.update(grid_res.get("tool_results", {}))
    tool_results.update(pricing_res.get("tool_results", {}))

    return {
        "tool_results": tool_results,
        "completed_steps": completed,
        "execution_logs": logs
    }

def node_execution_placeholder(state: Dict[str, Any]) -> Dict[str, Any]:
    logs: List[str] = state.get("execution_logs", [])
    completed: List[str] = state.get("completed_steps", [])

    logs.append("[Orchestrator] Execution placeholder: Synthesized preliminary design options.")
    completed.append("execution_placeholder")

    return {
        "completed_steps": completed,
        "execution_logs": logs
    }

def node_validation_placeholder(state: Dict[str, Any]) -> Dict[str, Any]:
    logs: List[str] = state.get("execution_logs", [])
    completed: List[str] = state.get("completed_steps", [])

    logs.append("[Orchestrator] Delegating safety checks to SafetyGuardrailAgent.")
    completed.append("validation_placeholder")

    safety_res = safety_agent.execute(state)
    validation_results = state.get("validation_results", {})
    validation_results.update(safety_res.get("validation_results", {}))

    return {
        "validation_results": validation_results,
        "completed_steps": completed,
        "execution_logs": logs
    }

def node_result(state: Dict[str, Any]) -> Dict[str, Any]:
    logs: List[str] = state.get("execution_logs", [])
    completed: List[str] = state.get("completed_steps", [])

    logs.append("[Orchestrator] Workflow graph execution completed. Ready for Senior Engineer review.")
    completed.append("result_aggregation")

    return {
        "current_step": "completed",
        "approval_status": "pending_engineer_review",
        "final_outcome": "Preliminary solar site plan generated successfully with CEB/LECO compliance validation and initial bill of materials.",
        "completed_steps": completed,
        "execution_logs": logs
    }

def build_workflow():
    """
    Builds the workflow graph. Tries LangGraph StateGraph, with fallback to sequential execution.
    """
    try:
        from langgraph.graph import StateGraph, END

        graph = StateGraph(WorkflowStateDict)
        graph.add_node("planning", node_planning)
        graph.add_node("delegation", node_delegation)
        graph.add_node("execution_placeholder", node_execution_placeholder)
        graph.add_node("validation_placeholder", node_validation_placeholder)
        graph.add_node("result", node_result)

        graph.set_entry_point("planning")
        graph.add_edge("planning", "delegation")
        graph.add_edge("delegation", "execution_placeholder")
        graph.add_edge("execution_placeholder", "validation_placeholder")
        graph.add_edge("validation_placeholder", "result")
        graph.add_edge("result", END)

        return graph.compile()
    except Exception:
        # Fallback executor matching identical nodes
        class FallbackGraph:
            def invoke(self, initial_state: Dict[str, Any]) -> Dict[str, Any]:
                s = dict(initial_state)
                for node_fn in [node_planning, node_delegation, node_execution_placeholder, node_validation_placeholder, node_result]:
                    out = node_fn(s)
                    s.update(out)
                return s

        return FallbackGraph()

compiled_workflow = build_workflow()

def run_solar_workflow(objective: str, customer_id: str = None, input_data: Dict[str, Any] = None) -> Dict[str, Any]:
    initial_state: Dict[str, Any] = {
        "workflow_id": str(uuid.uuid4()),
        "customer_id": customer_id,
        "objective": objective,
        "input_data": input_data or {},
        "plan": [],
        "current_step": "initialized",
        "completed_steps": [],
        "tool_results": {},
        "validation_results": {},
        "errors": [],
        "approval_status": "in_progress",
        "final_outcome": "",
        "execution_logs": [f"Initiating solar workflow: {objective}"]
    }

    result = compiled_workflow.invoke(initial_state)
    return result
