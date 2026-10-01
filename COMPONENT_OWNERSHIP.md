# Smart Solar component ownership

This repository is organized by four independently demonstrable business components. Each member owns the complete vertical slice for their component: database entities, ASP.NET API, React UI, Flutter UI, agentic workflow, tests, documentation, and demonstration.

| Member | Component | Primary users | Agentic contribution |
| --- | --- | --- | --- |
| Member 1 | Customer assessment and solar sizing | Homeowner, administrator | `SolarSizingAgent` turns validated survey data into a structured system recommendation. |
| Member 2 | Field operations and grid compliance | Field technician, engineer | `GridComplianceAgent` uses inspection telemetry and the project knowledge tool; a deterministic validator independently checks the result. |
| Member 3 | Engineering proposal and approval | Engineer, administrator | `SafetyGuardrailAgent` evaluates proposal risk; `DeterministicProposalValidator` enforces approval rules and human approval remains authoritative. |
| Member 4 | Inventory, pricing, and procurement | Inventory officer, engineer | `EquipmentPricingAgent` chooses and prices equipment using the exchange-rate tool; pricing and stock validators verify the result. |

Shared authentication, notifications, file storage, API clients, navigation, and master orchestration are integration infrastructure. Each shared area should have a named maintainer during development, but it does not replace any member's individual business-component contribution.

## Folder ownership

```text
backend/SolarPlatform.Api/Features/
  Assessment/          # Member 1
  FieldOperations/     # Member 2
  Engineering/         # Member 3
  Inventory/           # Member 4
backend/SolarPlatform.Api/Shared/

frontend-web/src/features/
  assessment/          # Member 1
  field-operations/    # Member 2
  engineering/         # Member 3
  inventory/           # Member 4

frontend-mobile/lib/features/
  assessment/          # Member 1
  field_operations/    # Member 2
  engineering/         # Member 3
  inventory/           # Member 4
frontend-mobile/lib/core/

agentic-ai/app/features/
  assessment/          # Member 1
  field_operations/    # Member 2
  engineering/         # Member 3
  inventory/           # Member 4
agentic-ai/app/shared/  # Planner, graph, observability, tool authorization
```

Tests mirror the same ownership under `backend/SolarPlatform.Tests/Features`, `frontend-web/src/features/*/__tests__`, and `agentic-ai/tests`. Flutter tests import the corresponding feature or core package directly.

## Integration boundary

The normal end-to-end sequence is:

1. Member 1 records a named customer survey and runs solar sizing.
2. Member 2 assigns and completes the site inspection, including GPS, photographs, telemetry, and grid-compliance evaluation.
3. Member 3 generates, validates, revises, and approves the engineering proposal with a recorded human decision.
4. Member 4 receives the approved proposal, calculates equipment pricing, handles the inventory request, and reserves or releases stock.

The shared planner coordinates these stages, persists workflow state, pauses at human approval, and resumes only after an authorized decision. Feature workflows remain independently testable and callable.
