# Inventory and equipment pricing API

All paths begin with /api/inventory and require a JWT. Inventory officers and administrators write; senior engineers may read. Equipment results are also readable by the proposal's homeowner. Other homeowners receive 404.

- GET /: search, category=PANEL|INVERTER, active, lowStock, sort=name|sku|stock|price, page, pageSize (maximum 100). Returns items, total, page, pageSize.
- GET /low-stock: the same paginated result restricted to available stock at or below reorder level.
- GET /{id}; POST /; PUT /{id}; DELETE /{id}. Delete deactivates an item. Edits carry the current version to detect stale updates.
- POST /{id}/adjust: quantityDelta and reason. Cannot reduce physical stock below reserved stock.
- GET /suppliers; POST /suppliers: name, contactEmail, phone.
- GET /proposals: approved proposals eligible for pricing.
- POST /proposals/{id}/price: reads approved capacity and server catalog prices, invokes the internal workflow, persists a VALIDATED or FAILED quote.
- GET /proposals/{id}/equipment: most recent 20 saved quote attempts, including failures.
- POST /reserve: quoteId. Uses a serializable transaction; replay of a successful reservation is idempotent.
- POST /{quoteId}/release: releases the entire equipment set atomically and retains its audit history.
- GET /reservations: most recent 500 reservation rows.

Item writes contain sku, name, category, manufacturer, model, supplierId, capacityWatts, quantityInStock, reorderLevel, unitPriceUsd, active and (for edits) version. Reserved quantity is never accepted from a client.

Validation failures return a useful message. Authentication failures use 401/403, missing resources use 404, and database concurrency/constraint conflicts use 409. A pricing-tool outage returns a saved FAILED quote; it never produces a fabricated LKR value.

Related endpoints: GET /api/reports/overview (staff totals) and GET /api/workflows/surveys/{id} (owner/engineer/admin persisted workflow overview).
