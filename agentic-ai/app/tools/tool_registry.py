"""Central least-privilege registry for tools callable by workflow agents."""

from collections.abc import Callable
from typing import Any


AGENT_TOOL_PERMISSIONS: dict[str, frozenset[str]] = {
    "PlannerAgent": frozenset(),
    "SolarSizingAgent": frozenset(),
    "GridComplianceAgent": frozenset({"ProjectKnowledgeTool"}),
    "SafetyGuardrailAgent": frozenset(),
    "EquipmentPricingAgent": frozenset({"ExchangeRateTool"}),
}


def permitted_tools(agent_name: str) -> list[str]:
    return sorted(AGENT_TOOL_PERMISSIONS.get(agent_name, frozenset()))


def authorize_tool(agent_name: str, tool_name: str) -> None:
    if tool_name not in AGENT_TOOL_PERMISSIONS.get(agent_name, frozenset()):
        raise PermissionError(f"{agent_name} is not permitted to use {tool_name}.")


def call_tool(agent_name: str, tool_name: str, action: Callable[..., Any], *args: Any, **kwargs: Any) -> Any:
    authorize_tool(agent_name, tool_name)
    return action(*args, **kwargs)

