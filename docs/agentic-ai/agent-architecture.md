# Implemented agent architecture

Reviewed 15 September 2026. FastAPI, LangGraph and Pydantic host deterministic specialists. No runtime LLM is called. Codex development assistance is separate from this runtime.

## Five roles

- PlannerAgent emits an ordered eight-step plan from a fixed template. It does not dynamically select tasks from an objective. No external tool or write permissions.
- SolarSizingAgent: SolarSizingInput → SolarSizingRecommendation (capacity, panel count, inverter size, assumptions), followed by independent validation. No external tools or approval authority.
- GridComplianceAgent: ComplianceEvaluationInput → measurement findings checked by DeterministicComplianceValidator. Rules are project screening thresholds, not utility certification. No external tools or approval authority.
- SafetyGuardrailAgent: GuardrailInput → GuardrailResult, checked by DeterministicProposalValidator. ASP.NET enforces the authorized human decision. No approval or stock-write permission.
- EquipmentPricingAgent: typed requirements/catalog and exchange rate → panel/inverter line items. The pricing graph calls the fixed USD/LKR tool, then separate price and availability validators. No inventory-write permission.

Only pricing calls an external tool; other specialists calculate over API-supplied inputs. Four classes alone do not prove full assignment acceptance. See [readiness audit](../assessment/assignment-readiness.md).

## Integration and state

Flutter and React → ASP.NET authentication/business rules → PostgreSQL and internal Python endpoints → ASP.NET persisted outcomes → shared client status.

The four specialist endpoints are /workflow/solar-sizing, /workflow/compliance, /workflow/guardrail and /workflow/equipment-pricing. LangGraph handles sizing, safety and pricing subgraphs; compliance is procedural. ASP.NET coordinates multiple requests and human pauses. The legacy /workflow/test diagnostic exercises sizing only and retains string logs containing serialized event summaries.

ASP.NET stores AgentWorkflow/AgentExecutionLog, ComplianceAssessment, EngineeringProposal with approval/lifecycle records, and EquipmentQuote/reservations. The authorized /api/workflows/surveys/{id} overview aggregates them. Survey ID links the business process; specialist calls can have different workflow IDs. State is distributed, not one canonical resumable graph checkpoint.

## Controls and limitations

Internal endpoints require X-Internal-Key. Clients call ASP.NET only. Private cloud isolation remains deployment work. The exchange tool permits one fixed endpoint, USD/LKR only, no redirects, eight-second timeout, freshness validation and caching. Catalog text cannot choose URLs or execute instructions. ASP.NET owns approval and transactional stock changes.

Fixed planning, inconsistent cross-stage timings/retry traces and crash recovery need strengthening. There is no general autonomous retry scheduler. Logs contain execution summaries and decisions, not hidden reasoning. These specialists do not certify CEB/LECO regulations, structural wind loads or utility approval.
