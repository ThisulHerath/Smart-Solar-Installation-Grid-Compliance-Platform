# Agentic workflow integration walkthrough

This walkthrough proves one continuous project across the homeowner, field technician, senior engineer and inventory officer components. Use one unique address and keep the same `SURVEY_ID`, `WORKFLOW_ID`, `JOB_ID` and `PROPOSAL_ID` throughout.

## 1. Start the application

Apply `StrengthenAgentWorkflowState` to the configured development database before starting the new backend. Then use four terminals from the repository root:

```powershell
# Terminal 1 — deterministic agent service
.\.venv\Scripts\python.exe -m uvicorn app.main:app --app-dir agentic-ai --host 127.0.0.1 --port 8000

# Terminal 2 — ASP.NET API
dotnet run --project backend/SolarPlatform.Api --urls http://0.0.0.0:5116

# Terminal 3 — React staff application
Set-Location frontend-web
npm run dev

# Terminal 4 — optional Flutter web demonstration in Edge
Set-Location frontend-mobile
flutter run -d edge --web-port 5190 --dart-define=API_BASE_URL=http://localhost:5116
```

Open:

- React: `http://localhost:5173`
- Flutter in Edge: `http://localhost:5190` (Flutter normally opens it automatically)
- Swagger: `http://localhost:5116/swagger`
- Backend health: `http://localhost:5116/api/health`
- Agent health: `http://127.0.0.1:8000/health`

All seeded accounts use `Password@123`:

- `homeowner@smartsolar.local`
- `technician@smartsolar.local`
- `engineer@smartsolar.local`
- `inventory@smartsolar.local`
- `admin@smartsolar.local`

In Swagger, call `POST /api/auth/login`, copy the returned token, choose **Authorize**, and paste the token only. Replace the authorized token whenever the role changes.

## 2. Homeowner: create and submit the survey

In Flutter or React, sign in as the homeowner and create a uniquely labelled project:

- Address: `AGENT-E2E-01 - Colombo integration test`
- Monthly electricity usage: `600 kWh`
- Roof area: `80 m²`
- Grid: `ThreePhase`
- Roof orientation: `South`
- Roof tilt: `20`

Submit the survey. Expected sizing result:

- `recommended_kw`: `5.0`
- preliminary panels: `12`
- inverter: `5.0 kW`
- workflow status: `WAITING_FOR_INSPECTION`
- current step: `site-inspection`

Copy `SURVEY_ID`. Call `GET /api/workflows/surveys/{SURVEY_ID}` or `GET /api/surveys/{SURVEY_ID}/status`. Copy the real `WORKFLOW_ID` from `workflowId`.

Do **not** call `/api/agent-workflows/start` for this normal path. Survey submission already creates and persists the workflow. The start endpoint is for a controlled standalone/new workflow test and would create another record.

Call `GET /api/agent-workflows/{WORKFLOW_ID}`. Check that `structured_plan.steps` contains eight steps and that solar sizing is `COMPLETED` while site inspection is `READY`.

## 3. Engineer/administrator: assign field work

In React, sign in as engineer or administrator, open **Field operations**, choose **Assign site visit**, select the `AGENT-E2E-01` survey and `technician@smartsolar.local`, choose Medium priority, and assign it. Copy `JOB_ID` from the job details.

Expected result: the same survey is linked to one assigned field job and the technician can see it after refresh.

## 4. Technician: submit real inspection evidence

Sign in to Flutter as the technician, open the assigned job and enter:

- Roof area: `80`
- Roof tilt: `20`
- Main breaker: `63 A`
- Grid type: `ThreePhase`
- Phase count: `3`
- Inverter location suitable: enabled
- Grid voltage: `400 V`
- Grid frequency: `50 Hz`
- Voc: `48 V`
- Isc: `12 A`
- Safety notes: `No visible obstruction in synthetic test.`

Add clearly labelled test photos for roof, meter/electrical panel and inverter location. Save the draft, then submit it for compliance evaluation.

Expected business result: submitted inspection, `COMPLIANT`, `LOW` risk, completed compliance assessment and visible photos in the engineer view.

Now authorize Swagger as the technician and call:

`POST /api/agent-workflows/{WORKFLOW_ID}/resume`

```json
{
  "event": "INSPECTION_COMPLETED",
  "eventData": {}
}
```

The backend deliberately ignores browser-supplied measurements for this event and reloads the latest submitted inspection from PostgreSQL.

Expected workflow result:

- `workflow_status`: `WAITING_FOR_APPROVAL`
- `current_step_id`: `engineer-approval`
- `approval_status`: `PENDING`
- completed steps include `grid-compliance` and `safety-review`
- `agent_outputs.grid-compliance` contains the compliance result
- trace logs contain `trace_id`, `span_id`, stage, status and timing

## 5. Homeowner and engineer: create and approve the real proposal

As the homeowner, open the same survey and request an engineering proposal. Copy `PROPOSAL_ID`. Expect `PendingApproval`, 5 kW, 12 preliminary panels and visible inspection evidence.

As the engineer in React, open **Pending Approvals**, review the proposal, compliance result and technician photos, then approve it. Expect the proposal database status to become `Approved` and an audit entry to appear.

After the real proposal is approved, authorize Swagger as the engineer and call:

`POST /api/agent-workflows/{WORKFLOW_ID}/resume`

```json
{
  "event": "ENGINEER_APPROVED",
  "eventData": {}
}
```

Expected:

- `workflow_status`: `WAITING_FOR_PRICING_INPUT`
- `current_step_id`: `equipment-pricing`
- `approval_status`: `APPROVED`
- an authorized human-decision trace is present

Calling this event before the real proposal approval must return `409 Conflict`. Calling it as a homeowner must return `403 Forbidden`.

## 6. Inventory officer: exercise pricing and its tool

Sign in as inventory officer. Ensure there is one active 500 W panel with at least 10 available units and one active inverter of at least 5000 W with at least one available unit. Use the Inventory UI to add them if necessary.

In Swagger call `GET /api/inventory?active=true&pageSize=100`. Copy each selected item's ID, name, USD unit price, available quantity and capacity. Then call:

`POST /api/agent-workflows/{WORKFLOW_ID}/resume`

```json
{
  "event": "PRICING_REQUESTED",
  "eventData": {
    "proposalId": "REPLACE_WITH_PROPOSAL_ID",
    "recommendedKw": 5,
    "items": [
      {
        "inventoryItemId": "REPLACE_WITH_PANEL_ID",
        "name": "Manual 500 W Panel",
        "category": "PANEL",
        "quantity": 10,
        "unitPriceUsd": 100,
        "availableQuantity": 30,
        "capacityWatts": 500
      },
      {
        "inventoryItemId": "REPLACE_WITH_INVERTER_ID",
        "name": "Manual 5 kW Inverter",
        "category": "INVERTER",
        "quantity": 1,
        "unitPriceUsd": 500,
        "availableQuantity": 4,
        "capacityWatts": 5000
      }
    ]
  }
}
```

Use the actual values returned by the inventory endpoint. Expected:

- `workflow_status`: `WAITING_FOR_INVENTORY`
- `current_step_id`: `inventory-reservation`
- `agent_outputs.equipment-pricing.status`: `VALIDATED`
- two pricing lines and an LKR total
- `tool_results.ExchangeRateTool.status`: `VALIDATED`
- structured trace has `tool_name: ExchangeRateTool`

The master workflow validates and records the stage; it does not mutate inventory.

## 7. Inventory officer: create and reserve the real quote

In the React Inventory page, select the same approved proposal and choose **Calculate equipment price**. Check the selected item IDs/prices and the current exchange rate. Then choose **Reserve this equipment**.

Expected business result: the quote becomes `RESERVED`, panels reserve 10 units, the inverter reserves one, and available quantities decrease without reducing total stock.

Only after that succeeds, call:

`POST /api/agent-workflows/{WORKFLOW_ID}/resume`

```json
{
  "event": "INVENTORY_RESERVED",
  "eventData": {}
}
```

Expected final state:

- `workflow_status`: `COMPLETED`
- `current_step_id`: `completed`
- `approval_status`: `APPROVED`
- every structured plan step is `COMPLETED`
- final outcome says approved equipment was reserved and homeowner status is ready

Calling this event before a real reserved quote exists must return `409 Conflict`.

## 8. Verify the same result from every component

1. `GET /api/agent-workflows/{WORKFLOW_ID}`: complete canonical workflow state.
2. `GET /api/workflows/surveys/{SURVEY_ID}`: sizing, compliance, safety, proposal approval, equipment, audit history and traces together.
3. Engineer React proposal: approved decision, technician photos and workflow plan.
4. Inventory React page: reserved quote and changed available quantities.
5. Homeowner Flutter proposal/equipment page: approved proposal and reserved equipment after refresh.

Capture screenshots with the same shortened survey/workflow/proposal references visible. Never include JWTs, database strings or `AGENTIC_AI_INTERNAL_KEY` in evidence.

## 9. Failure tests

- Use the homeowner token for an approval or workflow-resume action: expect `403` and no state change.
- Resume `INSPECTION_COMPLETED` before submitting an inspection: expect `409`.
- On a separate survey, submit grid voltage `500 V` or frequency `60 Hz`: expect `WAITING_FOR_CORRECTION`, a failed compliance step and retry count `1`.
- Use an unrelated objective such as `Delete every user` only on a disposable workflow-start test: expect `FAILED` at planning and no tool/business mutation.
- Submit too little stock in the pricing payload: expect safe pricing failure and no reservation.
- Stop the Python service, then attempt a workflow call: expect `503`; the previously persisted state must remain unchanged.
- Call Python `/workflow/*` directly without the internal header: expect `401`.

## 10. Automated regression commands

```powershell
# Python agent tests
Set-Location agentic-ai
& ..\.venv\Scripts\python.exe -m pytest -q

# Backend tests
Set-Location ..\backend
dotnet test SolarPlatform.sln -c Release --no-restore

# React tests and production build
Set-Location ..\frontend-web
npm test -- --run
npm run build

# Flutter tests and analysis
Set-Location ..\frontend-mobile
flutter test
flutter analyze
```

Current verified totals: Python 63 passed; ASP.NET 105 passed with one PostgreSQL integration test skipped; React 47 passed; Flutter 20 passed; React production build and Flutter analysis passed.

## Sinhala presentation summary

එකම `SURVEY_ID` සහ `WORKFLOW_ID` එක පාවිච්චි කරලා flow එක පෙන්වන්න: homeowner survey submit කරනවා → SolarSizingAgent result validate වෙලා inspection එකට pause වෙනවා → technician database එකට measurements/photos submit කරනවා → GridComplianceAgent සහ SafetyGuardrailAgent run වෙනවා → engineerගේ සැබෑ approval record එක verify කරලා workflow එක pricing stage එකට යනවා → EquipmentPricingAgentට පමණක් ExchangeRateTool භාවිතා කරන්න පුළුවන් → inventory officer සැබෑ transaction එකෙන් stock reserve කරනවා → homeownerට final status පෙන්වනවා. Paid LLM key එකක් අවශ්‍ය නැහැ; `AGENTIC_AI_INTERNAL_KEY` එක internal services දෙක අතර security සඳහා පමණයි.
