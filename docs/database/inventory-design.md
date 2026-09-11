# Inventory persistence

The additive EF migration AddInventoryPricingPhase5 creates Supplier, InventoryItems, EquipmentQuote, InventoryReservations and InventoryTransaction. Earlier survey, inspection and proposal tables remain intact.

InventoryItems has a unique normalized SKU, positive USD price and capacity, and a GUID concurrency token. Database CHECK constraints require stock >= reserved >= 0. Supplier and proposal relationships use foreign keys with restricted deletion. Deactivation preserves history.

EquipmentQuote stores status, result JSON, error, creation time and a one-hour expiry. Each quote has an immutable calculation snapshot. Reservations retain quantities, USD unit price, currency rate, LKR unit/line prices, status and timestamps. A filtered unique index prevents duplicate active reservations for a proposal and item. InventoryTransaction records actor, reference, quantity, reason and timestamp.

Reserve and release use serializable PostgreSQL transactions. Each reservation rechecks approval, quote age, catalog identity, capacity, price and available stock. It writes all reservations, stock counters, transaction records and quote status together. A conflicting request must reload and retry; an idempotent replay does not duplicate stock movement.

The PostgreSQL integration test creates a unique schema, asserts current_schema on connection open, uses a schema-specific migration history, and drops only that generated schema in finally. Neon tests use a direct connection because transaction pooling cannot preserve session search_path. See https://neon.com/docs/connect/connection-pooling.

Verification note: the first test attempt used a connection whose startup search path was ignored. The additive migrations reached public; the test-data save failed on a duplicate profile and rolled back. The corrected isolated test subsequently passed. All eight project migrations were confirmed applied.
