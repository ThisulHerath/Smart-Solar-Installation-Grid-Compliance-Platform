from typing import List, Dict, Any, Optional, TypedDict
from pydantic import BaseModel, Field
import uuid

class WorkflowStateDict(TypedDict, total=False):
    workflow_id: str
    customer_id: Optional[str]
    objective: str
    input_data: Dict[str, Any]
    plan: List[str]
    current_step: str
    completed_steps: List[str]
    tool_results: Dict[str, Any]
    validation_results: Dict[str, Any]
    errors: List[str]
    approval_status: str
    final_outcome: str
    execution_logs: List[str]

class WorkflowExecutionRequest(BaseModel):
    objective: str = Field(..., description="Solar workflow objective or survey query")
    customer_id: Optional[str] = Field(None, description="Optional customer or site ID")
    input_data: Dict[str, Any] = Field(default_factory=dict, description="Input parameters and telemetry")

class WorkflowExecutionResponse(BaseModel):
    workflow_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    customer_id: Optional[str] = None
    objective: str
    plan: List[str] = Field(default_factory=list)
    current_step: str = "completed"
    completed_steps: List[str] = Field(default_factory=list)
    tool_results: Dict[str, Any] = Field(default_factory=dict)
    validation_results: Dict[str, Any] = Field(default_factory=dict)
    errors: List[str] = Field(default_factory=list)
    approval_status: str = "pending_engineer_review"
    final_outcome: str = ""
    execution_logs: List[str] = Field(default_factory=list)
