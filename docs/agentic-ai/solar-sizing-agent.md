# Solar Sizing Agent

`SolarSizingAgent` produces a structured preliminary recommendation from workflow and survey input. The authoritative rule is `recommended kW = round(monthly kWh / 120.0, 2)`. The deterministic validator independently checks positive inputs, the kW formula, 400 W panel-count estimate, inverter size, and schema completeness. Invalid or unavailable AI output marks the workflow failed.

The internal endpoint is `POST /workflow/solar-sizing` and requires `X-Internal-Key`. The existing Phase 1 test workflow remains available for compatibility.
