"""
Pydantic schemas for the SafetyGuardrailAgent (Phase 4).
Input and structured output are strictly validated — no free-form text trusted.
"""
from typing import List, Optional, Literal
from pydantic import BaseModel, Field
import uuid


class GuardrailInput(BaseModel):
    """Input to the SafetyGuardrailAgent workflow."""
    proposal_id: Optional[str] = None
    workflow_id: str = Field(default_factory=lambda: f"wf-guard-{uuid.uuid4().hex[:8]}")

    # Technical specs
    recommended_kw: float = Field(gt=0)
    panel_count: int = Field(gt=0)
    inverter_size_kw: float = Field(gt=0)
    estimated_cost_lkr: float = Field(ge=0)

    # Compliance context
    grid_compliance_status: str = "UNKNOWN"
    risk_level: str = "UNKNOWN"
    grid_type: str = "SinglePhase"
    monthly_kwh: float = Field(default=0.0, ge=0)
    roof_area_sqm: float = Field(default=0.0, ge=0)

    # Safety notes from field inspection
    safety_notes: Optional[str] = None
    compliance_notes: Optional[str] = None


class GuardrailResult(BaseModel):
    """
    Structured output from SafetyGuardrailAgent.
    The AI NEVER approves — it only recommends.
    Deterministic validator has final authority on requiresApproval.
    """
    safety_status: Literal["SAFE", "REQUIRES_APPROVAL", "BLOCKED"] = "REQUIRES_APPROVAL"
    risk_level: str = "HIGH"
    requires_approval: bool = True
    issues: List[str] = Field(default_factory=list)
    recommendations: List[str] = Field(default_factory=list)
    recommendation_summary: str = ""
    workflow_id: Optional[str] = None
    execution_logs: List[dict] = Field(default_factory=list)


class GuardrailWorkflowResult(BaseModel):
    """Full response from the /workflow/guardrail endpoint."""
    workflow_id: str
    proposal_id: Optional[str] = None
    safety_status: str
    risk_level: str
    requires_approval: bool
    issues: List[str] = Field(default_factory=list)
    recommendations: List[str] = Field(default_factory=list)
    recommendation_summary: str = ""
    validation_override: bool = False
    override_reason: str = ""
    execution_logs: List[dict] = Field(default_factory=list)
