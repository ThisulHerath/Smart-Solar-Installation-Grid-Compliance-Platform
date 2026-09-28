from typing import Any, Literal

from pydantic import BaseModel, Field


class PlanStep(BaseModel):
    """A reviewable unit of work produced by the deterministic planner."""

    step_id: str = Field(min_length=1, max_length=80)
    title: str = Field(min_length=1, max_length=200)
    agent_name: str = Field(min_length=1, max_length=100)
    depends_on: list[str] = Field(default_factory=list)
    required_inputs: list[str] = Field(default_factory=list)
    allowed_tools: list[str] = Field(default_factory=list)
    high_impact: bool = False
    status: Literal["WAITING", "READY", "RUNNING", "COMPLETED", "FAILED", "PAUSED"] = "WAITING"


class WorkflowPlan(BaseModel):
    objective: str = Field(min_length=3, max_length=500)
    workflow_type: Literal["FULL_INSTALLATION", "COMPLIANCE_REVIEW", "EQUIPMENT_PRICING"]
    steps: list[PlanStep] = Field(min_length=1)


class MasterWorkflowStartRequest(BaseModel):
    workflow_id: str | None = Field(default=None, max_length=100)
    objective: str = Field(min_length=3, max_length=500)
    customer_id: str | None = Field(default=None, max_length=100)
    input_data: dict[str, Any] = Field(default_factory=dict)


class MasterWorkflowResumeRequest(BaseModel):
    workflow_state: dict[str, Any]
    event: Literal[
        "INSPECTION_COMPLETED",
        "ENGINEER_APPROVED",
        "ENGINEER_REJECTED",
        "REVISION_REQUESTED",
        "PRICING_REQUESTED",
        "INVENTORY_RESERVED",
    ]
    event_data: dict[str, Any] = Field(default_factory=dict)

