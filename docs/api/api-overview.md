# REST API Overview

The ASP.NET Core API provides the authoritative REST endpoints for Web and Mobile clients.

## Endpoints

### 1. Health & Dependency Probing
- **`GET /api/health`**
  - Public endpoint.
  - Returns structured dependency status for Neon PostgreSQL and Agentic AI.
  - Response:
    ```json
    {
      "status": "healthy",
      "database": "connected",
      "agenticAi": "available",
      "environment": "Development",
      "timestamp": "2026-09-07T14:00:00Z"
    }
    ```

### 2. Authentication
- **`POST /api/auth/register`**
  - Registers a new user.
  - Body: `{ "email", "password", "fullName", "phoneNumber", "role" }`
- **`POST /api/auth/login`**
  - Authenticates credentials and returns JWT bearer token.
  - Body: `{ "email", "password" }`
  - Response: `{ "token", "tokenType": "Bearer", "expiresIn": 3600, "user": { ... } }`
- **`GET /api/auth/me`**
  - Requires `Authorization: Bearer <token>`
  - Returns current user profile and assigned roles.

### 3. Agentic AI Workflows
- **`POST /api/agent-workflows/test`**
  - Internal orchestration forwarding to Python FastAPI.
  - Body: `{ "objective": "..." }`
  - Returns multi-agent execution steps, plan, and validation logs.

### 4. Role-Restricted Verification Endpoints
- **`GET /api/admin/test`** &rarr; Restricted to `ADMINISTRATOR`
- **`GET /api/engineer/test`** &rarr; Restricted to `SENIOR_ENGINEER`
