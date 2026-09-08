# Customer Survey Flow

Flutter authenticates with JWT and submits survey JSON to ASP.NET Core. The API derives the user from JWT claims, validates ownership and input, persists the survey in Neon through EF Core, creates a workflow, and calls the internal Agentic AI service with `X-Internal-Key`. Structured sizing output is independently validated and persisted. React staff views the same API data; Flutter reads status and workflow results.

Failure is explicit: the workflow and survey are marked failed with a safe error message. No recommendation is fabricated and no client receives internal stack traces.
