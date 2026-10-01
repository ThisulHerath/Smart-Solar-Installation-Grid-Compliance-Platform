# Feature-first repository structure

The project uses the same four business boundaries in the backend, React application, Flutter application, agentic service, and tests. This makes individual contribution easy to identify and keeps a business change inside one recognizable vertical slice.

## Rules

- Put component-specific controllers, models, DTOs, services, pages, widgets, agents, schemas, workflows, and tests inside that component's feature folder.
- Put code in `Shared` or `core` only when two or more components use it and it has no single business owner.
- Keep Entity Framework migrations under `backend/SolarPlatform.Api/Migrations`; migrations describe the integrated database history and should not be moved between members.
- Keep public API routes and serialized contracts stable when moving source files.
- The master agent workflow belongs under `agentic-ai/app/shared/orchestration`; individual reasoning and validation remain inside the owning feature.
- Every pull request should name the member/component, affected layers, tests run, and any cross-component contract change.

## Cross-component dependency direction

Feature code may depend on shared infrastructure. Shared infrastructure must not import UI pages or component-specific presentation code. Cross-component actions should pass through public API or workflow contracts instead of directly changing another component's internal state.

## Definition of done for one member

A member's component is ready for assessment when it has a working database/API path, a usable React path, a usable Flutter path, a distinct agent or tool-assisted workflow, validation and error handling, tests, and a short individual demonstration that identifies the member's own contribution.
