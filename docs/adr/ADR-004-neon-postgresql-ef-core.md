# ADR-004: Neon Managed PostgreSQL + EF Core Database Strategy

## Status
Accepted

## Context
The project mandates a single cloud-native source of truth for structured data. Local standalone PostgreSQL databases are disallowed as the primary database to prevent database divergence.

## Options Considered
1. **Local Docker PostgreSQL as primary**: Causes drift between local student development and team assessment environments.
2. **Neon Managed Serverless PostgreSQL**: Cloud-managed PostgreSQL with branching support, connection pooling, and standard SQL compliance.
3. **Entity Framework Core with Npgsql**: Enterprise ORM providing type-safe queries, migration tracking, and relational constraints.

## Decision
We adopted **Neon Managed PostgreSQL** (`steep-band-56603943`, `production` branch) paired with **Entity Framework Core 8.0** (`Npgsql.EntityFrameworkCore.PostgreSQL`). EF Core code-first migrations govern all database evolution. Destructive database drops are prohibited.

## Consequences
- **Positive**: Single authoritative database, clean schema migrations, strong typing and relation integrity.
- **Negative**: Requires secure environment variable management for database credentials in CI and local setups.
