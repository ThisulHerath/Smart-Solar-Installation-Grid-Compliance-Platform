# System Architecture

## Architectural Overview
The **Smart Solar Installation & Grid Compliance Platform** is structured as a multi-tier, secure, distributed cloud system designed for solar installation planning, grid compliance verification, and field telemetry.

```mermaid
graph TD
    ClientWeb["React 18 Web App (Vercel)"] -->|REST + JWT| ApiGateway["ASP.NET Core 8 Web API (Render)"]
    ClientMobile["Flutter Mobile App (Android APK)"] -->|REST + JWT| ApiGateway

    subgraph "Secure Internal Tier"
        ApiGateway -->|Npgsql / EF Core| NeonDB[("Neon Managed PostgreSQL\n(steep-band-56603943)")]
        ApiGateway -->|Internal HTTP + X-Internal-Key| AIService["Python FastAPI / LangGraph (Render)"]
    end

    subgraph "Agentic AI Multi-Agent Workflow"
        AIService --> PlannerAgent["Planner Agent"]
        AIService --> GridAgent["Grid Compliance Agent (CEB/LECO)"]
        AIService --> PricingAgent["Equipment Pricing Agent"]
        AIService --> SafetyAgent["Safety Guardrail Agent"]
    end
```

## Architectural Boundaries & Principles
1. **Authoritative Public Entrypoint**: ASP.NET Core is the **only** publicly accessible backend service.
2. **Direct Access Prohibition**: Neither React Web nor Flutter Mobile are permitted to communicate directly with Neon PostgreSQL or the Python FastAPI AI service.
3. **Role-Based Access Control**: Standard JWT tokens carry user identities and roles (`HOMEOWNER`, `FIELD_TECHNICIAN`, `SENIOR_ENGINEER`, `INVENTORY_OFFICER`, `ADMINISTRATOR`).
4. **Resilience & Graceful Degradation**: If downstream AI or database dependencies experience transient downtime, the health and workflow endpoints handle errors safely without platform crashes.
