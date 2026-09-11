# Phase 4 Test Plan & Verification Strategy

## Overview
This document outlines the test strategy, golden test cases, automated test coverage, and verification results for Phase 4 (Engineering Proposals, AI Safety Guardrails, and Senior Engineer Approvals).

---

## Test Execution Summary

| Suite | Technology | Total Tests | Status |
|---|---|---|---|
| Backend Domain & API | C# xUnit / Moq / EF Core InMemory | 60 | **PASSED** |
| Agentic AI Workflows | Python `unittest` / Pydantic | 18 | **PASSED** |
| **Total Test Suite** | | **78** | **ALL PASSED** |

---

## Golden Test Cases

### GC1: Recommended kW = 5.0, Compliant Grid
- **Inputs**: 5.0 kW system, COMPLIANT grid status, low risk.
- **Expected Outcome**: `requires_approval = False`, `safety_status = SAFE`.

### GC2: Recommended kW = 12.5, Compliant Grid
- **Inputs**: 12.5 kW system (> 10.0 kW threshold), COMPLIANT grid status.
- **Expected Outcome**: `requires_approval = True`, `proposalStatus = PendingApproval`.

### GC3: Recommended kW = 6.0, Non-Compliant Grid
- **Inputs**: 6.0 kW system, NON_COMPLIANT grid status (over-voltage).
- **Expected Outcome**: `requires_approval = True`, `proposalStatus = PendingApproval`.

### GC4: AI Bypass Override
- **Inputs**: AI output mock claims `requires_approval = False`, but kW = 15.0.
- **Expected Outcome**: `DeterministicProposalValidator` overrides AI decision, forces `requires_approval = True`, records `override_reason`.

### GC5: State Machine Enforcement
- **Inputs**: Attempting to approve a `Draft` proposal.
- **Expected Outcome**: `InvalidOperationException` thrown with 400 Bad Request.

### GC6: Transaction Rollback on Exception
- **Inputs**: Exception during approval database write.
- **Expected Outcome**: DbContext transaction rolls back; proposal remains `PendingApproval`, no orphan audit logs.
