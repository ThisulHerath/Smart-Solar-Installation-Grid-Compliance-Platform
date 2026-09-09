# Field Inspection Lifecycle & State Machine

## 1. Field Job Lifecycle State Machine

The field job processing lifecycle is governed by an explicit state transition matrix implemented in `FieldJobStatusTransition.cs`:

```mermaid
stateDiagram-v2
    [*] --> Assigned : Staff assigns technician
    Assigned --> Accepted : Technician accepts job
    Assigned --> InProgress : GPS Check-in
    Accepted --> InProgress : GPS Check-in
    InProgress --> Submitted : Technician submits inspection
    Submitted --> ComplianceProcessing : AI evaluation triggered
    ComplianceProcessing --> ComplianceComplete : Grid Compliant (Pass)
    ComplianceProcessing --> Failed : Violations detected (Fail)
    Failed --> Assigned : Re-assignment / Re-dispatch
    Failed --> InProgress : Re-survey
```

---

## 2. Transition Rules & Invariants

1. **State Immutability of Completed Jobs**: Once `ComplianceComplete` is reached, state is final unless re-evaluated by a Senior Engineer.
2. **Mandatory GPS Check-in**: Field technician cannot submit a site inspection without recorded GPS latitude and longitude coordinates.
3. **Deterministic Validation Gate**: The status cannot transition to `ComplianceComplete` if any statutory electrical thresholds (grid voltage, frequency, breaker rating) are breached.
4. **Audit Trail**: Every state transition updates `UpdatedAt` timestamps and emits structured logs in `ComplianceAssessment`.
