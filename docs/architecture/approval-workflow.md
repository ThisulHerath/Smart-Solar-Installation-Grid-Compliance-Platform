# Engineering Proposal Approval Workflow Architecture

## Overview
This document details the end-to-end multi-agent workflow governing Engineering Proposal creation, Safety Guardrail evaluation, Deterministic Validation, and Human Senior Engineer Approval.

---

## Architectural Sequence

```mermaid
sequenceDiagram
    autonumber
    actor Homeowner
    participant API as ASP.NET Core API
    participant AI as Agentic AI (LangGraph)
    participant Guardrail as SafetyGuardrailAgent
    participant Validator as DeterministicProposalValidator
    participant DB as AppDbContext (SQL DB)
    actor Engineer as Senior Engineer

    Homeowner->>API: POST /api/proposals (surveyId)
    API->>DB: Load SolarSurvey + SiteInspection + Compliance
    API->>AI: POST /workflow/guardrail (GuardrailInput)
    AI->>Guardrail: Evaluate safety, kW threshold, risk level
    Guardrail-->>AI: GuardrailResult (advisory only)
    AI->>Validator: Validate rules (authoritative)
    Validator-->>AI: ValidationResult (final requiresApproval)
    AI-->>API: GuardrailWorkflowResult
    API->>DB: Persist EngineeringProposal (Status: PendingApproval)
    API-->>Homeowner: Proposal DTO (Status: PendingApproval)

    Engineer->>API: GET /api/proposals/pending
    API-->>Engineer: List of pending proposals
    Engineer->>API: POST /api/proposals/{id}/approve
    API->>Validator: Re-run deterministic checks
    API->>DB: Transaction: Update status to Approved + write ApprovalAuditLog
    DB-->>API: Commit
    API-->>Engineer: Updated Proposal DTO (Status: Approved)
```

---

## Governance Rules & Safety Principles

1. **No Automatic AI Approvals**: The AI agent (`SafetyGuardrailAgent`) **never** has the authority to approve a proposal. It produces advisory findings, risk assessments, and recommendations.
2. **Deterministic Overrides**: The `DeterministicProposalValidator` executes code-level rules outside the LLM context. If system capacity > 10kW or grid compliance is non-compliant, human approval is strictly mandatory regardless of AI output.
3. **Fail-Safe Default**: If the AI service is offline or throws an exception, the system defaults `requiresApproval = True` and `safetyStatus = REQUIRES_APPROVAL`.
4. **Audit Trail Immutability**: All approval, rejection, and revision decisions are recorded in `ApprovalAuditLogs` with user IDs, timestamps, and commentary.
