"""
SafetyGuardrailAgent — Phase 4.

Responsibility:
- Inspect the proposed solar system against safety and compliance rules
- Identify safety/compliance concerns and issues
- Determine whether high-impact approval is required (advisory only)
- Produce structured, Pydantic-validated safety findings
- NEVER directly approve a proposal

This agent is deterministic-rule-based (matching Phase 2/3 pattern).
The DeterministicProposalValidator has final authority over approval decisions.
"""
from typing import Any, Dict, List
from datetime import datetime, timezone
from pydantic import ValidationError

from app.schemas.guardrail_schemas import GuardrailInput, GuardrailResult

# Max kW for routine (no-approval) installation
HIGH_IMPACT_KW_THRESHOLD = 10.0
NON_COMPLIANT_STATUSES = {"NON_COMPLIANT", "CONDITIONAL"}
HIGH_RISK_LEVELS = {"HIGH", "CRITICAL"}


class SafetyGuardrailAgent:
    """
    Evaluates a proposed solar installation for safety and compliance risks.
    Returns a structured GuardrailResult — never approves directly.
    """

    def __init__(self, name: str = "SafetyGuardrailAgent"):
        self.name = name

    def execute(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """Backward compatibility for generic state execution in test_workflow.py."""
        val = dict(state.get("validation_results", {}))
        val["safety_guardrails"] = {
            "roof_setback_met": None,
            "clearance_met": None,
            "safety_status": "INPUT_REQUIRED"
        }
        state["validation_results"] = val
        return state

    def evaluate(self, data: GuardrailInput) -> GuardrailResult:
        """
        Run safety and compliance checks. Returns a validated GuardrailResult.
        On any internal error, defaults to REQUIRES_APPROVAL (fail-safe).
        """
        try:
            return self._run_checks(data)
        except ValidationError:
            # Pydantic validation failed — return safe default
            return GuardrailResult(
                safety_status="REQUIRES_APPROVAL",
                risk_level="HIGH",
                requires_approval=True,
                issues=["Internal guardrail validation error — approval required by default."],
                recommendations=["Contact system administrator to investigate guardrail failure."],
                recommendation_summary="Safety guardrail encountered a validation error. Manual senior engineer review required.",
                workflow_id=data.workflow_id
            )
        except Exception as ex:
            # Any unexpected error — fail safe
            return GuardrailResult(
                safety_status="REQUIRES_APPROVAL",
                risk_level="HIGH",
                requires_approval=True,
                issues=[f"Guardrail evaluation error: {type(ex).__name__}"],
                recommendations=["Retry after investigating the error."],
                recommendation_summary="Safety evaluation could not be completed. Approval required.",
                workflow_id=data.workflow_id
            )

    def _run_checks(self, data: GuardrailInput) -> GuardrailResult:
        issues: List[str] = []
        recommendations: List[str] = []
        requires_approval: bool = False
        logs: List[dict] = []

        now = datetime.now(timezone.utc).isoformat()

        # ── Check 1: System Size (kW threshold) ───────────────────────────────
        if data.recommended_kw > HIGH_IMPACT_KW_THRESHOLD:
            requires_approval = True
            issues.append(
                f"System size {data.recommended_kw:.2f}kW exceeds the {HIGH_IMPACT_KW_THRESHOLD}kW "
                "high-impact threshold. Utility interconnection approval required."
            )
            recommendations.append(
                "Submit CEB/LECO interconnection application before proceeding. "
                "Consider splitting into multiple smaller arrays if feasible."
            )
        else:
            recommendations.append(
                f"System size {data.recommended_kw:.2f}kW is within routine installation limits (<= {HIGH_IMPACT_KW_THRESHOLD}kW)."
            )

        logs.append({
            "agent_name": self.name,
            "step_name": "kw_threshold_check",
            "status": "requires_approval" if data.recommended_kw > HIGH_IMPACT_KW_THRESHOLD else "passed",
            "started_at": now, "completed_at": now,
            "output_summary": f"Recommended kW: {data.recommended_kw:.2f}kW"
        })

        # ── Check 2: Grid Compliance Status ───────────────────────────────────
        compliance_upper = data.grid_compliance_status.upper()
        if compliance_upper in NON_COMPLIANT_STATUSES:
            requires_approval = True
            issues.append(
                f"Grid compliance status '{data.grid_compliance_status}' indicates non-conformance "
                "with CEB/LECO standards. Rectification and senior engineering review required."
            )
            recommendations.append(
                "Resolve all grid compliance violations before proceeding. "
                "Re-run site inspection after corrective actions are complete."
            )
        else:
            recommendations.append(
                f"Grid compliance status '{data.grid_compliance_status}' is acceptable."
            )

        logs.append({
            "agent_name": self.name,
            "step_name": "compliance_status_check",
            "status": "requires_approval" if compliance_upper in NON_COMPLIANT_STATUSES else "passed",
            "started_at": now, "completed_at": now,
            "output_summary": f"Compliance: {data.grid_compliance_status}"
        })

        # ── Check 3: Risk Level ───────────────────────────────────────────────
        risk_upper = data.risk_level.upper()
        if risk_upper in HIGH_RISK_LEVELS:
            requires_approval = True
            issues.append(
                f"Risk level '{data.risk_level}' is elevated. "
                "Senior engineer review mandatory for high/critical risk installations."
            )
            recommendations.append(
                "Conduct a full risk assessment and implement risk mitigation measures "
                "before installation proceeds."
            )

        logs.append({
            "agent_name": self.name,
            "step_name": "risk_level_check",
            "status": "requires_approval" if risk_upper in HIGH_RISK_LEVELS else "passed",
            "started_at": now, "completed_at": now,
            "output_summary": f"Risk: {data.risk_level}"
        })

        # ── Check 4: Safety Notes from Site Inspection ────────────────────────
        danger_keywords = ["unsafe", "danger", "hazard", "exposed wire", "structural", "risk"]
        if data.safety_notes:
            notes_lower = data.safety_notes.lower()
            flagged = [kw for kw in danger_keywords if kw in notes_lower]
            if flagged:
                requires_approval = True
                issues.append(
                    f"Safety notes contain concern keywords: {', '.join(flagged)}. "
                    "Senior engineer inspection of site safety notes recommended."
                )
                recommendations.append(
                    "Review site-specific safety notes with a licensed electrical engineer "
                    "before proceeding with installation."
                )

        logs.append({
            "agent_name": self.name,
            "step_name": "safety_notes_review",
            "status": "completed",
            "started_at": now, "completed_at": now,
            "output_summary": "Safety notes reviewed."
        })

        # ── Check 5: Three-Phase Large System ────────────────────────────────
        grid_type_lower = data.grid_type.lower()
        is_three_phase = "three" in grid_type_lower or "3phase" in grid_type_lower
        if is_three_phase and data.recommended_kw > 5.0:
            recommendations.append(
                f"Three-phase installation of {data.recommended_kw:.2f}kW: "
                "ensure inverter neutral earthing and phase balancing complies with SLS 1522."
            )

        # ── Determine Safety Status ───────────────────────────────────────────
        if not issues:
            safety_status = "SAFE"
            risk_level = "LOW"
        elif len(issues) == 1 and data.recommended_kw <= HIGH_IMPACT_KW_THRESHOLD:
            safety_status = "REQUIRES_APPROVAL"
            risk_level = "MEDIUM"
        else:
            safety_status = "REQUIRES_APPROVAL"
            risk_level = data.risk_level if data.risk_level.upper() in HIGH_RISK_LEVELS else "MEDIUM"

        # Build summary
        if issues:
            summary = (
                f"Safety evaluation identified {len(issues)} concern(s) requiring attention. "
                f"System: {data.recommended_kw:.2f}kW, {data.panel_count} panels. "
                f"Grid: {data.grid_compliance_status}. Risk: {risk_level}."
            )
        else:
            summary = (
                f"System of {data.recommended_kw:.2f}kW ({data.panel_count} panels) "
                f"passed all routine safety checks. Grid: {data.grid_compliance_status}."
            )

        logs.append({
            "agent_name": self.name,
            "step_name": "safety_verdict",
            "status": "completed",
            "started_at": now, "completed_at": now,
            "output_summary": f"Safety verdict: {safety_status}, requires_approval: {requires_approval}"
        })

        return GuardrailResult(
            safety_status=safety_status,
            risk_level=risk_level,
            requires_approval=requires_approval,
            issues=issues,
            recommendations=recommendations,
            recommendation_summary=summary,
            workflow_id=data.workflow_id,
            execution_logs=logs
        )
