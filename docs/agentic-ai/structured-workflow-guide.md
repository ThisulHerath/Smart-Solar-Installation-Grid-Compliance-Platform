# Structured agent workflow guide (English / සිංහල)

## English

### Does this require an API key?

No language-model API key is required. The runtime uses reviewed deterministic rules, Pydantic contracts, LangGraph specialist subgraphs, and a persisted master state machine. The existing `AGENTIC_AI_INTERNAL_KEY` is a private service-to-service authentication secret between ASP.NET and FastAPI; it is not an OpenAI, Gemini, or paid-model key.

### What happens from the beginning?

1. ASP.NET starts a workflow for a survey through `POST /api/agent-workflows/start`.
2. PlannerAgent classifies the objective and creates a typed plan. Every step declares its dependencies, inputs, allowed tools, status, and whether a human-controlled action is involved.
3. SolarSizingAgent calculates a preliminary system and an independent validator checks the result.
4. The workflow pauses at `WAITING_FOR_INSPECTION`. A technician must submit real measurements and evidence.
5. The technician event resumes the workflow. GridComplianceAgent may read only reviewed project guidance through ProjectKnowledgeTool. A deterministic validator decides whether the evidence passes.
6. SafetyGuardrailAgent checks the proposed system. Failed or missing evidence returns the workflow to `WAITING_FOR_CORRECTION` and increments the retry count.
7. A valid result pauses at `WAITING_FOR_APPROVAL`. Only an authorized senior engineer or administrator can apply the approval event in ASP.NET.
8. Approved work can continue to pricing. EquipmentPricingAgent alone may call ExchangeRateTool. It produces structured line items which are independently checked.
9. The workflow pauses for an inventory officer. ASP.NET performs the real transactional reservation; Python cannot reserve stock.
10. ASP.NET saves the complete state and normalized execution logs after every event. The workflow can therefore resume after a service restart.

### Main implementation files

- `agentic-ai/app/agents/planner_agent.py`: objective classification and typed planning.
- `agentic-ai/app/schemas/plan_schemas.py`: plan and start/resume contracts.
- `agentic-ai/app/tools/tool_registry.py`: least-privilege tool permissions.
- `agentic-ai/app/workflow/master_workflow.py`: pause, resume, correction, approval, pricing, and completion transitions.
- `agentic-ai/app/main.py`: internal `/workflow/start` and `/workflow/resume` endpoints.
- `backend/SolarPlatform.Api/Controllers/AgentWorkflowsController.cs`: authenticated user-facing start/resume/read API and role checks.
- `backend/SolarPlatform.Api/Integrations/AgenticAiService.cs`: authenticated ASP.NET-to-Python client.
- `backend/SolarPlatform.Api/Models/AgentWorkflow.cs` and `AgentExecutionLog.cs`: durable state and trace metadata.
- `frontend-web/src/components/WorkflowSummary.tsx`: readable step status in the web UI.

### Four member contribution areas

1. Member 1 — customer survey, preliminary solar sizing, validation, and homeowner status UI.
2. Member 2 — technician assignment, inspection evidence/photos, grid compliance, and correction flow.
3. Member 3 — engineering proposal, safety guardrails, deterministic validation, human approval, and audit UI.
4. Member 4 — equipment catalog, exchange-rate tool, quote validation, transactional reservation, and final workflow status.

Each member can demonstrate a React/Flutter screen, ASP.NET API and database behavior, Python specialist logic, validation, tests, and one failure path within their component.

## සිංහල

### API key එකක් අවශ්‍යද?

Paid LLM API key එකක් අවශ්‍ය නැහැ. මෙහි runtime එක deterministic rules, Pydantic contracts, LangGraph specialist subgraphs සහ database එකේ save කරන master workflow state එක භාවිතා කරනවා. `AGENTIC_AI_INTERNAL_KEY` කියන්නේ ASP.NET සහ FastAPI අතර request එක විශ්වාසදායකද කියලා පරීක්ෂා කරන internal secret එකක්. ඒක OpenAI/Gemini API key එකක් නොවේ.

### මුල සිට workflow එක ක්‍රියා කරන්නේ කොහොමද?

1. Survey එකකට ASP.NET මගින් workflow එක start කරනවා.
2. PlannerAgent objective එක හඳුනාගෙන dependencies, required inputs, allowed tools, status සහ human-control සලකුණු ඇති structured plan එකක් හදනවා.
3. SolarSizingAgent preliminary system size එක ගණනය කරනවා. වෙනම deterministic validator එක result එක පරීක්ෂා කරනවා.
4. Workflow එක `WAITING_FOR_INSPECTION` තත්ත්වයේ නවතිනවා. Technician විසින් සැබෑ measurements සහ evidence දිය යුතුයි.
5. Inspection event එකෙන් workflow එක resume වෙනවා. GridComplianceAgentට ProjectKnowledgeTool එකෙන් reviewed project guidance කියවන්න විතරයි අවසර තියෙන්නේ.
6. Evidence අඩු නම් හෝ validation fail නම් workflow එක `WAITING_FOR_CORRECTION` වෙත යනවා සහ retry count එක වැඩි වෙනවා.
7. Valid result එකක් ලැබුණාම `WAITING_FOR_APPROVAL` තත්ත්වයේ නවතිනවා. ASP.NET role check එක අනුව Senior Engineer හෝ Administrator කෙනෙකුට පමණක් approval event එක යවන්න පුළුවන්.
8. Approval පසු EquipmentPricingAgentට පමණක් ExchangeRateTool භාවිතා කර quote එක ගණනය කළ හැකියි. වෙනම validators catalog සහ arithmetic පරීක්ෂා කරනවා.
9. Inventory Officer සඳහා workflow එක නැවත pause වෙනවා. සැබෑ stock reservation transaction එක ASP.NET කරනවා; Python agent එකට stock වෙනස් කරන්න බැහැ.
10. සෑම event එකකට පසුව complete state එක සහ trace logs database එකට save වෙන නිසා service restart වුණත් workflow එක නැවත continue කළ හැකියි.

### Members හතර දෙනාට බෙදීම

1. Member 1 — Customer Survey සහ Solar Sizing.
2. Member 2 — Field Inspection, Photos සහ Grid Compliance.
3. Member 3 — Proposal, Safety Validation සහ Engineer Approval.
4. Member 4 — Equipment Pricing, Inventory Reservation සහ Final Status.

මෙය agentic contribution එක ශක්තිමත් කරනවා: goal-based plan selection, structured state, controlled tools, feedback/correction loop, pause/resume, human approval සහ traceability තියෙනවා. නමුත් live LLM reasoning හෝ generative RAG භාවිතා කරන බව presentation එකේ කියන්න එපා.
