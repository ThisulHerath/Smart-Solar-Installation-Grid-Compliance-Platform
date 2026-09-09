from typing import Any, Dict, List
from datetime import datetime, timezone
import time
import uuid

from app.schemas.compliance_schemas import ComplianceEvaluationInput, ComplianceEvaluationResponse
from app.agents.grid_compliance_agent import GridComplianceAgent
from app.agents.compliance_validator import DeterministicComplianceValidator

compliance_agent = GridComplianceAgent()
validator = DeterministicComplianceValidator()

def _add_log(logs: List[Dict[str, Any]], agent: str, step: str, status: str, summary: str, duration_ms: int = 0, error: str = None) -> List[Dict[str, Any]]:
    now = datetime.now(timezone.utc).isoformat()
    return logs + [{
        "agent_name": agent,
        "step_name": step,
        "status": status,
        "started_at": now,
        "completed_at": now,
        "duration_ms": duration_ms,
        "output_summary": summary,
        "error_message": error,
        "retry_count": 0
    }]

def run_compliance_evaluation(payload: Dict[str, Any]) -> ComplianceEvaluationResponse:
    start_time = time.time()
    workflow_id = payload.get("workflow_id") or f"wf-comp-{uuid.uuid4().hex[:8]}"
    execution_logs: List[Dict[str, Any]] = []

    try:
        # Step 1: Input Validation / Ingestion
        t0 = time.time()
        input_data = ComplianceEvaluationInput.model_validate(payload)
        d0 = int((time.time() - t0) * 1000)
        execution_logs = _add_log(
            execution_logs,
            "CompliancePlanner",
            "ingestion",
            "completed",
            f"Ingested site inspection telemetry for job {input_data.field_job_id or 'N/A'}.",
            d0
        )

        # Step 2: GridComplianceAgent Evaluation
        t1 = time.time()
        candidate = compliance_agent.evaluate(input_data)
        d1 = int((time.time() - t1) * 1000)
        execution_logs = _add_log(
            execution_logs,
            "GridComplianceAgent",
            "evaluation",
            "completed",
            f"Evaluated grid compliance. Outcome: {candidate['compliance_status']}, Risk: {candidate['risk_level']}.",
            d1
        )

        # Step 3: Deterministic Compliance Validation
        t2 = time.time()
        val_result = validator.validate(candidate, input_data.model_dump())
        d2 = int((time.time() - t2) * 1000)
        is_val_passed = val_result["valid"]
        execution_logs = _add_log(
            execution_logs,
            "DeterministicComplianceValidator",
            "validation",
            "completed" if is_val_passed else "failed",
            f"Deterministic validation result: {val_result['validation_status']}.",
            d2,
            error=None if is_val_passed else "Deterministic validation criteria unsatisfied."
        )

        if not is_val_passed:
            candidate["grid_compliant"] = False
            candidate["compliance_status"] = "NON_COMPLIANT"
            candidate["risk_level"] = "HIGH"
            candidate["violations"].append("Deterministic safety guardrail check failed.")

        return ComplianceEvaluationResponse(
            workflow_id=workflow_id,
            grid_compliant=candidate["grid_compliant"],
            compliance_status=candidate["compliance_status"],
            risk_level=candidate["risk_level"],
            violations=candidate["violations"],
            recommendations=candidate["recommendations"],
            validation_status=val_result["validation_status"],
            notes=candidate.get("notes"),
            execution_logs=execution_logs
        )
    except Exception as ex:
        execution_logs = _add_log(
            execution_logs,
            "GridComplianceWorkflow",
            "error_handling",
            "failed",
            "Grid compliance workflow encountered an exception.",
            int((time.time() - start_time) * 1000),
            error=str(ex)
        )
        return ComplianceEvaluationResponse(
            workflow_id=workflow_id,
            grid_compliant=False,
            compliance_status="NON_COMPLIANT",
            risk_level="CRITICAL",
            violations=[f"Workflow execution exception: {str(ex)}"],
            recommendations=["Retry compliance evaluation with complete telemetry data."],
            validation_status="ERROR",
            notes="Compliance evaluation aborted due to server exception.",
            execution_logs=execution_logs
        )
