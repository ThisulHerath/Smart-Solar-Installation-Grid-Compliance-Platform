"""
DeterministicProposalValidator — Phase 4.

Authoritative validator that runs AFTER the SafetyGuardrailAgent.
Its decisions CANNOT be overridden by the AI — if a rule says approval is
required, it will be required regardless of what the AI output said.

Rules:
  1. recommendedKw > 10.0  → requiresApproval = True
  2. gridComplianceStatus in {NON_COMPLIANT, CONDITIONAL} → requiresApproval = True
  3. AI says requiresApproval=False but rule says True → OVERRIDE and LOG
"""
from typing import Dict, Any, List

HIGH_IMPACT_KW_THRESHOLD = 10.0
NON_COMPLIANT_STATUSES = {"NON_COMPLIANT", "CONDITIONAL"}


class DeterministicProposalValidator:
    """
    Deterministic rule-based validator for engineering proposals.
    Runs outside the LLM pipeline. Has final authority over approval decisions.
    """

    def validate(
        self,
        recommended_kw: float,
        panel_count: int,
        inverter_size_kw: float,
        estimated_cost_lkr: float,
        grid_compliance_status: str,
        ai_says_requires_approval: bool
    ) -> Dict[str, Any]:
        """
        Validates the proposal against deterministic rules.
        Returns a dict with:
          - valid: bool
          - requires_approval: bool (authoritative)
          - checks: list of pass/fail check descriptions
          - violations: list of rule violation messages
          - override_reason: str (non-empty if AI was overridden)
          - validation_status: str
        """
        checks: List[str] = []
        violations: List[str] = []
        override_reason = ""

        # ── Field Validation ─────────────────────────────────────────────────
        if recommended_kw <= 0:
            violations.append(f"recommendedKw ({recommended_kw}) must be > 0.")
            checks.append("FAIL:recommended_kw_positive")
        else:
            checks.append("PASS:recommended_kw_positive")

        if panel_count <= 0:
            violations.append(f"panelCount ({panel_count}) must be > 0.")
            checks.append("FAIL:panel_count_positive")
        else:
            checks.append("PASS:panel_count_positive")

        if inverter_size_kw <= 0:
            violations.append(f"inverterSizeKw ({inverter_size_kw}) must be > 0.")
            checks.append("FAIL:inverter_size_positive")
        else:
            checks.append("PASS:inverter_size_positive")

        if estimated_cost_lkr <= 0:
            violations.append(f"estimatedCostLkr ({estimated_cost_lkr}) must be > 0.")
            checks.append("FAIL:cost_positive")
        else:
            checks.append("PASS:cost_positive")

        # ── High-Impact Approval Rules (CANNOT be overridden by AI) ──────────
        requires_approval_by_rule = False

        # Rule 1: kW threshold
        if recommended_kw > HIGH_IMPACT_KW_THRESHOLD:
            requires_approval_by_rule = True
            violations.append(
                f"APPROVAL REQUIRED: recommendedKw ({recommended_kw:.2f}kW) exceeds "
                f"{HIGH_IMPACT_KW_THRESHOLD}kW threshold."
            )
            checks.append(f"FAIL:kw_threshold (>{HIGH_IMPACT_KW_THRESHOLD}kW)")
        else:
            checks.append(f"PASS:kw_threshold (<={HIGH_IMPACT_KW_THRESHOLD}kW)")

        # Rule 2: Compliance status
        compliance_upper = grid_compliance_status.upper()
        if compliance_upper in NON_COMPLIANT_STATUSES:
            requires_approval_by_rule = True
            violations.append(
                f"APPROVAL REQUIRED: gridComplianceStatus '{grid_compliance_status}' "
                "requires senior engineer review."
            )
            checks.append(f"FAIL:compliance_status ({grid_compliance_status})")
        else:
            checks.append(f"PASS:compliance_status ({grid_compliance_status})")

        # ── AI Override Check ─────────────────────────────────────────────────
        if not ai_says_requires_approval and requires_approval_by_rule:
            override_reason = (
                "DETERMINISTIC OVERRIDE: AI indicated approval was not required, "
                "but the high-impact rule triggered by "
                f"{'kW > 10' if recommended_kw > HIGH_IMPACT_KW_THRESHOLD else ''}"
                f"{'grid non-compliance' if compliance_upper in NON_COMPLIANT_STATUSES else ''}"
                " mandates approval. AI result rejected."
            )

        # Final decision: rule or AI can set requires_approval, but only rule can CLEAR it
        final_requires_approval = requires_approval_by_rule or ai_says_requires_approval
        field_errors_only = not requires_approval_by_rule and len(violations) > 0
        valid = len([v for v in violations if "APPROVAL REQUIRED" not in v]) == 0

        validation_status = (
            "VALIDATION_FAILED" if not valid else
            "PENDING_APPROVAL" if final_requires_approval else
            "APPROVED_WITHOUT_REVIEW"
        )

        return {
            "valid": valid,
            "requires_approval": final_requires_approval,
            "checks": checks,
            "violations": violations,
            "override_reason": override_reason,
            "validation_status": validation_status
        }
