"""Validated inspection -> cited project guidance -> screening -> independent check."""
from typing import Any, Dict
from uuid import uuid4
from app.schemas.compliance_schemas import ComplianceEvaluationInput, ComplianceEvaluationResponse
from app.agents.grid_compliance_agent import GridComplianceAgent
from app.agents.compliance_validator import DeterministicComplianceValidator
from app.tools.project_knowledge import retrieve_project_guidance
from app.workflow.observability import trace_stage

compliance_agent = GridComplianceAgent()
validator = DeterministicComplianceValidator()


def run_compliance_evaluation(payload: Dict[str, Any]) -> ComplianceEvaluationResponse:
    workflow_id = payload.get("workflow_id") or f"wf-comp-{uuid4().hex[:8]}"
    logs = []
    try:
        with trace_stage(logs, workflow_id, "CompliancePlanner", "ingestion"):
            data = ComplianceEvaluationInput.model_validate(payload)
        with trace_stage(logs, workflow_id, "ProjectKnowledgeTool", "retrieve_guidance"):
            evidence = retrieve_project_guidance("grid voltage frequency inspection measurements", 2)
            if not evidence:
                raise ValueError("Reviewed project guidance unavailable")
        with trace_stage(logs, workflow_id, "GridComplianceAgent", "evaluation"):
            candidate = compliance_agent.evaluate(data)
        with trace_stage(logs, workflow_id, "DeterministicComplianceValidator", "validation") as event:
            validation = validator.validate(candidate, data.model_dump())
            event["validation_result"] = validation["validation_status"]
            if not validation["valid"]:
                event["status"] = "failed"
                candidate.update(grid_compliant=False, compliance_status="NON_COMPLIANT", risk_level="HIGH")
                candidate["violations"].append("Deterministic safety guardrail check failed.")
        source_note = "; ".join(f"{item['source']} (v{item['version']})" for item in evidence)
        return ComplianceEvaluationResponse(
            workflow_id=workflow_id, grid_compliant=candidate["grid_compliant"],
            compliance_status=candidate["compliance_status"], risk_level=candidate["risk_level"],
            violations=candidate["violations"], recommendations=candidate["recommendations"],
            validation_status=validation["validation_status"],
            notes=(candidate.get("notes") or "") + " Reviewed project references: " + source_note,
            evidence=evidence, execution_logs=logs)
    except Exception:
        # Pydantic errors can include raw input values; never return those to clients.
        return ComplianceEvaluationResponse(
            workflow_id=workflow_id, grid_compliant=False, compliance_status="NON_COMPLIANT",
            risk_level="CRITICAL", violations=["Compliance evaluation could not complete with the supplied input."],
            recommendations=["Review the required measurements and retry compliance evaluation."],
            validation_status="ERROR", notes="No compliance clearance was granted.", execution_logs=logs)
