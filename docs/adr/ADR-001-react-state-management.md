# ADR-001: React State Management Strategy

## Status
Accepted

## Context
The Smart Solar Web Platform requires an efficient, maintainable, and predictable state management architecture for Phase 1 and future phases. The platform handles user authentication, JWT lifecycle, RBAC permissions, live system health monitoring, and interactive multi-agent workflow inspection.

## Options Considered
1. **Redux Toolkit (RTK)**: Full-featured, predictable state container with time-travel debugging. However, it introduces significant boilerplate and cognitive overhead for Phase 1 requirements.
2. **React Context API + Custom Hooks**: Built directly into React, zero additional dependencies, lightweight, and ideal for global auth and session state.
3. **Zustand**: Minimalist state store with low boilerplate.

## Decision
We adopted **React Context API with Custom Hooks (`AuthContext`)** paired with modular API service abstractions. Authentication tokens are managed with browser `localStorage` persistence and reactive state updates across protected routes.

## Consequences
- **Positive**: Zero external dependency overhead, seamless TypeScript integration, clear separation of UI components and auth logic.
- **Negative / Future mitigation**: If deeply nested high-frequency dashboard updates are needed in Phase 2, specific sub-stores (e.g., Zustand) can be added without refactoring the foundational `AuthContext`.
