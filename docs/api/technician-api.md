# Technician & Field Operations REST API Documentation

## Base URL
`/api/technician/jobs` (Mobile Technician Client)
`/api/field-jobs` (Staff / Admin / Engineer Web Client)

## Authentication & Headers
All requests require a valid JWT Bearer token:
```http
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

---

## 1. Technician Endpoints

### 1.1 List Assigned Jobs
- **Method**: `GET /api/technician/jobs`
- **Query Parameters**: `status` (optional `FieldJobStatus`)
- **Authorization**: `FIELD_TECHNICIAN`, `ADMINISTRATOR`, `SENIOR_ENGINEER`
- **Response**: `200 OK`
```json
[
  {
    "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "solarSurveyId": "7ca85f64-5717-4562-b3fc-2c963f66afa7",
    "technicianId": "cccccccc-cccc-cccc-cccc-cccccccccccc",
    "technicianName": "Lead Field Technician",
    "customerName": "Kamal Perera",
    "customerPhone": "+94771234567",
    "propertyAddress": "45 Galle Road, Colombo 03",
    "monthlyKwh": 1200.0,
    "roofAreaSqm": 85.0,
    "status": "Assigned",
    "priority": "High",
    "assignedAt": "2026-09-09T08:00:00Z",
    "hasInspection": false
  }
]
```

### 1.2 Get Job by ID
- **Method**: `GET /api/technician/jobs/{jobId}`
- **Response**: `200 OK` (includes customer, survey, inspection, telemetry, photos, and compliance assessment).

### 1.3 Update Job Status
- **Method**: `PUT /api/technician/jobs/{jobId}/status`
- **Body**:
```json
{
  "newStatus": "Accepted",
  "reason": "Technician acknowledged dispatch."
}
```
- **Response**: `200 OK`

### 1.4 GPS Check-in
- **Method**: `POST /api/technician/jobs/{jobId}/check-in`
- **Body**:
```json
{
  "latitude": 6.9271,
  "longitude": 79.8612
}
```
- **Response**: `200 OK` (Sets coordinates and automatically transitions job to `InProgress`).

### 1.5 Save Site Inspection Draft
- **Method**: `PUT /api/technician/jobs/{jobId}/inspection`
- **Body**:
```json
{
  "roofAreaMeasuredSqm": 82.5,
  "roofOrientation": "South",
  "roofTilt": 15.0,
  "gridTypeObserved": "SinglePhase",
  "phaseCount": 1,
  "mainBreakerRating": 40.0,
  "inverterLocationSuitable": true,
  "safetyNotes": "Clear ladder access on west wall.",
  "technicianNotes": "Service meter is easily accessible."
}
```
- **Response**: `200 OK`

### 1.6 Record Telemetry Measurement
- **Method**: `POST /api/technician/jobs/{jobId}/telemetry`
- **Body**:
```json
{
  "measurementType": "GridVoltage",
  "measurementValue": 230.5,
  "unit": "V"
}
```
- **Response**: `200 OK`

### 1.7 Upload Evidentiary Photo
- **Method**: `POST /api/technician/jobs/{jobId}/photos`
- **Content-Type**: `multipart/form-data`
- **Form Fields**: `file` (Binary Image File), `photoType` (`Roof`, `Meter`, `ElectricalPanel`, `InverterLocation`, `SafetyIssue`)
- **Response**: `200 OK`

### 1.8 Submit Site Inspection & Evaluate Compliance
- **Method**: `POST /api/technician/jobs/{jobId}/submit`
- **Response**: `200 OK` (Advances status to `Submitted` -> `ComplianceProcessing` -> `ComplianceComplete` or `Failed`).

---

## 2. Staff Management Endpoints (`/api/field-jobs`)

### 2.1 List All Jobs
- **Method**: `GET /api/field-jobs`
- **Authorization**: `ADMINISTRATOR`, `SENIOR_ENGINEER`
- **Response**: `200 OK`

### 2.2 Create / Assign Field Job
- **Method**: `POST /api/field-jobs`
- **Body**:
```json
{
  "solarSurveyId": "7ca85f64-5717-4562-b3fc-2c963f66afa7",
  "technicianId": "cccccccc-cccc-cccc-cccc-cccccccccccc",
  "scheduledAt": "2026-09-10T09:00:00Z",
  "priority": "High"
}
```
- **Response**: `201 Created`

### 2.3 Trigger Compliance Evaluation
- **Method**: `POST /api/field-jobs/{jobId}/evaluate-compliance`
- **Response**: `200 OK`
