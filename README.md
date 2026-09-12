# Smart Solar Installation & Grid Compliance Platform

SE3090 university project, group **2026-AI-17**. A working Sri Lankan solar-planning demonstration spanning customer surveys, field inspection, engineering approval and equipment procurement.

## What works

Web and mobile registration now require email OTP verification. Account & security provides OTP-protected password changes and account deletion, with session revocation. The web login has no demo-account shortcuts. Homeowners can create assessments, submit solar analysis and follow proposals from the web portal. Configure Gmail SMTP using [email verification setup](docs/EMAIL-VERIFICATION.md) before accepting registrations.

Flutter homeowners register, submit surveys and photos, request proposals and view equipment estimates. Technicians use device location, camera/gallery, inspection forms and measured readings. React staff review surveys, assign jobs, approve/reject/request revisions, manage suppliers and stock, calculate LKR prices and reserve/release equipment.

ASP.NET Core 8 is the only client gateway and owns JWT roles, EF Core/PostgreSQL persistence and transactions. Internal FastAPI/LangGraph specialists perform planning, sizing, compliance screening, safety checks and equipment pricing. These specialists use deterministic rules, not a hosted language model. The pricing workflow uses a real allowlisted exchange-rate API.

The product ends at approved equipment ready for installation planning. It does not commission installations or issue utility approval. See [Sri Lankan scope](docs/sri-lanka-scope.md).

## Local setup

Requirements: .NET 8 SDK, Node.js 22+, Python 3.11+, Flutter stable, Android SDK/JDK and a PostgreSQL/Neon database. Keep .env out of Git. Copy .env.example and set DATABASE_CONNECTION_STRING, JWT_KEY, JWT_ISSUER, JWT_AUDIENCE, AGENTIC_AI_BASE_URL=http://localhost:8000 and AGENTIC_AI_INTERNAL_KEY.

From the repository root:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r agentic-ai/requirements.txt
dotnet restore backend/SolarPlatform.sln
```

With DATABASE_CONNECTION_STRING available in the migration process, apply:

```powershell
dotnet ef database update --project backend/SolarPlatform.Api
```

The development API loads the root .env automatically; the design-time migration command needs the variable in its process environment. Never paste a connection string into source or command transcripts.

Start three terminals:

```powershell
# Repository root: internal AI
.\.venv\Scripts\python.exe -m uvicorn app.main:app --app-dir agentic-ai --host 127.0.0.1 --port 8000

# Repository root: API (0.0.0.0 allows a local emulator/phone to connect)
dotnet run --project backend/SolarPlatform.Api --urls http://0.0.0.0:5116

# frontend-web:
npm ci
npm run dev
```

Open http://localhost:5173. API documentation: http://localhost:5116/swagger. Health: http://localhost:5116/api/health. Development HTTP is intended for local demonstration.

In frontend-mobile:

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5116
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:5116
```

For a physical phone replace the emulator address with the PC's reachable LAN address. For hosting use an HTTPS API URL. See [handover](docs/deployment/RELEASE-HANDOVER.md) for Windows symlink notes and device verification.

## Demo accounts

All five seeded accounts use the development password Password@123:

- admin@smartsolar.local: administrator
- engineer@smartsolar.local: senior engineer
- technician@smartsolar.local: field technician
- homeowner@smartsolar.local: homeowner
- inventory@smartsolar.local: inventory officer

These are public demo credentials; replace/disable them before public deployment. New registrations receive only HOMEOWNER.

## Demonstration sequence

1. Register a homeowner in Flutter and submit a survey (600 kWh, 80 square metres is a useful synthetic example).
2. Engineer assigns a field job in React. Technician checks in, records observed values/readings and submits the inspection.
3. Homeowner opens the survey's proposal screen and requests a proposal.
4. Engineer reviews and records approve/reject/revise. Missing compliance evidence blocks approval. A requested revision is retained in history; a corrected inspection can support an updated proposal.
5. Inventory officer adds active 500 W panels and a sufficiently rated inverter, selects an approved proposal, calculates pricing and reserves equipment.
6. Homeowner refreshes equipment status. Staff may release stock; replaying a completed reservation does not duplicate it.

Equipment quotes expire after one hour and do not hold stock until reserved. Costs omit installation and taxes. Preliminary sizing uses 400 W panels; final catalog selection uses 500 W panels.

## Tests and evidence

```powershell
dotnet test backend/SolarPlatform.sln
# agentic-ai:
..\.venv\Scripts\python.exe -m pytest -q
# frontend-web:
npm test
npm run build
# frontend-mobile:
flutter analyze
flutter test
flutter build apk --debug
```

Set TEST_DATABASE_CONNECTION_STRING to run the isolated PostgreSQL migration/concurrency/rollback test. It uses a unique schema with an explicit isolation assertion; it does not delete project tables. Locally verified totals: 83 backend tests including PostgreSQL, 38 Python, 16 React and 14 Flutter. No hosted CI execution is claimed.

Run the full local HTTP demonstration only against a demo database:

```powershell
.\.venv\Scripts\python.exe scripts/smoke_workflow.py --output docs/testing/live-workflow-evidence.json
```

This creates labelled synthetic records and leaves them for review. The evidence file contains real HTTP statuses, timings, saved workflow state and exchange-rate results, with no tokens or passwords.

## Technical documentation

- [Inventory API](docs/api/inventory-api.md)
- [Inventory database and transaction design](docs/database/inventory-design.md)
- [Controlled pricing workflow](docs/agentic-ai/equipment-pricing-agent.md)
- [Connected workflow](docs/architecture/inventory-pricing-flow.md)
- [Phase 5 verification](docs/testing/phase-5-test-plan.md)
- [Architecture decision](docs/adr/ADR-006-inventory-transactions-and-tools.md)
- [AI assistance disclosure draft](docs/AI-USAGE.md)
- [Local release and hosting handover](docs/deployment/RELEASE-HANDOVER.md)

Earlier Phase 1-4 documents describe their implementation stages; this README and release handover describe current verified scope. Hosting remains deferred. Student names, contribution claims, reflections, signatures, deployment links and the demonstration video must be supplied by the group.
