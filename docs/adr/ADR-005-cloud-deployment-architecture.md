# ADR-005: Cloud Deployment Architecture

## Status
Accepted

## Context
The platform comprises five distinct architectural tiers that need clean, secure, and cost-effective hosting strategies for production and grading environments.

## Options Considered
1. Monolithic all-in-one VM / VPS
2. Distributed Cloud Native Services:
   - React Web &rarr; Vercel (Edge CDN)
   - ASP.NET Core API &rarr; Render (Docker/Web Service)
   - Python Agentic AI &rarr; Render (Internal Web Service)
   - Database &rarr; Neon Serverless PostgreSQL
   - Mobile &rarr; Android APK distribution

## Decision
We adopted the **Distributed Cloud Native Architecture**:
- **Frontend Web**: Deployed to Vercel for fast global static asset delivery.
- **Backend API**: Deployed to Render as the authoritative public entrypoint.
- **Agentic AI**: Deployed to Render as an internal private service.
- **Database**: Hosted on Neon PostgreSQL.
- **Frontend Mobile**: Built as Android APK with dynamic backend base URL configuration.

## Consequences
- **Positive**: Strict security boundaries (clients never reach internal AI or database directly), independent scaling and zero-downtime deployments.
- **Negative**: Requires environment variable synchronization across hosting platforms.
