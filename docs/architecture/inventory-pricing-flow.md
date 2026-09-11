# Connected workflow and human control

1. Homeowner registers in Flutter and submits a survey with optional image.
2. ASP.NET persists survey/workflow state and calls the internal sizing graph. Planner output and execution logs are persisted. Incoming timestamps are normalized to UTC for PostgreSQL.
3. Engineer assigns a field job. Technician records real device check-in, photos, observed installation values and electrical readings.
4. Compliance specialist and validator screen the measurements. Latest readings are used on reevaluation; earlier readings remain audit evidence.
5. Homeowner requests an engineering proposal from an analysed survey. Safety findings and deterministic validation are saved.
6. The workflow pauses in PendingApproval. Only an engineer or administrator can approve, reject or request revision. Missing compliance evidence and a blocked safety finding prevent approval. Decision and audit record commit together under a serializable transaction.
7. Inventory officer prices an approved proposal through the controlled exchange-rate tool. A validated quote may be reserved atomically.
8. Homeowner reads equipment status and estimated cost. Reserved equipment means ready for installation planning, not installed or utility-connected.

GET /api/workflows/surveys/{id} reconstructs the shared survey workflow from durable records: objective, plan, specialist results, validation, human decision, errors and equipment outcomes. Restarting services does not lose the human approval pause. It is a set of coordinated request-driven workflows, not a continuously running autonomous process. The sizing graph alone does not execute all later phases.

Revision handling retains old proposal decisions. After an inspection is corrected and reevaluated, the homeowner can request an updated proposal under the same survey. Changed consumption/roof requirements require a new survey because submitted surveys are immutable.
