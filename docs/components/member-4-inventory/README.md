# Member 4 — Inventory, pricing, and procurement

Owns equipment catalog management, search and stock status, engineer inventory requests, approved-proposal selection, price calculation, exchange-rate handling, reservation, release, and procurement presentation.

- Backend: `backend/SolarPlatform.Api/Features/Inventory`
- React: `frontend-web/src/features/inventory`
- Flutter: `frontend-mobile/lib/features/inventory`
- AI: `agentic-ai/app/features/inventory`
- Backend tests: `backend/SolarPlatform.Tests/Features/Inventory`

The `EquipmentPricingAgent` produces a structured equipment estimate. `ExchangeRateTool` supplies the conversion input, while independent arithmetic and stock checks prevent an agent-generated value from being trusted without verification.

Demo: select an approved proposal by customer/project name, show its engineer inventory request, calculate the itemized LKR estimate, inspect workflow stages, reserve stock, verify availability changes, and release the reservation.
