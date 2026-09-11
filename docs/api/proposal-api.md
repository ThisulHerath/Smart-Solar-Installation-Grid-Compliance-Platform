# Engineering Proposal API Documentation

## Overview
Phase 4 introduces REST API endpoints for proposal creation, evaluation, senior engineer review (approval/rejection/revision), and homeowner status tracking.

---

## Base URL
`/api/proposals`

---

## Authorization Matrix

| Endpoint | Method | Allowed Roles | Description |
|---|---|---|---|
| `POST /` | `POST` | `HOMEOWNER`, `ADMINISTRATOR` | Initiates proposal creation workflow from a survey |
| `GET /` | `GET` | `SENIOR_ENGINEER`, `ADMINISTRATOR` | Lists all engineering proposals |
| `GET /pending` | `GET` | `SENIOR_ENGINEER`, `ADMINISTRATOR` | Lists proposals requiring engineer review |
| `GET /{id}` | `GET` | Authenticated Users | Gets full proposal details and audit history |
| `POST /{id}/approve` | `POST` | `SENIOR_ENGINEER`, `ADMINISTRATOR` | Approves a pending proposal |
| `POST /{id}/reject` | `POST` | `SENIOR_ENGINEER`, `ADMINISTRATOR` | Rejects a proposal (requires comment) |
| `POST /{id}/revise` | `POST` | `SENIOR_ENGINEER`, `ADMINISTRATOR` | Requests proposal revision (requires comment) |
| `GET /survey/{surveyId}` | `GET` | Authenticated Users | Fetches proposals associated with a specific survey |

---

## Endpoint Specifications

### 1. Create Engineering Proposal
`POST /api/proposals`

**Request Body:**
```json
{
  "solarSurveyId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "notes": "Homeowner requested maximum capacity array"
}
```

**Response (201 Created):**
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "solarSurveyId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "workflowId": "wf-guard-a1b2c3d4",
  "recommendedKw": 12.5,
  "panelCount": 30,
  "inverterSizeKw": 12.5,
  "estimatedCostLkr": 1400000.0,
  "gridComplianceStatus": "COMPLIANT",
  "riskLevel": "MEDIUM",
  "safetyStatus": "REQUIRES_APPROVAL",
  "proposalStatus": "PendingApproval",
  "requiresApproval": true,
  "recommendationSummary": "Safety evaluation identified system size 12.50kW exceeds 10kW threshold.",
  "createdAt": "2026-09-10T11:00:00Z",
  "updatedAt": "2026-09-10T11:00:00Z",
  "auditLogs": []
}
```

---

### 2. Approve Proposal
`POST /api/proposals/{id}/approve`

**Request Body:**
```json
{
  "comment": "System specs and main breaker capacity verified. Approved for grid connection."
}
```

**Response (200 OK):**
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "proposalStatus": "Approved",
  "auditLogs": [
    {
      "id": "98765432-10fe-dcba-9876-543210fedcba",
      "decision": "Approved",
      "comment": "System specs and main breaker capacity verified. Approved for grid connection.",
      "userId": "e4f5a6b7-8901-2345-6789-abcdef012345",
      "timestamp": "2026-09-10T11:15:00Z"
    }
  ]
}
```

---

### 3. Reject Proposal
`POST /api/proposals/{id}/reject`

**Request Body:**
```json
{
  "comment": "Inverter location violates safety clearance. Site unviable."
}
```

---

### 4. Request Revision
`POST /api/proposals/{id}/revise`

**Request Body:**
```json
{
  "comment": "Please downsize array to 8kW to fit single-phase export limit."
}
```
