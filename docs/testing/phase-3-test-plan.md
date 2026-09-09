# Phase 3 Test Plan & Validation Matrix

## 1. Golden Compliance Test Cases

The compliance evaluation engine is validated against 5 canonical golden test cases:

| Case # | Scenario Description | Inputs | Expected Compliance Status | Expected Risk | Violations & Recommendations |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Case 1** | **Ideal Single-Phase Installation** | 230V, 50Hz, 40A Breaker, Inverter Suitable, Voc=450V, Isc=11.5A | `COMPLIANT` | `LOW` | 0 violations. Passed all checks. |
| **Case 2** | **Over-Voltage Violation** | 258V Single-Phase (>243.8V ceiling), 50Hz, Inverter Suitable | `NON_COMPLIANT` | `HIGH` | Over-voltage violation detected. Recommend AVR / utility tap adjustment. |
| **Case 3** | **Frequency Deviation Violation** | 230V, 48.8Hz (<49.5Hz floor), Inverter Suitable | `NON_COMPLIANT` | `HIGH` | Frequency outside synchronous statutory limits. |
| **Case 4** | **Unsuitable Inverter Location** | 230V, 50Hz, Inverter Suitable = False | `NON_COMPLIANT` | `HIGH` | Inverter location thermal/fire hazard. Recommend relocation. |
| **Case 5** | **Under-rated Service Breaker** | 230V, 50Hz, Main Breaker = 20A (<30A min) | `NON_COMPLIANT` / `CONDITIONAL` | `MEDIUM` | Breaker undersized for solar export backfeed. Recommend 32A/40A upgrade. |

---

## 2. Test Execution Commands & Verification

### 2.1 Backend (.NET Unit Tests)
```bash
dotnet test backend/SolarPlatform.Tests/SolarPlatform.Tests.csproj
```
**Results**: 38 passed, 0 failed.

### 2.2 Python Agentic AI Tests
```bash
python -m unittest discover -s agentic-ai/tests
```
**Results**: 14 passed, 0 failed.

### 2.3 React Frontend Tests
```bash
cd frontend-web && npx vitest run
```
**Results**: 10 passed across 2 test suites.

### 2.4 Flutter Mobile Tests
```bash
cd frontend-mobile && flutter test
```
**Results**: 10 passed, 0 failed.
