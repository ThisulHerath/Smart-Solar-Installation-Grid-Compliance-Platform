import importlib
import sys

import pytest
from fastapi.testclient import TestClient
import dotenv


def load_main(monkeypatch, key=None):
    if key is None:
        monkeypatch.delenv("AGENTIC_AI_INTERNAL_KEY", raising=False)
    else:
        monkeypatch.setenv("AGENTIC_AI_INTERNAL_KEY", key)
    sys.modules.pop("app.main", None)
    return importlib.import_module("app.main")


def test_missing_internal_key_is_a_configuration_error(monkeypatch):
    monkeypatch.setattr(dotenv, "load_dotenv", lambda: None)
    with pytest.raises(RuntimeError, match="AGENTIC_AI_INTERNAL_KEY"):
        load_main(monkeypatch)


def test_invalid_internal_key_is_rejected(monkeypatch):
    main = load_main(monkeypatch, "test-internal-key")
    client = TestClient(main.app)

    response = client.post(
        "/workflow/guardrail",
        json={"recommended_kw": 5, "panel_count": 10, "inverter_size_kw": 5, "estimated_cost_lkr": 1},
        headers={"X-Internal-Key": "wrong-key"},
    )

    assert response.status_code == 401


def test_workflow_endpoint_preserves_objective_input_and_serializes_logs(monkeypatch):
    main = load_main(monkeypatch, "test-internal-key")
    response = TestClient(main.app).post(
        "/workflow/test",
        json={"objective": "Assess my rooftop", "customer_id": "customer-42",
              "input_data": {"monthly_kwh": 600, "roof_area_sqm": 80, "grid_type": "ThreePhase"}},
        headers={"X-Internal-Key": "test-internal-key"},
    )
    assert response.status_code == 200
    result = response.json()
    assert result["objective"] == "Assess my rooftop"
    assert result["customer_id"] == "customer-42"
    assert result["current_step"] == "completed"
    assert len(result["execution_logs"]) == 3
    assert all(isinstance(log, str) for log in result["execution_logs"])
    assert result["validation_results"]["valid"] is True
