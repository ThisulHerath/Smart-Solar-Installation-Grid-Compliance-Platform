# 2026-AI-17 local release handover

The local release includes ASP.NET API, React staff portal, Flutter Android app, internal Python workflows, Neon migration, inventory/pricing, stock reservation, tests and technical documentation. Hosting was deferred by the group. No live deployment or final university submission is claimed.

## Run locally

September 12 account update: apply `AddEmailVerification`, configure Gmail App Password delivery as described in [email verification setup](../EMAIL-VERIFICATION.md), and use `/register` for new verified homeowner accounts. Both clients now provide account security actions. The latest account-update test evidence is in `docs/testing/account-security-verification.md`.

Keep the repository .env private. Start the internal Python service, then the API, then React. See the root README for exact commands. Demo credentials are listed there. Open http://localhost:5173 and http://localhost:5116/swagger.

The supplied debug APK targets the Android emulator's http://10.0.2.2:5116. For a phone on the same trusted local network, rebuild with --dart-define=API_BASE_URL=http://YOUR_PC_LAN_IP:5116. The API must listen on 0.0.0.0 and the device must be able to reach it. Do not silently disable the firewall. Android asks for location access only when a technician requests check-in. Camera/gallery are user-selected.

## Hosting later

- Use the API Dockerfile with backend/SolarPlatform.Api as build context. Configure ASPNETCORE_URLS=http://0.0.0.0:5000 and the environment variables from .env.example.
- Run migrations using the private Neon connection before deploying a new API. Preserve backups and inspect migration scripts.
- Host the internal Python service on a private network; configure AGENTIC_AI_BASE_URL and matching AGENTIC_AI_INTERNAL_KEY. Do not put either key in a client bundle.
- Build React with VITE_API_BASE_URL set to the hosted HTTPS API. Set CORS_ALLOWED_ORIGINS on the API to the exact web origin. vercel.json provides SPA route fallback.
- Set ENABLE_SWAGGER=true only when evaluator API documentation is intended to be available.
- Replace or disable published demonstration accounts before a public launch. Their credentials are intentionally public development fixtures.
- Configure durable, private file storage and authorized image delivery before accepting real bills or site photos. The current local upload directory uses static file serving and is for demo data.
- Build a release APK with the HTTPS API URL and the group's signing configuration. The provided artifact is debug-signed for demonstration.
- Verify public URLs, health, Swagger, mobile connectivity, CI, backups and evaluator access. Record real deployment links and screenshots.

## University submission work owned by the group

Complete student names/IDs/component ownership, real commit/PR evidence, personal reflections and signatures. Record the ten-minute video, add accessible hosted URLs and merge the written work into one consolidated PDF. The technical handover draft is not a completed signed submission. Follow the assignment's naming convention and evaluator access dates.

## Known limits

No physical-device GPS/camera run is claimed. Native permissions and real sensor behaviour need a device check. The desktop Flutter target can require Windows Developer Mode for symlinks; Android builds succeed with resolved dependencies and --no-pub in this environment. Dependency deprecation/build warnings are recorded; none blocked the delivered build. Hard process termination can leave a non-reservable PROCESSING quote; request a fresh quote. Installation commissioning and utility submission are outside the implemented workflow.
