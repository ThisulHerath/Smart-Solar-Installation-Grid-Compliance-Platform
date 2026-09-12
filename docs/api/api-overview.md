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
- **`POST /api/auth/register/request-otp`**
  - Requests email verification; does not create a user.
  - Body: `{ "email", "password", "fullName", "phoneNumber" }`
- **`POST /api/auth/register`**
  - Verifies a one-time email code and creates a HOMEOWNER account.
  - Body: `{ "challengeId", "code" }`
- **`POST /api/auth/password/request-otp`** and **`POST /api/auth/password/confirm`**
  - Authenticated password change with email verification; invalidates previous sessions.
- **`POST /api/auth/account-deletion/request-otp`** and **`POST /api/auth/account-deletion/confirm`**
  - Authenticated deletion with email verification; removes account access and profile contacts while preserving project audit records.
  - See [email verification](../EMAIL-VERIFICATION.md) for Gmail setup, bodies and limits.
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
