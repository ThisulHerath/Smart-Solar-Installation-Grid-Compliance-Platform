# Testing Strategy

## Overview
The testing suite verifies all foundational layers: API, security, data mapping, AI state transitions, web UI bundling, and mobile model integrity.

## Test Suites

### 1. Backend (.NET 8 xUnit)
- **Project**: `backend/SolarPlatform.Tests`
- **Coverage**:
  - `AuthServiceTests`: Registration, login validation, password verification, duplicate email rejections.
  - `JwtTokenServiceTests`: Token creation, claims inspection, expiration validation.
  - `HealthControllerTests`: Dependency probe formatting, graceful degradation when AI or DB is offline.
  - `AuthorizationEndpointTests`: Role-based route authorization.
  - `AgenticAiServiceTests`: Typed HTTP client error resilience and safe fallbacks.
- **Run Command**:
  ```bash
  dotnet test backend/SolarPlatform.sln
  ```

### 2. Agentic AI (Python Pytest / Unittest)
- **Project**: `agentic-ai/tests`
- **Coverage**:
  - Agent interface executions (Planner, Grid, Pricing, Safety).
  - Pydantic model validation.
  - LangGraph StateGraph execution lifecycle.
- **Run Command**:
  ```bash
  python -m unittest discover -s agentic-ai/tests -p "test_*.py"
  ```

### 3. Frontend Web (React + Vite + TypeScript)
- **Project**: `frontend-web`
- **Coverage**:
  - TypeScript strict type checks.
  - Vite production bundle validation.
- **Run Command**:
  ```bash
  npm --prefix frontend-web run build
  ```

### 4. Frontend Mobile (Flutter Test)
- **Project**: `frontend-mobile`
- **Coverage**:
  - Dart model deserialization tests.
- **Run Command**:
  ```bash
  flutter test
  ```
