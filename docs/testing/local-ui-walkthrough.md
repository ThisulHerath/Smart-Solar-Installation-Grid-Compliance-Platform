# Local UI walkthrough

For exact inputs, expected results and all five roles, follow the [complete manual acceptance guide](manual-acceptance-guide.md). Engineers and administrators can now assign a technician from **Field Operations → Assign technician**, using survey/technician dropdowns, priority and an optional visit time.

## Open the applications

- Web portal: http://localhost:5173
- Flutter app in Microsoft Edge: http://localhost:5180
- API health: http://localhost:5116/api/health
- API documentation: http://localhost:5116/swagger

For this local session, the Solar AI service uses http://127.0.0.1:8001 because port 8000 is occupied by another project. The private root `.env` has been updated to use port 8001.

## Manual login credentials

These seeded development accounts remain available. There are no account-fill shortcuts in the login screens. All five use `Password@123`:

- Administrator: `admin@smartsolar.local`
- Senior engineer: `engineer@smartsolar.local`
- Field technician: `technician@smartsolar.local`
- Homeowner: `homeowner@smartsolar.local`
- Inventory officer: `inventory@smartsolar.local`

## Check the new UI

1. Open the web root while signed out. Expect the public cream-and-green landing page, readable headings, and working navigation links.
2. Choose **Explore service**, or enter `/dashboard`, `/profile`, or `/inventory` directly. Expect the login page and empty email/password fields.
3. Enter the administrator credentials manually. Expect the dashboard with live totals, navigation tabs, and workspace cards.
4. Open **My profile**. Expect the signed-in user's name, email, phone, role, and membership date. Open **Account & security** to reach the separate security controls. The profile is a details view; it does not offer unsupported profile edits.
5. Open each workspace card. Expect the corresponding surveys, field jobs, approvals, inventory, profile, or security page. The current navigation tab should be highlighted.
6. Log out, then try to open `/profile` again. Expect login to be required.
7. Open the Flutter app in Edge. Expect a public welcome page. Choose **Log in** and enter the homeowner credentials. Expect the homeowner workspace and solar-survey action. Open the profile icon and check the account details and security link.
8. In Flutter, sign out from the profile. Expect the welcome page. Sign in as a technician to check the site-jobs action.
9. Choose registration on either client using an inbox you control. Expect a verification email, an error for an incorrect code, and successful registration only with a valid code. Real email delivery must be checked separately; the automated tests use a test mailbox.
10. Resize the web portal to phone width. Expect a menu button and stacked cards. Test camera and GPS on an actual phone separately; an Edge preview cannot establish native-device behavior.

## Check the project workflow

Use labelled demo data in the development database:

1. Homeowner: create an assessment with a property address, monthly electricity usage, and roof area; add site photos.
2. Engineer: review the survey and assign a technician.
3. Technician in Flutter: open the job, check in, record site measurements and photos, and submit the inspection.
4. Homeowner: request the proposal once the required assessment/inspection steps are ready.
5. Engineer: review the proposal and approve it.
6. Inventory officer: generate an equipment quote, reserve equipment, and verify stock changes.
7. Homeowner: refresh the project and confirm the equipment status is visible.

## Start again later

Open separate PowerShell terminals at the repository root:

```powershell
# AI service
.\.venv\Scripts\python.exe -m uvicorn app.main:app --app-dir agentic-ai --host 127.0.0.1 --port 8001
```

```powershell
# Backend
dotnet run --project backend/SolarPlatform.Api --launch-profile http --urls http://0.0.0.0:5116
```

```powershell
# Web
cd frontend-web
npm run dev
```

```powershell
# Flutter in Microsoft Edge
cd frontend-mobile
flutter run -d edge --web-port 5180 --dart-define=API_BASE_URL=http://localhost:5116
```

Do not start a duplicate server on an already occupied port. Use Ctrl+C in its terminal to stop a server before restarting it.
