# Customer Survey API

Authenticated homeowner endpoints: `GET/PUT /api/customer/profile`, `POST/GET /api/surveys`, `GET/PUT /api/surveys/{id}`, `POST /api/surveys/{id}/submit`, and `GET /api/surveys/{id}/status`.

Homeowners are scoped to their own profile and draft surveys. Senior engineers and administrators can inspect the survey list and details. The server validates positive usage and roof area, supported grid type, paired coordinates, and controlled status transitions. Submission starts the internal solar sizing workflow; clients never call the Python service directly.
