# Grid Compliance Agent & Deterministic Validation Architecture

## 1. Overview

The `GridComplianceAgent` evaluates on-site solar survey measurements and electrical telemetry against Sri Lankan utility distribution standards (CEB / LECO) and international statutory codes:
- **IEEE 1547**: Standard for Interconnection and Interoperability of Distributed Energy Resources.
- **IEC 61727**: Photovoltaic (PV) systems - Characteristics of the utility interface.
- **SLS 1522**: Sri Lanka Standards for grid-connected rooftop solar installations.

---

## 2. Engineering Threshold Matrix

| Parameter | Nominal Standard | Allowable Operating Window | Critical Trip Limits | Statutory Standard |
| :--- | :--- | :--- | :--- | :--- |
| **Single-Phase Voltage** | 230 V AC | 216.2 V – 243.8 V (±6%) | < 200 V or > 260 V | SLS 1522 / CEB Guide |
| **Three-Phase Voltage** | 400 V AC | 376.0 V – 424.0 V (±6%) | < 350 V or > 450 V | SLS 1522 / CEB Guide |
| **Grid Frequency** | 50.0 Hz | 49.5 Hz – 50.5 Hz (±1%) | < 48.0 Hz or > 52.0 Hz | IEEE 1547 |
| **Main Breaker Rating** | >= 32 A | >= 30 A | < 30 A (Undersized) | IET Wiring Regs (18th Ed) |
| **Inverter Location** | Sheltered & Ventilated | Clear airflow (>= 300mm) | Fire hazard / Sun exposed | SLS 1522 Section 4.2 |

---

## 3. LangGraph Multi-Agent Architecture

```
[Inbound Inspection Data] 
       │
       ▼
[CompliancePlanner Node] ──► Ingestion, parameter sanitation & normalization
       │
       ▼
[GridComplianceAgent Node] ──► Voltage, frequency, string DC checks, violations synthesis
       │
       ▼
[DeterministicValidator Node] ──► Zero-violation compliance verification, risk matrix consistency
       │
       ▼
[ComplianceEvaluationResponse]
```

### Deterministic Safety Guardrail
Even if an LLM or heuristic candidate claims `grid_compliant: true`, the `DeterministicComplianceValidator` independently validates:
1. `violations.length == 0` when `grid_compliant == true`.
2. Grid voltage falls strictly within allowable nominal tolerance.
3. Inverter location suitability flag is `true`.
4. Risk level aligns directly with violation severity.

If any invariant fails, the validator forces `grid_compliant = false`, `compliance_status = NON_COMPLIANT`, and attaches a validation failure reason.
