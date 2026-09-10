# Safety Guardrail Agent Specification

## Overview
The `SafetyGuardrailAgent` is a specialized agent in the Agentic AI service responsible for evaluating solar installation proposals against utility interconnection rules, capacity thresholds, grid compliance data, and site safety findings.

---

## Component Architecture

```
                       [ GuardrailInput ]
                               │
                               ▼
                    [ SafetyGuardrailAgent ]
                               │
               ┌───────────────┼───────────────┐
               ▼               ▼               ▼
         [ System Size ] [ Grid Status ] [ Site Safety ]
           (kW > 10.0)    (Compliance)     (Keywords)
               │               │               │
               └───────────────┼───────────────┘
                               ▼
                      [ GuardrailResult ]
                               │
                               ▼
               [ DeterministicProposalValidator ]
                               │
                               ▼
                  [ GuardrailWorkflowResult ]
```

---

## Key Rules & Evaluation Logic

1. **System Size Rule**:
   - `recommended_kw > 10.0 kW`: Interconnection approval required by utility guidelines. Triggers `requires_approval = True`.
2. **Grid Compliance Rule**:
   - `grid_compliance_status` in `{"NON_COMPLIANT", "CONDITIONAL"}`: Senior engineer review required to verify grid stabilization measures.
3. **Risk Level Rule**:
   - `risk_level` in `{"HIGH", "CRITICAL"}`: Senior engineer review mandatory.
4. **Site Safety Keyword Inspection**:
   - Scans field inspection safety notes for hazard keywords (`danger`, `hazard`, `unsafe`, `exposed wire`). Flags for human review if found.

---

## Fail-Safe Behavior
- On Pydantic schema validation error or unhandled exception, `SafetyGuardrailAgent` catches the error and returns:
```json
{
  "safety_status": "REQUIRES_APPROVAL",
  "risk_level": "HIGH",
  "requires_approval": true,
  "issues": ["Internal guardrail error — approval required by default."],
  "recommendations": ["Contact administrator."]
}
```
