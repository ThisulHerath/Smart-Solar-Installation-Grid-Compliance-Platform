# Manual acceptance guide — Smart Solar

Use this guide in order. It follows one synthetic project across all five accounts. Record screenshots and actual results; tick a step only after you perform it. Test values are software fixtures, not measurements or installation advice for a real property.

## 1. Open the services

- React: http://localhost:5173
- Flutter in Microsoft Edge: http://localhost:5180
- API health: http://localhost:5116/api/health
- Swagger: http://localhost:5116/swagger
- Internal AI health: http://127.0.0.1:8001/health

Expected API health fields: `status: healthy`, `database: connected`, `agenticAi: available`. A loaded page or HTTP 200 alone does not establish healthy dependencies. If degraded or timing out, resolve that before running the scenario. Restart commands are in [local UI walkthrough](local-ui-walkthrough.md). Do not launch duplicate servers on occupied ports.

Use React for staff and Flutter for the homeowner/technician. Log out before changing roles. Two ordinary tabs on the same origin share login storage; they are not independent accounts. Use a separate browser profile if simultaneous roles are needed. Swagger authorization is separate from signing into React.

## 2. Credentials and basic access

All five seeded local accounts use **Password@123**:

- Homeowner: `homeowner@smartsolar.local`
- Engineer: `engineer@smartsolar.local`
- Technician: `technician@smartsolar.local`
- Inventory officer: `inventory@smartsolar.local`
- Administrator: `admin@smartsolar.local`

First, sign out and open the public landing page. Follow a service link; expect login/registration. Try `/profile` while signed out; expect login. Enter a valid email with `WrongPassword!123`; expect an error and no authenticated workspace. Then enter the correct password. Expect the matching account name and role. Check profile, log out and verify protected pages require login again.

Use seeded accounts for the main workflow. Their `.local` addresses are not real inboxes and cannot receive OTP messages.

## 3. Homeowner — create the test project in Flutter

Log into Flutter as homeowner. Open **My solar surveys**. Enter:

- Monthly Consumption (kWh): `600`
- Roof Surface Area (m²): `80`
- Grid Connection Type: **Three Phase (400V)**
- Property Address: `MANUAL-A-01 - Synthetic solar test, Colombo`
- Optional photo: a harmless test roof image, not a real bill or personal document.

Choose **Submit Survey for AI Sizing** once, then wait/refresh. Find the same address under **Your Submitted Surveys & AI Results**.

Expected: `AnalysisComplete`, preliminary capacity **5 kW**, inverter **5 kW**, estimated **12 panels** under the current 400 W sizing/rounding rule. This is a preliminary estimate; the equipment stage uses a different 500 W policy. A failure message is not a successful AI run.

Search for `MANUAL-A-01` and use the status filter. Expect the matching survey. Photograph/screenshot the input and output.

AI evidence: PlannerAgent → SolarSizingAgent → DeterministicValidator. The current planner uses a fixed template and the specialists use deterministic rules; this is not an LLM conversation.

## 4. Engineer — inspect the survey and assign work

Log into React as engineer. Open **Staff Surveys** and find `MANUAL-A-01`. Expect the same consumption, area and analysis result entered in Flutter.

In React, open **Field Operations** and click **Assign technician**.

1. Customer survey: select `MANUAL-A-01 - Synthetic solar test, Colombo`.
2. Technician: select the active technician whose email is `technician@smartsolar.local`.
3. Priority: **Medium**.
4. Visit date and time: leave blank for this immediate test, or choose a local date/time.
5. Click **Assign site visit** once.
6. Expect a confirmation naming the technician/address, the form to close, and the assigned job to appear in the list.
7. Open the job to review it. Record JOB_ID from its detail URL if needed for optional API checks.

The technician will see this job in Flutter after refreshing their job list. No IDs or Swagger calls are needed to assign the visit. Only engineers and administrators can access this staff form. The backend also rejects inactive users and users without the technician role. If there are no surveys/active technicians, the form explains the problem and prevents submission.

Optional API evidence later: log into Swagger with `POST /api/auth/login`, using the appropriate role's email/password. Copy its returned token without quotes; use **Authorize** and paste only the token (no added Bearer prefix). Execute `GET /api/surveys`, find the exact test address and record its `id` as SURVEY_ID. Never include tokens in screenshots.

## 5. Technician — complete field work in Flutter

Log out of homeowner in Flutter, then log in as technician. Open **Site jobs and inspections** and select the test address.

Choose **Record GPS Check-in** and allow location access. Expect successful check-in and job progress. On Edge, location availability depends on browser/Windows permissions. If it fails, do not claim GPS passed.

For a software-only fallback, authorize Swagger with the technician token using the login procedure above, then execute `POST /api/technician/jobs/{jobId}/check-in` using JOB_ID and:

```json
{"latitude":6.9,"longitude":79.8}
```

These are explicitly synthetic coordinates. This verifies the API, not physical-device GPS.

Enter the inspection form:

- Measured Roof Area: `80`
- Roof Tilt Angle: `20`
- Main Breaker Rating: `63`
- Observed grid connection: **Three phase**
- Roof orientation: **South**
- Inverter Location Suitable: **ON**
- Grid Voltage: `400`
- Grid Freq: `50`
- Voc: `48`
- Isc: `12`

Under **Site Evidence Photographs**, choose Roof/Meter/ElectricalPanel/ and upload clearly labelled test images. Expect a success message. Test both photo selection and, separately on a real device, camera capture and permission denial.

Choose **Save Inspection Draft**. Expect `Site inspection draft & telemetry saved.` Then choose **Submit Inspection for Grid Compliance Evaluation**. Submission also saves the form. Expect a compliance result of **COMPLIANT**, `gridCompliant: true` in API evidence, and completed compliance/job status. Exact badge spacing can differ between clients.

AI evidence: GridComplianceAgent and deterministic compliance checks. These project thresholds do not certify an actual installation.

## 6. Engineer — check that mobile evidence arrived

In React as engineer, refresh **Field Operations** and open the same job. Confirm the inspection values, readings, submitted evidence and compliance result match Flutter. Search by the synthetic address and test the completed-status filter. A different job with similar values is not cross-platform proof.

## 7. Homeowner — request the engineering proposal

In Flutter, log out of technician and back in as homeowner. Open **My solar surveys**, locate the exact test address and choose **Proposal and equipment** → **Request engineering proposal**.

Expected: **PendingApproval** / Pending Approval, **5 kW**, inverter **5 kW**, preliminary panel count **12**. The current preliminary proposal estimate is **LKR 1,710,000**: 12 × 80,000 plus 5 × 150,000. It is separate from the live catalog quote, not a final commercial offer. Inspect safety/recommendation information. The proposal must not become Approved merely because the safety check ran.

AI evidence: SafetyGuardrailAgent plus deterministic proposal validation. Human approval remains a separate action.

## 8. Engineer — approve in React

Open **Pending Approvals** as engineer. Identify the proposal for the same survey and open it. Review capacity, compliance, safety information, validation and history. Record **PROPOSAL_ID** from its detail URL (`/proposals/ID`); it is needed when selecting equipment later.

Click **Approve Proposal** → **Confirm Approval**. Expected: **Approved** and an approval audit entry. Return to the same proposal in Flutter and use refresh. Expected: the same approval decision there.

Do not reject or request revision on this main project before finishing pricing. Separate scenarios below test those branches.

## 9. Inventory officer — equipment, pricing and reservation

Log into React as inventory officer → **Inventory**. Search/filter/sort existing equipment first; expect relevant rows and working pagination when more than ten rows exist.

Optional supplier test: expand **Add supplier**, enter name `Manual Test Supplier A01`, leave optional email/phone empty, then **Save supplier**. Expect confirmation and the supplier available in the equipment form.

Use **Add equipment** twice, with unique SKUs each time you repeat this guide:

**Panel:** SKU `MANUAL-A01-PANEL`; Name `Manual 500 W Panel`; Category PANEL; Capacity 500; Stock quantity 30; Reorder level 2; Unit price USD 100; Active checked.

**Inverter:** SKU `MANUAL-A01-INVERTER`; Name `Manual 5 kW Inverter`; Category INVERTER; Capacity 5000; Stock quantity 4; Reorder level 2; Unit price USD 500; Active checked.

Manufacturer/model can be `Software demo`; supplier is optional. Click **Save equipment**. Expect saved rows with available stock and initially zero reservations for these new items.

Under **Proposal equipment & pricing**, select the approved proposal by the first eight characters of PROPOSAL_ID and 5 kW. Click **Calculate equipment price**.

Expected: **VALIDATED**, rate and timestamp, **10 × 500 W panels**, **1 compatible inverter**, LKR total, quote expiry and **Workflow activity** logs. Existing compatible catalog items may be selected instead of the two you added. Verify the actual selected item names and prices.

If the selected prices are USD 100 and USD 500, the USD subtotal is **1,500**, so the expected LKR total is **1,500 × the displayed exchange rate**, subject to line rounding. Do not expect a fixed LKR amount or the same total as the preliminary proposal. Equipment estimates exclude installation and taxes.

Open **Workflow activity**. Expect exchange-rate/tool, equipment-selection and validation activity. Then click **Reserve this equipment**.

Expected: quote becomes **RESERVED**; reservation rows appear. For the selected panel, reserved quantity rises by 10 and available quantity falls by 10; the inverter changes by 1. Total stock stays unchanged because this reserves items rather than selling/removing them. Account for any pre-existing reservations on the selected items.

## 10. Homeowner — confirm the final outcome

Refresh **Proposal and equipment** for your survey in Flutter. Expect **Approved**, a visible equipment quote and **RESERVED** equipment status. Take the final screenshot before releasing stock. Close/reopen the view and refresh to confirm the result is persisted.

Then inventory officer may choose **Release equipment** for this demo quote. Expect **RELEASED** and available stock restored. Flutter should show the updated status after refresh. Reusing a released quote to reserve again must be rejected; a new valid quote is required.

## 11. Administrator — overview and permissions

Log into React as administrator. Open Dashboard, Staff Surveys, Field Operations, Proposals, Pending Approvals, Inventory, My Profile and Account & security. Expect matching account/role, functioning pages and visible test records appropriate to each section. Counts depend on existing records; do not expect exact totals.

This app does not currently provide a complete admin user-management screen. Do not claim that CRUD feature based on administrator login alone.

As homeowner, try `/inventory` and `/proposals/pending`: expect restricted access and no staff data. As inventory officer, try the approval page: expect restricted access. Engineer may read inventory but should not receive inventory-writer controls.

For a backend permission test, authorize Swagger as homeowner and call `POST /api/proposals/{id}/approve` with the test PROPOSAL_ID and `{"comment":"Unauthorized test"}`. Expect **403**, with no new approval/change. Role-switching in Swagger requires replacing its authorized token.

## 12. View the AI state and diagnostic

In Swagger as engineer or administrator, execute `GET /api/workflows/surveys/{id}` with SURVEY_ID. Expect linked objective, plan, sizing/validation, compliance, safety, proposal decision, equipment results and available audit history. Save a screenshot of results without tokens. Some stage logs/timings are incomplete; absence must be recorded rather than invented.

For a small diagnostic, execute `POST /api/agent-workflows/test`:

```json
{
  "objective":"Assess the manual test rooftop",
  "customerId":"manual-test-user",
  "inputData":{"monthly_kwh":600,"roof_area_sqm":80,"grid_type":"ThreePhase"}
}
```

Expected: `current_step: completed`, the same objective/customer ID, `validation_results.valid: true`, a plan and three sizing-stage log entries. This diagnostic does **not** execute inspection, approval or pricing and is not proof of all four agents.

## 13. Registration, profile and account security

Use a separate disposable account with an inbox you control; do not modify/delete the seeded accounts.

Register with Full name `Manual Test Homeowner`, your actual email, optional phone blank, Password and Confirm password `ManualSolar@12345`. Choose **Continue with email verification**. Expect a code in your inbox if the email provider is configured. Check spam. There is no universal test OTP.

Enter an intentionally incorrect code once; expect rejection and no registration. Enter the latest real code; expect account creation and homeowner access. Log out and log back in. Verify name/email/role on profile. Try registering the same email again; expect no duplicate account.

In **Account & security** → **Change password**, enter and confirm `ManualSolarNew@12345`, request the code and verify using the inbox. Expect sessions to end, old password rejected and new password accepted.

Optional final destructive test: only for this disposable account, open **Delete account**, read/accept its acknowledgement and complete email verification. Expect login access removed; retained audit records are not promised to be erased. Stop before final verification if you want to keep the account.

## 14. Failure and alternate-path scenarios

Use new addresses `MANUAL-B-01`, `MANUAL-C-01`, etc. Do not damage the successful project.

- **Invalid survey:** monthly usage `-10` or roof area `0` → form/API error; no successful sizing result.
- **Noncompliance:** repeat the inspection scenario on B, with ThreePhase voltage `500` and frequency `60` → noncompliant findings; no normal approval/stock reservation should proceed.
- **Revision:** on a separate valid pending proposal, engineer → Request Revision → comment `Please verify roof measurements and resubmit.` → confirm. Expect RevisionRequested and history; homeowner sees Request updated proposal. Address the requested data before resubmitting.
- **Rejection:** separate pending proposal → Reject Proposal → comment `Duplicate software test request.` → confirm. Expect Rejected and history on both clients.
- **Input checks:** missing rejection/revision comment → confirmation blocked; duplicate inventory SKU → validation error; negative stock/price → blocked.
- **Low-stock filter:** create a separate unused item with stock 1 and reorder level 2 → it appears under Low stock only. Do not alter shared stock to force this.
- **Deactivation:** deactivate only an unused test item → Inactive; it should no longer be selected for new pricing.
- **AI unavailable:** after the successful run, stop only the Solar Python server in its terminal. Submit a new survey or run the diagnostic. Expect a visible failed/unavailable outcome, no fabricated successful analysis and no automatic approval/reservation. Restart the AI server on 8001 afterwards. If Codex owns that server and you have no terminal control, skip this test until it is started in your terminal.
- **Unauthorized internal call:** Python workflow endpoints without the internal header should return 401. Do not copy the server's private key into a browser or report.
- **Persistence:** refresh/reopen both clients → saved survey, proposal and quote remain. Different IDs or disappearing records indicate a failure to investigate.

## 15. Evidence and pass criteria

Keep: health screenshot; each role/profile; survey input/output; job ID and inspection; compliance; pending proposal; engineer approval/history; pricing/tool activity; stock before/after; homeowner final status; one denied action; one safe failure; genuine OTP and physical-device evidence when performed.

For every step record **PASS / FAIL / NOT TESTED**, actual result, screenshot and survey/job/proposal IDs. UI wording can differ from API status strings; record both when unclear. If a step fails, stop that scenario and keep the exact error rather than repeatedly submitting duplicate records.

A successful main scenario establishes integrated operation. It does not establish 100% coverage, native-device behaviour, deployment readiness or completion of the assignment's planning/recovery requirements. See [assignment readiness](../assessment/assignment-readiness.md) for those remaining gaps.
