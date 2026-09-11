import pytest
from pydantic import ValidationError
from app.schemas.compliance_schemas import ComplianceEvaluationInput
from app.agents.grid_compliance_agent import GridComplianceAgent

def test_misnamed_readings_are_rejected_instead_of_silently_ignored():
    with pytest.raises(ValidationError):
        ComplianceEvaluationInput.model_validate({'gridVoltage': 400, 'mainBreakerRating': 63})

def test_missing_measurements_never_produce_compliant_assessment():
    result = GridComplianceAgent().evaluate(ComplianceEvaluationInput())
    assert not result['grid_compliant']
    assert result['compliance_status'] != 'COMPLIANT'
