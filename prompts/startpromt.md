Smart-Solar-Installation-Grid
You are the lead software architect and senior full-stack engineer for our SE3090 Software Engineering Frameworks Assignment 1 project.

==================================================
PROJECT
==================================================

Project Name:

Smart Solar Installation & Grid Compliance Platform

This is a university assessed project.

The official SE3090 Assignment 1 specification is the source of truth.

The project must be understandable, explainable and maintainable by the students.

Do not generate:
- unexplained magic code
- unnecessary abstractions
- fake functionality
- fake test results
- fake deployment results
- unnecessary dependencies
- placeholder functionality presented as complete
- copied structures from the AutoCare sample scenario

The AutoCare example is guidance only. Our project is an original Smart Solar domain.

==================================================
MANDATORY TECHNOLOGY STACK
==================================================

Backend:
- C#
- ASP.NET Core Web API

ORM:
- Entity Framework Core
- Npgsql PostgreSQL provider

Database:
- Neon Managed PostgreSQL

Web:
- React
- TypeScript
- React Router
- justified state management

Mobile:
- Flutter
- Dart
- justified state management

Agentic AI:
- Python
- FastAPI
- Pydantic
- LangGraph

Version Control:
- Git
- GitHub

CI:
- GitHub Actions

Hosting target:
- React → Vercel
- ASP.NET Core API → Render
- Agentic AI → Render
- Database → Neon PostgreSQL
- Flutter → Android APK

==================================================
DATABASE DECISION
==================================================

IMPORTANT:

Neon is the project's PostgreSQL database provider.

Do NOT create a separate local PostgreSQL database as the primary database.

The application must use Neon Managed PostgreSQL.

Use:

ASP.NET Core
    ↓
Entity Framework Core
    ↓
Npgsql
    ↓
Neon PostgreSQL

React and Flutter must never connect directly to Neon.

Only ASP.NET Core may access the database.

The database must remain standard PostgreSQL and must be implemented using Entity Framework Core migrations.

==================================================
NEON PROJECT SETUP
==================================================

The Neon project already exists.

Neon Project ID:

steep-band-56603943

Neon branch:

production

Before modifying project code, inspect the repository and determine what already exists.

Then configure the current working directory with the Neon project.

Use the following Neon setup process provided by Neon:

1. Install/login:

npm i -g neon@latest
neon login

2. Install Neon skills:

neon skills -y

3. Set up Neon MCP:

neon mcp -y

4. Link the current repository to the existing Neon project:

neon link --project-id steep-band-56603943 --branch production -y

5. Initialize Neon configuration:

neon config init

6. If neon.ts is created or already exists, use the following configuration:

import { defineConfig } from "@neon/config/v1";

export default defineConfig({
  auth: true,
});

7. Deploy Neon configuration if required:

neon deploy

IMPORTANT:
Do not create a different Neon project.
Do not create a different production branch.
Do not replace the existing Neon project ID.
Do not expose Neon credentials in source control.

After Neon setup, verify that the project is actually linked and usable.

If any Neon CLI command fails:
- inspect the error
- determine the cause
- fix only what is necessary
- do not invent a successful result
- report exactly what failed if it cannot be fixed

==================================================
ENVIRONMENT VARIABLES
==================================================

Use environment variables for all secrets and environment-specific configuration.

At minimum prepare:

DATABASE_CONNECTION_STRING=
JWT_KEY=
JWT_ISSUER=
JWT_AUDIENCE=
AGENTIC_AI_BASE_URL=
AGENTIC_AI_INTERNAL_KEY=

For local development, the DATABASE_CONNECTION_STRING must point to Neon PostgreSQL.

Do not commit:
- Neon database password
- Neon connection string containing credentials
- JWT secrets
- API keys
- AI provider secrets

Create:

.env.example

The example file must contain variable names only, or safe placeholder values.

The real .env file must be ignored by Git.

==================================================
EXISTING REPOSITORY
==================================================

Current repository structure:

Smart-Solar-Installation-Grid/
├── .vscode/
├── agentic-ai/
├── backend/
├── database/
├── frontend-mobile/
├── frontend-web/
├── README.md
└── docker-compose.yml

Do NOT destroy or replace the existing repository structure without a good reason.

Inspect the repository first.

Determine:
- which folders are empty
- which projects already exist
- which configuration files already exist
- whether package managers are already initialized
- whether Docker is configured
- whether any .NET/React/Flutter/Python work already exists

Preserve useful work.

==================================================
PHASE 1 OBJECTIVE
==================================================

Implement ONLY the project foundation.

Do not build the complete business system yet.

The objective is to make all architectural layers runnable and establish conventions for future development.

At the end of Phase 1, the following architecture must work:

React
   |
   | REST + JWT
   ↓
ASP.NET Core API
   |
   ├────→ Neon PostgreSQL
   |
   └────→ Python FastAPI / LangGraph
                 |
                 ↓
           Agentic AI foundation

Flutter
   |
   | REST + JWT
   ↓
ASP.NET Core API

IMPORTANT:

React and Flutter communicate ONLY with ASP.NET Core.

React and Flutter must NOT:
- connect directly to Neon
- connect directly to PostgreSQL
- call the Python Agentic AI service directly

ASP.NET Core is the authoritative public API.

Python Agentic AI is an internal service called by ASP.NET Core.

==================================================
PHASE 1 DELIVERABLES
==================================================

1. Repository structure
2. Neon database connection
3. ASP.NET Core foundation
4. Entity Framework Core foundation
5. JWT authentication foundation
6. Role-based authorization foundation
7. React foundation
8. Flutter foundation
9. Agentic AI service foundation
10. ASP.NET Core → Agentic AI integration
11. Docker development configuration where useful
12. GitHub Actions CI
13. Basic tests
14. Documentation
15. Architecture Decision Records

==================================================
1. REPOSITORY STRUCTURE
==================================================

Use this structure where appropriate:

/
├── .github/
│   └── workflows/
│       ├── backend-ci.yml
│       ├── web-ci.yml
│       ├── mobile-ci.yml
│       └── ai-ci.yml
│
├── .vscode/
│
├── agentic-ai/
│   ├── app/
│   │   ├── agents/
│   │   │   ├── planner_agent.py
│   │   │   ├── grid_compliance_agent.py
│   │   │   ├── equipment_pricing_agent.py
│   │   │   └── safety_guardrail_agent.py
│   │   ├── tools/
│   │   ├── workflow/
│   │   ├── validators/
│   │   ├── schemas/
│   │   └── main.py
│   ├── tests/
│   ├── requirements.txt
│   ├── .env.example
│   └── Dockerfile
│
├── backend/
│   ├── SolarPlatform.Api/
│   │   ├── Controllers/
│   │   ├── DTOs/
│   │   ├── Models/
│   │   ├── Data/
│   │   ├── Services/
│   │   ├── Authentication/
│   │   ├── Middleware/
│   │   ├── Validators/
│   │   ├── Integrations/
│   │   └── Program.cs
│   │
│   └── tests/
│
├── database/
│   ├── schema/
│   ├── seed/
│   └── README.md
│
├── frontend-web/
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   ├── layouts/
│   │   ├── routes/
│   │   ├── services/
│   │   ├── hooks/
│   │   ├── store/
│   │   ├── types/
│   │   └── utils/
│   └── tests/
│
├── frontend-mobile/
│   ├── lib/
│   │   ├── screens/
│   │   ├── widgets/
│   │   ├── services/
│   │   ├── models/
│   │   ├── providers/
│   │   ├── routes/
│   │   └── utils/
│   └── test/
│
├── docs/
│   ├── architecture/
│   ├── database/
│   ├── api/
│   ├── agentic-ai/
│   ├── testing/
│   ├── deployment/
│   └── adr/
│
├── .env.example
├── .gitignore
├── docker-compose.yml
└── README.md

Keep the structure simple.

Do not create folders that are not needed.

==================================================
2. NEON DATABASE + EF CORE
==================================================

Configure ASP.NET Core to use Neon PostgreSQL.

Use:

Microsoft.EntityFrameworkCore
Npgsql.EntityFrameworkCore.PostgreSQL
Microsoft.EntityFrameworkCore.Design

Create the DbContext.

Use dependency injection.

Read the connection string from configuration/environment variables.

Do NOT hard-code credentials.

Create only foundation entities in Phase 1.

At minimum:

User
Role
UserRole

Include:

Id
CreatedAt
UpdatedAt

Use:
- primary keys
- foreign keys
- constraints
- suitable PostgreSQL types

Create an EF Core migration.

Apply the migration to the Neon production branch only when explicitly appropriate.

Do not create a second database.

Document the Neon database setup.

==================================================
3. DEVELOPMENT DATABASE SAFETY
==================================================

Because Neon is being used as the managed database, avoid uncontrolled schema changes.

Use EF Core migrations.

Document:

dotnet ef migrations add InitialCreate
dotnet ef database update

Do not automatically delete or recreate the database.

Do not run destructive SQL.

Do not drop production tables.

Before any destructive database operation, stop and request explicit confirmation.

==================================================
4. USER ROLES
==================================================

Create these development roles:

HOMEOWNER
FIELD_TECHNICIAN
SENIOR_ENGINEER
INVENTORY_OFFICER
ADMINISTRATOR

User authentication must support role-based authorization.

Create development test accounts only.

Passwords must be securely hashed.

Never store plaintext passwords.

Never expose password hashes to API responses.

==================================================
5. ASP.NET CORE FOUNDATION
==================================================

Implement:

- Controllers
- DTOs
- Application/service layer
- Entity Framework Core
- Dependency Injection
- Authentication
- Authorization
- Configuration
- Global exception handling
- Structured logging
- CORS
- Swagger/OpenAPI
- Async operations where appropriate

Create:

GET /api/health

Return structured dependency information.

Example:

{
  "status": "healthy",
  "database": "connected",
  "agenticAi": "available"
}

If Neon is unavailable:
- do not crash
- report controlled dependency status

If Agentic AI is unavailable:
- do not crash
- report controlled dependency status

Do not expose secrets or stack traces.

==================================================
6. JWT AUTHENTICATION
==================================================

Create:

POST /api/auth/register
POST /api/auth/login
GET /api/auth/me

Login returns:
- JWT access token
- user ID
- role
- basic user information

Use JWT authentication.

Use role-based authorization.

Create architecture verification endpoints:

GET /api/admin/test

ADMIN only.

GET /api/engineer/test

SENIOR_ENGINEER only.

These are temporary verification endpoints for Phase 1.

Do not implement fake business logic.

Use DTO validation.

Return correct HTTP status codes.

==================================================
7. REACT FOUNDATION
==================================================

Use:
- React
- TypeScript
- functional components
- Hooks
- React Router
- reusable components
- justified state management

Select an appropriate state management strategy.

Document the decision in an ADR.

Implement:

Login page
Protected routes
Dashboard shell
Navigation
Logout
Current user
Unauthorized page
404 page
Loading states
Error states

Create API service layer.

Use:

VITE_API_BASE_URL

Example:

VITE_API_BASE_URL=http://localhost:5000

The React application may communicate only with ASP.NET Core.

It must never call Neon directly.

It must never call Python Agentic AI directly.

==================================================
8. FLUTTER FOUNDATION
==================================================

Use:
- Flutter
- Dart
- reusable widgets
- routing
- justified state management
- API service
- authentication service
- secure token storage

Implement:

Login
Protected app shell
Home screen
Navigation
Logout
Current user
Error handling
Loading states

Use a configuration mechanism for the API URL.

Local example:

http://localhost:5000

Later production example:

https://<deployed-api-domain>

Do not hard-code production URLs throughout the code.

Prepare the architecture for:
- camera
- GPS
- image/file upload
- notifications

Do not implement the full solar survey yet.

==================================================
9. AGENTIC AI FOUNDATION
==================================================

Create Python FastAPI service.

Use:
- Python
- FastAPI
- Pydantic
- LangGraph

Create:

GET /health

Create initial workflow state.

Include:

workflow_id
customer_id
objective
input_data
plan
current_step
completed_steps
tool_results
validation_results
errors
approval_status
final_outcome
execution_logs

Create interfaces/stubs for:

PlannerAgent
GridComplianceAgent
EquipmentPricingAgent
SafetyGuardrailAgent

Each agent must have:
- unique responsibility
- structured input
- structured output
- controlled tool permissions
- visible participation in the workflow

Do NOT implement the full solar business logic yet.

Create a LangGraph workflow skeleton:

objective
→ planning
→ delegation
→ execution placeholder
→ validation placeholder
→ result

Do not pretend that the complete Agentic AI workflow is finished.

==================================================
10. ASP.NET CORE → AGENTIC AI
==================================================

Create:

IAgenticAiService

Implementation:

AgenticAiService

Configure:

AGENTIC_AI_BASE_URL
AGENTIC_AI_INTERNAL_KEY

Create:

POST /api/agent-workflows/test

Request:

{
  "objective": "Test solar workflow"
}

ASP.NET Core sends this internally to FastAPI.

FastAPI returns structured JSON.

ASP.NET Core returns the structured result to the client.

React and Flutter must not call FastAPI directly.

Implement:
- timeout
- retry policy where appropriate
- controlled failure
- logging
- safe failure response

==================================================
11. DOCKER
==================================================

Review the existing docker-compose.yml.

Do NOT introduce a local PostgreSQL database as a replacement for Neon.

Do NOT duplicate the Neon database locally as the project's primary database.

Docker may be used for:
- Agentic AI service
- local service orchestration
- other application services where useful

Flutter does not need to run inside Docker.

Do not store secrets inside docker-compose.yml.

==================================================
12. GITHUB ACTIONS
==================================================

Create:

.github/workflows/backend-ci.yml

It must:
- checkout
- install/setup .NET
- restore
- build
- test

Trigger:
- push
- pull_request

Do not create fake deployment results.

Additional workflows may be added only if they are reliable.

==================================================
13. TESTING
==================================================

Create meaningful foundation tests.

Backend:
- health endpoint
- login success
- login failure
- validation
- authorization
- protected endpoints
- AI service failure handling

Database:
- EF Core model validation
- migration verification where appropriate

Agentic AI:
- health
- Pydantic validation
- invalid state rejection
- workflow skeleton

React:
- login page
- protected route

Flutter:
- authentication state
- basic login/widget test where practical

Do not chase high coverage purely for a percentage.

==================================================
14. DOCUMENTATION
==================================================

README.md must include:

- project overview
- problem statement
- technology stack
- architecture
- repository structure
- Neon setup
- Neon project/branch configuration
- environment variables
- local setup
- how to start Agentic AI
- how to start ASP.NET Core
- how to start React
- how to start Flutter
- how to run migrations
- how to run tests
- Swagger URL
- health endpoint
- test accounts
- current Phase 1 limitations

Create:

docs/architecture/system-architecture.md

docs/architecture/data-flow.md

docs/database/database-design.md

docs/api/api-overview.md

docs/agentic-ai/agent-architecture.md

docs/testing/testing-strategy.md

docs/deployment/deployment-plan.md

==================================================
15. ADRs
==================================================

Create:

ADR-001 React State Management

ADR-002 Flutter State Management

ADR-003 Agentic AI Framework and LangGraph Orchestration

ADR-004 Neon PostgreSQL + EF Core Database Strategy

ADR-005 Cloud Deployment Architecture

Each ADR should contain:

Context
Options considered
Decision
Consequences

Do not write generic filler.

==================================================
16. SECURITY
==================================================

Implement foundation-level security:

- JWT authentication
- role-based authorization
- password hashing
- input validation
- CORS restriction
- environment variables
- secure configuration
- no secrets in Git
- controlled errors
- API request validation

Do not store:
- passwords
- tokens
- API keys
- unnecessary sensitive information

Do not expose secrets in logs.

==================================================
17. DO NOT IMPLEMENT IN PHASE 1
==================================================

Do NOT fully implement:

- solar sizing
- roof calculations
- CEB/LECO compliance rules
- field telemetry
- inventory management
- utility filing
- quotations
- exchange-rate business logic
- approval business workflow
- complete four-agent workflow
- production deployment

Only establish the foundation and interfaces for these.

==================================================
18. PHASE 1 ACCEPTANCE CRITERIA
==================================================

Phase 1 is complete only when:

[ ] Neon project is linked successfully
[ ] Neon production branch is configured
[ ] ASP.NET Core connects to Neon PostgreSQL
[ ] EF Core migration is created
[ ] EF Core migration can be applied
[ ] Foundation tables exist
[ ] Roles exist
[ ] Seed development users exist
[ ] JWT login works
[ ] JWT protected endpoint works
[ ] Role authorization works
[ ] /api/health works
[ ] Swagger works
[ ] React starts
[ ] React login works
[ ] React protected route works
[ ] React uses ASP.NET Core only
[ ] Flutter starts
[ ] Flutter login architecture works
[ ] Flutter token storage works
[ ] Flutter uses ASP.NET Core only
[ ] FastAPI starts
[ ] FastAPI /health works
[ ] LangGraph foundation exists
[ ] ASP.NET Core can call FastAPI internally
[ ] AI service failure is handled safely
[ ] Backend tests pass
[ ] GitHub Actions passes
[ ] .env.example exists
[ ] No secrets are committed
[ ] README is updated
[ ] Architecture documentation exists
[ ] ADRs exist

==================================================
19. IMPORTANT OPERATING RULE
==================================================

Before modifying the repository:

1. Inspect the entire current repository structure.
2. Inspect important existing configuration files.
3. Inspect existing project files.
4. Identify conflicts.
5. Identify missing components.
6. Report what you found.
7. Then make the minimum necessary changes.

Do not blindly recreate projects that already exist.

==================================================
20. DATABASE SAFETY RULE
==================================================

This project uses Neon PostgreSQL.

Never:
- delete the Neon project
- delete the production branch
- drop the entire database
- reset the database destructively
- replace Neon with local PostgreSQL

without explicit approval.

Use EF Core migrations for schema evolution.

==================================================
21. AFTER IMPLEMENTATION
==================================================

Run actual verification.

Run:
- backend build
- backend tests
- frontend build/test where available
- Flutter analyze/test where available
- Python tests
- Neon connectivity verification

Fix real errors.

Then report:

A. Existing repository state before changes
B. Files created
C. Files modified
D. Neon setup status
E. Database schema created
F. Architecture summary
G. Commands required to run the system
H. Test results
I. GitHub Actions status
J. Known issues
K. Phase 1 acceptance checklist
L. Recommended Phase 2 work

Do not claim a feature works unless you actually tested it.

Do not move to Phase 2 automatically.

STOP after Phase 1.