"""
Phase 4 Proposal Guardrail Workflow.

LangGraph pipeline:
    LoadContext → SafetyGuardrailAgent → DeterministicProposalValidator → SetApprovalRequirement → END

The AI (SafetyGuardrailAgent) CANNOT approve a proposal.
The DeterministicProposalValidator has final authority.
"""
from typing import Any, Dict
from datetime import datetime, timezone
import time

from app.schemas.guardrail_schemas import GuardrailInput, GuardrailResult, GuardrailWorkflowResult
from app.agents.safety_guardrail_agent import SafetyGuardrailAgent
from app.agents.proposal_validator import DeterministicProposalValidator

guardrail_agent = SafetyGuardrailAgent()
validator = DeterministicProposalValidator()


def _log(logs, agent, step, status, summary, duration_ms=0, error=None):
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


def run_guardrail_workflow(payload: Dict[str, Any]) -> GuardrailWorkflowResult:
    """
    Execute the full proposal guardrail workflow.
    Always returns a GuardrailWorkflowResult — never raises to the caller.
    """
    start = time.time()
    execution_logs = []
    workflow_id = payload.get("workflow_id", f"wf-guard-{__import__('uuid').uuid4().hex[:8]}")
    proposal_id = payload.get("proposal_id")

    try:
        # ── Step 1: Parse and validate input ──────────────────────────────────
        t0 = time.time()
        try:
            input_data = GuardrailInput.model_validate(payload)
        except Exception as ex:
            execution_logs = _log(execution_logs, "Guardrail", "ingestion", "failed",
                                  "Input validation failed.", int((time.time() - t0) * 1000), str(ex))
            return GuardrailWorkflowResult(
                workflow_id=workflow_id,
                proposal_id=proposal_id,
                safety_status="REQUIRES_APPROVAL",
                risk_level="HIGH",
                requires_approval=True,
                issues=[f"Input validation error: {ex}"],
                recommendations=["Provide complete proposal data and retry."],
                recommendation_summary="Proposal guardrail could not be evaluated due to invalid input.",
                validation_override=False,
                override_reason="",
                execution_logs=execution_logs
            )

        execution_logs = _log(execution_logs, "GuardrailPlanner", "ingestion", "completed",
                              f"Proposal {proposal_id or 'N/A'} — {input_data.recommended_kw:.2f}kW ingested.",
                              int((time.time() - t0) * 1000))

        # ── Step 2: SafetyGuardrailAgent evaluation ───────────────────────────
        t1 = time.time()
        guardrail_result: GuardrailResult = guardrail_agent.evaluate(input_data)
        d1 = int((time.time() - t1) * 1000)

        execution_logs = _log(
            execution_logs, "SafetyGuardrailAgent", "evaluation",
            "completed",
            f"Safety: {guardrail_result.safety_status}, AI requires_approval: {guardrail_result.requires_approval}.",
            d1
        )

        # ── Step 3: DeterministicProposalValidator ────────────────────────────
        t2 = time.time()
        val = validator.validate(
            recommended_kw=input_data.recommended_kw,
            panel_count=input_data.panel_count,
            inverter_size_kw=input_data.inverter_size_kw,
            estimated_cost_lkr=input_data.estimated_cost_lkr,
            grid_compliance_status=input_data.grid_compliance_status,
            ai_says_requires_approval=guardrail_result.requires_approval
        )
        d2 = int((time.time() - t2) * 1000)

        was_overridden = bool(val["override_reason"])
        execution_logs = _log(
            execution_logs, "DeterministicProposalValidator", "validation",
            "completed",
            f"Final requires_approval: {val['requires_approval']}. Override: {was_overridden}.",
            d2,
            error=val["override_reason"] if was_overridden else None
        )

        # Merge AI issues + deterministic violations (no duplicates)
        all_issues = list(guardrail_result.issues)
        for v in val["violations"]:
            if v not in all_issues:
                all_issues.append(v)

        all_recommendations = list(guardrail_result.recommendations)

        # ── Step 4: Final decision ────────────────────────────────────────────
        final_safety_status = (
            "BLOCKED" if not val["valid"] else
            "REQUIRES_APPROVAL" if val["requires_approval"] else
            guardrail_result.safety_status
        )
        final_risk_level = guardrail_result.risk_level

        execution_logs = _log(
            execution_logs, "ApprovalRequirementSetter", "set_approval_requirement", "completed",
            f"Final decision: {final_safety_status}, requires_approval={val['requires_approval']}.",
            int((time.time() - start) * 1000)
        )

        return GuardrailWorkflowResult(
            workflow_id=input_data.workflow_id,
            proposal_id=proposal_id,
            safety_status=final_safety_status,
            risk_level=final_risk_level,
            requires_approval=val["requires_approval"],
            issues=all_issues,
            recommendations=all_recommendations,
            recommendation_summary=guardrail_result.recommendation_summary,
            validation_override=was_overridden,
            override_reason=val["override_reason"],
            execution_logs=execution_logs
        )

    except Exception as ex:
        execution_logs = _log(
            execution_logs, "GuardrailWorkflow", "error_handling", "failed",
            "Guardrail workflow encountered an unexpected exception.",
            int((time.time() - start) * 1000),
            error=str(ex)
        )
        # Fail safe — always requires approval on unknown error
        return GuardrailWorkflowResult(
            workflow_id=workflow_id,
            proposal_id=proposal_id,
            safety_status="REQUIRES_APPROVAL",
            risk_level="HIGH",
            requires_approval=True,
            issues=[f"Workflow exception: {ex}"],
            recommendations=["Retry guardrail evaluation."],
            recommendation_summary="Guardrail evaluation failed. Manual senior engineer review required.",
            validation_override=False,
            override_reason="",
            execution_logs=execution_logs
        )
