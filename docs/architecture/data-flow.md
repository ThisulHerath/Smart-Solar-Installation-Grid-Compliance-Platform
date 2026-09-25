# Platform Data Flow

## 1. Authentication Flow
```mermaid
sequenceDiagram
    autonumber
    actor User as Client (Web / Mobile)
    participant API as ASP.NET Core API
    participant DB as Neon PostgreSQL

    User->>API: POST /api/auth/login { email, password }
    API->>DB: Query User & Roles by Email
    DB-->>API: Return User Entity & Password Hash
    API->>API: Verify BCrypt Password Hash
    API->>API: Generate Cryptographic JWT Token (HS256)
    API-->>User: 200 OK { token, user: { id, email, fullName, roles } }
```


## 2. Agentic AI Workflow Flow
```mermaid
sequenceDiagram
    autonumber
    actor Client as Authenticated Client
    participant API as ASP.NET Core API
    participant AI as Python FastAPI / LangGraph
    participant Agents as LangGraph Multi-Agents

    Client->>API: POST /api/agent-workflows/test { objective }
    API->>API: Validate Request & Authorize
    API->>AI: POST /workflow/test [Header: X-Internal-Key]
    AI->>Agents: Invoke StateGraph (Planning -> Delegation -> Execution -> Validation -> Result)
    Agents-->>AI: Consolidated Workflow State
    AI-->>API: Structured Workflow JSON
    API-->>Client: 200 OK { workflow_id, plan, execution_logs, approval_status }
```


## 3. Survey Submission & Preliminary Sizing Flow
```mermaid
sequenceDiagram
    autonumber
    actor Homeowner as Homeowner (Mobile/Web)
    participant API as ASP.NET Core API
    participant DB as PostgreSQL
    participant AI as Agentic AI (Solar Sizing Agent)

    Homeowner->>API: POST /api/surveys { monthlyKwh, roofAreaSqm, gridType, address }
    API->>DB: Save SolarSurvey (status: Draft)
    Homeowner->>API: POST /api/surveys/{id}/images (JPEG/PNG, up to 5 MB)
    API->>DB: Save SolarSurveyImage
    Homeowner->>API: POST /api/surveys/{id}/submit
    API->>DB: Create AgentWorkflow, set survey status: Submitted -> Processing
    API->>AI: ExecuteSolarSizingAsync { monthly_kwh, roof_area_sqm, grid_type }
    AI-->>API: Recommendation, Plan, ExecutionLogs, ValidationResults
    API->>DB: Save AgentExecutionLog(s) + workflow result
    API->>DB: Set survey status: AnalysisComplete (or Failed)
    API-->>Homeowner: 200 OK { survey, workflowStatus }
```
> Note: the survey's `roofAreaSqm` at this stage is homeowner-reported and used only for *preliminary* sizing. It is re-measured by a technician during field inspection (Flow 4) and that measured value takes precedence for compliance evaluation.



## 4. Field Inspection & Grid Compliance Flow
```mermaid
sequenceDiagram
    autonumber
    actor Engineer as Senior Engineer / Admin
    actor Tech as Field Technician
    participant API as ASP.NET Core API
    participant DB as PostgreSQL
    participant AI as Agentic AI (Grid Compliance Agent)

    Engineer->>API: POST /api/field-jobs { surveyId, technicianId }
    API->>DB: Create FieldJob
    Engineer->>API: PUT /api/field-jobs/{jobId}/assign
    Tech->>API: POST /api/technician/{jobId}/check-in (geolocation)
    Tech->>API: PUT /api/technician/{jobId}/inspection (roof tilt/orientation, breaker rating, phase count, ...)
    Tech->>API: POST /api/technician/{jobId}/telemetry (Voc, Isc, Vmp, Imp, irradiance, grid voltage/frequency)
    Tech->>API: POST /api/technician/{jobId}/photos
    Tech->>API: POST /api/technician/{jobId}/submit
    API->>DB: Mark inspection submitted
    API->>API: Auto-trigger TriggerComplianceEvaluationAsync(jobId)
    API->>DB: Set FieldJob status: ComplianceProcessing
    API->>AI: ExecuteComplianceEvaluationAsync { gridType, phaseCount, breakerRating, roofAreaMeasured, telemetry... }
    alt AI service reachable
        AI-->>API: { gridCompliant, complianceStatus, riskLevel, violations, recommendations }
    else AI call fails
        API->>API: Fall back to deterministic local evaluator (logged as warning)
    end
    API->>DB: Save/update ComplianceAssessment
    API->>DB: Set FieldJob status: ComplianceComplete (or Failed)
    API-->>Engineer: 200 OK ComplianceAssessmentDto
```
> An engineer can also re-trigger evaluation directly via `POST /api/field-jobs/{jobId}/evaluate-compliance`, independent of the technician's original submit call.



## 5. Equipment Pricing & Reservation Flow
```mermaid
sequenceDiagram
    autonumber
    actor Inventory as Inventory Officer
    participant API as ASP.NET Core API
    participant DB as PostgreSQL
    participant AI as Agentic AI (Equipment Pricing Agent)
    participant FX as External Exchange-Rate API

    Inventory->>API: POST /api/inventory/proposals/{id}/price
    API->>DB: Verify proposal.status == Approved
    API->>DB: Select compatible active 500W panels (qty by kW) + inverter (rated >= system kW)
    API->>AI: PriceAsync { proposalId, recommendedKw, items[] }
    AI->>FX: Fetch current USD → LKR exchange rate
    FX-->>AI: rate + timestamp
    AI-->>API: PricingResult { status, exchangeRate, rateTimestamp, lines[], totalPriceLkr }
    API->>API: ValidatePricing() — re-derive every line total & compare against catalog (defense in depth)
    API->>DB: Save EquipmentQuote (status: VALIDATED, expires in 1 hour)
    API-->>Inventory: 200 OK quote

    Inventory->>API: POST /api/inventory/reserve { quoteId }
    API->>DB: Create InventoryReservation, increment ReservedQuantity (idempotent — no duplicate on replay)
    API-->>Inventory: 200 OK { status: "RESERVED" }

    opt Release
        Inventory->>API: POST /api/inventory/{quoteId}/release
        API->>DB: Decrement ReservedQuantity, set reservation status: RELEASED
        API-->>Inventory: 200 OK { status: "RELEASED" }
    end
```
> Quotes expire one hour after creation and reserve no stock until the explicit `/reserve` call — a quote alone does not hold inventory.
