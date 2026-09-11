# Equipment pricing workflow

The internal FastAPI POST /workflow/equipment-pricing requires X-Internal-Key. React and Flutter call only ASP.NET; Python never writes PostgreSQL.

LangGraph runs Requirements -> ExchangeRateTool -> EquipmentPricingAgent -> PricingValidator -> InventoryAvailability -> Format. Pydantic rejects extra fields and invalid identifiers, capacities, quantities and non-finite currency values. The planner, sizing, compliance, safety and pricing specialists are deterministic domain agents; no hosted language model or LLM API key is used. Do not describe the application as an LLM-powered autonomous installer.

ASP.NET selects available, active 500 W panels and an inverter with capacity at least the approved kW. Required panels = ceiling(kW * 2). USD prices come exclusively from the catalog. Python requests only https://open.er-api.com/v6/latest/USD and reads LKR. It rejects redirects, unsupported base currency, malformed rates, stale timestamps over 48 hours and timestamps over five minutes into the future. Successful results are cached for one hour. HTTP timeout is eight seconds. The provider requires attribution, displayed in both clients: https://www.exchangerate-api.com/docs/free.

Decimal arithmetic rounds each converted unit price to two places using half-up rounding, multiplies by quantity, then sums lines. Both Python and ASP.NET independently verify results. Example test fixture: ten USD450 panels and one USD900 inverter at LKR300/USD total LKR1,620,000. These are synthetic test inputs, not market prices.

Names and notes are data, never instructions. Clients cannot choose a tool URL, supply a currency rate, execute code, write SQL or approve a proposal. A failure is saved without fallback exchange rates. Interrupted requests are marked FAILED when cancellation is observed; a new quote can be requested. A hard process crash may leave PROCESSING, which is not reservable.
