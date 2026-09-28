# Implemented agent architecture

Reviewed 15 September 2026. FastAPI, LangGraph and Pydantic host deterministic specialists. No runtime LLM is called. Codex development assistance is separate from this runtime.

## Coordinated roles

- PlannerAgent classifies a reviewed solar objective into a full-installation, compliance-review, or equipment-pricing workflow and emits a typed plan with dependencies, required inputs, permitted tools, human-impact markers, and status. It rejects unrelated goals. Its selection is deterministic and reviewable; it is not language-model reasoning. No external tool or write permissions.
- SolarSizingAgent: SolarSizingInput → SolarSizingRecommendation (capacity, panel count, inverter size, assumptions), followed by independent validation. No external tools or approval authority.
- GridComplianceAgent: ComplianceEvaluationInput → measurement findings checked by DeterministicComplianceValidator. Rules are project screening thresholds, not utility certification. No external tools or approval authority.
- SafetyGuardrailAgent: GuardrailInput → GuardrailResult, checked by DeterministicProposalValidator. ASP.NET enforces the authorized human decision. No approval or stock-write permission.
- EquipmentPricingAgent: typed requirements/catalog and exchange rate → panel/inverter line items. The pricing graph calls the fixed USD/LKR tool, then separate price and availability validators. No inventory-write permission.

Grid compliance can call only the versioned ProjectKnowledgeTool, and pricing can call only the fixed ExchangeRateTool. A central allow-list rejects cross-agent tool use. Other specialists calculate over API-supplied inputs. Four classes alone do not prove full assignment acceptance. See [readiness audit](../assessment/assignment-readiness.md).

## Integration and state

Flutter and React → ASP.NET authentication/business rules → PostgreSQL and internal Python endpoints → ASP.NET persisted outcomes → shared client status.

The four specialist endpoints are /workflow/solar-sizing, /workflow/compliance, /workflow/guardrail and /workflow/equipment-pricing. LangGraph handles sizing, safety and pricing subgraphs; compliance is procedural. The new `/workflow/start` and `/workflow/resume` endpoints coordinate these bounded stages as one recoverable state machine. They pause for inspection, engineering approval, pricing input and inventory review. ASP.NET persists the complete returned state after every event, so a service restart does not require an in-memory Python conversation. The legacy /workflow/test endpoint remains a sizing diagnostic.

ASP.NET stores AgentWorkflow/AgentExecutionLog, the canonical serialized workflow state, ComplianceAssessment, EngineeringProposal with approval/lifecycle records, and EquipmentQuote/reservations. The authorized `/api/agent-workflows/start`, `/api/agent-workflows/{id}/resume`, and `/api/agent-workflows/{id}` routes enforce ownership and role-specific events. The authorized `/api/workflows/surveys/{id}` overview exposes the current structured plan alongside business records. Survey ID and workflow ID make each run traceable.

## Controls and limitations

Internal endpoints require X-Internal-Key. Clients call ASP.NET only. Private cloud isolation remains deployment work. The exchange tool permits one fixed endpoint, USD/LKR only, no redirects, eight-second timeout, freshness validation and caching. Catalog text cannot choose URLs or execute instructions. ASP.NET owns approval and transactional stock changes.

Each execution event has a trace ID, span ID, stage name, status and timing. Invalid or incomplete inspection evidence returns to a correction state; high-impact approval and reservation stages remain paused for authorized people. There is no general autonomous retry scheduler or free-form tool selection. Logs contain execution summaries and decisions, not hidden chain-of-thought. These specialists do not certify CEB/LECO regulations, structural wind loads or utility approval.
