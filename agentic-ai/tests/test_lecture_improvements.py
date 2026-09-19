from datetime import datetime, timezone
from unittest.mock import patch
import httpx
import pytest
from app.tools.project_knowledge import retrieve_project_guidance, POLICY_VERSION
from app.workflow.graph import run_solar_sizing_workflow
from app.workflow.compliance_workflow import run_compliance_evaluation
import app.tools.exchange_rate as exchange


@pytest.mark.parametrize('query,expected', [
    ('monthly electricity sizing', 'sizing'),
    ('nominal voltage frequency tolerance', 'grid'),
    ('technician photos measurements inspection', 'inspection'),
    ('senior engineer approval', 'approval'),
    ('USD LKR prices taxes', 'pricing'),
    ('PostgreSQL transaction stock twice', 'reservation'),
])
def test_small_reviewed_retrieval_set(query, expected):
    result = retrieve_project_guidance(query)
    assert result[0]['id'] == expected
    assert result[0]['version'] == POLICY_VERSION
    assert result[0]['source'] == 'project-policy:' + expected


def test_retrieval_does_not_invent_evidence_or_accept_unbounded_queries():
    assert retrieve_project_guidance('') == []
    assert retrieve_project_guidance('xyzzy') == []
    with pytest.raises(ValueError):
        retrieve_project_guidance('x' * 1001)
    with pytest.raises(ValueError):
        retrieve_project_guidance('solar', 6)


def test_sizing_spans_are_measured_and_correlated():
    result = run_solar_sizing_workflow(dict(workflow_id='trace-test', customer_id='test', monthly_kwh=600, roof_area_sqm=80, grid_type='ThreePhase'))
    assert result['current_step'] == 'COMPLETE'
    assert len(result['execution_logs']) == 3
    for event in result['execution_logs']:
        assert event['trace_id'] == 'trace-test'
        assert event['span_id']
        assert datetime.fromisoformat(event['completed_at']) >= datetime.fromisoformat(event['started_at'])
        assert event['duration_ms'] >= 0


def test_invalid_sizing_preserves_failed_span_without_raw_error():
    result = run_solar_sizing_workflow(dict(workflow_id='bad', monthly_kwh=float('nan'), roof_area_sqm=80))
    assert result['current_step'] == 'FAILED'
    assert result['execution_logs'][-1]['status'] == 'failed'
    assert result['execution_logs'][-1]['agent_name'] == 'SolarSizingAgent'


def test_compliance_includes_versioned_references_and_safe_failures():
    result = run_compliance_evaluation(dict(grid_type='ThreePhase', grid_voltage=400, grid_frequency=50, main_breaker_rating=63, inverter_location_suitable=True))
    assert result.grid_compliant
    assert {item['id'] for item in result.evidence} == {'grid', 'inspection'}
    assert 'project-policy:grid' in result.notes
    bad = run_compliance_evaluation(dict(grid_voltage='PRIVATE-INPUT'))
    assert not bad.grid_compliant
    assert bad.validation_status == 'ERROR'
    assert 'PRIVATE-INPUT' not in bad.model_dump_json()
    assert bad.execution_logs[-1]['status'] == 'failed'


def response(status=200):
    return httpx.Response(status, json=dict(result='success', base_code='USD', rates={'LKR':300}, time_last_update_unix=int(datetime.now(timezone.utc).timestamp())), request=httpx.Request('GET', exchange.ENDPOINT))


def test_missing_location_evidence_never_defaults_to_suitable():
    result = run_compliance_evaluation(dict(grid_type='ThreePhase', grid_voltage=400, grid_frequency=50, main_breaker_rating=63))
    assert not result.grid_compliant
    assert any('inverter_location_suitable' in issue for issue in result.violations)


def test_transient_tool_failure_retries_once_and_caches_success(monkeypatch):
    monkeypatch.setattr(exchange, '_cached', None)
    monkeypatch.setattr(exchange, '_cached_at', None)
    with patch('httpx.Client.get', side_effect=[httpx.TimeoutException('offline'), response()]) as get, patch.object(exchange.time, 'sleep'):
        assert exchange.get_usd_to_lkr_exchange_rate().rate == 300
        assert exchange.get_usd_to_lkr_exchange_rate().rate == 300
        assert get.call_count == 2


@pytest.mark.parametrize('status,attempts', [(403, 1), (503, 2)])
def test_tool_retry_is_bounded_and_does_not_fabricate_rate(monkeypatch, status, attempts):
    monkeypatch.setattr(exchange, '_cached', None)
    with patch('httpx.Client.get', return_value=response(status)) as get, patch.object(exchange.time, 'sleep'), pytest.raises(httpx.HTTPStatusError):
        exchange.get_usd_to_lkr_exchange_rate()
    assert get.call_count == attempts
    assert exchange._cached is None
