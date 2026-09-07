# ADR-002: Flutter State Management Strategy

## Status
Accepted

## Context
The Flutter mobile application serves field technicians and site surveyors capturing solar site telemetry, GPS coordinates, and inspection reports. It requires robust lifecycle state management for authentication, secure token persistence, and role verification.

## Options Considered
1. **Bloc / Cubit**: Highly structured and testable event-driven state management. Introduces additional layers for initial Phase 1 foundation.
2. **Provider with ChangeNotifier**: Official Flutter recommendation for lightweight to medium apps, well-documented, testable, and minimal boilerplate.
3. **Riverpod**: Compile-safe evolution of Provider, but adds steeper initial learning curve for student assessment.

## Decision
We adopted **Provider (`ChangeNotifierProvider`)** with `flutter_secure_storage` for secure token management. `AuthProvider` exposes state status (`uninitialized`, `authenticated`, `unauthenticated`, `authenticating`) and reactive notifications to UI screens.

## Consequences
- **Positive**: Clean separation of UI and business logic, simple dependency injection, easily mockable in unit/widget tests.
- **Negative**: For complex offline sync in Phase 2, repository patterns layered atop Provider will be maintained.
