# Member 1 — Customer assessment and solar sizing

Owns named homeowner surveys, property details and map location, electricity and roof inputs, survey images, survey lifecycle, and the initial solar-size recommendation.

- Backend: `backend/SolarPlatform.Api/Features/Assessment`
- React: `frontend-web/src/features/assessment`
- Flutter: `frontend-mobile/lib/features/assessment`
- AI: `agentic-ai/app/features/assessment`
- Backend tests: `backend/SolarPlatform.Tests/Features/Assessment`

The `SolarSizingAgent` receives validated survey facts and returns a structured recommendation. The surrounding workflow preserves deterministic input/output contracts so the feature runs without a paid model API.

Demo: create a survey with a clear project name, choose the property on the map, enter roof and usage data, upload evidence, save/reopen it, and show the sizing result plus workflow trace.
