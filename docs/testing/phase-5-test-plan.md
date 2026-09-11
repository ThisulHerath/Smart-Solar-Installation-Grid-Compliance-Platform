# Release verification

Measured locally on Windows with the configured Neon database. Results are actual runs, not a guarantee of hosted performance.

- Backend: 83 passed across the full suite and added contract regression, including the PostgreSQL integration test.
- Python: 38 passed. One dependency deprecation warning.
- React: 16 passed in four files.
- Flutter: 14 passed. Static analysis reported no issues.
- Android: debug APK built successfully. Physical-device camera/GPS interaction still requires an on-device check.
- Browser: inventory staff login, dashboard totals, inventory catalog and saved released quote verified through the rendered UI. Narrow-screen navigation checked for overflow.
- Live HTTP workflow: scripts/smoke_workflow.py creates explicitly labelled synthetic records, registers a homeowner, submits sizing, assigns a technician, records inspection and telemetry, evaluates compliance, creates a proposal, verifies homeowner approval denial, approves as engineer, gets a live USD/LKR quote, reserves twice without duplication, reads it as homeowner, releases, and verifies a released quote cannot be reserved again.
- Performance: 20 report reads with concurrency five. Consult live-workflow-evidence.json for timestamps, response codes and the current median/p95, rather than copying stale numbers.

The live smoke runner leaves labelled demo records for review, releases its reservation, and never cleans unrelated records. It may select an existing cheaper compatible item. Run only against a development API/database.

PostgreSQL tests cover full migration, competing reservations, idempotency, release, injected persistence failure rollback, and database stock constraints. Unit/API tests cover catalog CRUD, duplicate SKU, stale edits, negative stock, insufficient stock, unapproved proposals, unauthorized roles, owner isolation, pricing validation and outages. Python evaluations cover golden arithmetic, incompatible panel counts, stock changes, bad tool outputs, stale rates, extra URL fields and injected instructions.

No GitHub Actions execution or hosted verification is claimed. Workflows are supplied and must run after the group pushes its reviewed branch.
