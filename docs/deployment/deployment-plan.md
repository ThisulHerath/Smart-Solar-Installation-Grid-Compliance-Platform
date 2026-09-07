# Cloud Deployment Plan

## Hosting Strategy

| Layer | Technology | Target Hosting | Access Level |
| :--- | :--- | :--- | :--- |
| **Frontend Web** | React + TypeScript (Vite) | Vercel | Public Edge CDN |
| **Backend API** | ASP.NET Core 8 Web API | Render | Public REST Gateway |
| **Agentic AI** | Python FastAPI + LangGraph | Render | Internal Private Microservice |
| **Database** | Neon Managed PostgreSQL | Neon Cloud | Managed Cloud DB (Accessed by API only) |
| **Frontend Mobile**| Flutter / Dart | Android APK | Mobile Client |

## Environment Provisioning Checklist
1. **Neon PostgreSQL**:
   - Project: `steep-band-56603943`
   - Branch: `production`
   - SSL Mode: Required
2. **Render (Backend API)**:
   - Environment variables: `DATABASE_CONNECTION_STRING`, `JWT_KEY`, `JWT_ISSUER`, `JWT_AUDIENCE`, `AGENTIC_AI_BASE_URL`, `AGENTIC_AI_INTERNAL_KEY`.
3. **Render (Agentic AI)**:
   - Environment variables: `PORT=8000`, `AGENTIC_AI_INTERNAL_KEY`.
4. **Vercel (Frontend Web)**:
   - Environment variable: `VITE_API_BASE_URL=https://<your-render-api>.onrender.com`.
