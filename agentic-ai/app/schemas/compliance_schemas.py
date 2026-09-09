from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field
import uuid

class ComplianceEvaluationInput(BaseModel):
    inspection_id: Optional[str] = None
    field_job_id: Optional[str] = None
    grid_type: str = "SinglePhase"
    phase_count: Optional[int] = 1
    main_breaker_rating: Optional[float] = None
    inverter_location_suitable: Optional[bool] = True
    roof_area_sqm: Optional[float] = None
    roof_tilt: Optional[float] = None
    roof_orientation: Optional[str] = None
    voc: Optional[float] = None
    isc: Optional[float] = None
    vmp: Optional[float] = None
    imp: Optional[float] = None
    irradiance: Optional[float] = None
    temperature: Optional[float] = None
    grid_voltage: Optional[float] = None
    grid_frequency: Optional[float] = None
    safety_notes: Optional[str] = None
    technician_notes: Optional[str] = None

class ComplianceEvaluationResponse(BaseModel):
    workflow_id: str = Field(default_factory=lambda: f"wf-comp-{uuid.uuid4().hex[:8]}")
    grid_compliant: bool
    compliance_status: str
    risk_level: str
    violations: List[str] = Field(default_factory=list)
    recommendations: List[str] = Field(default_factory=list)
    validation_status: str
    notes: Optional[str] = None
    execution_logs: List[Dict[str, Any]] = Field(default_factory=list)
