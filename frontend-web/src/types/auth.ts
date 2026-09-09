export interface User {
  id: string;
  email: string;
  fullName: string;
  phoneNumber?: string;
  roles: string[];
  createdAt: string;
}

export interface AuthResponse {
  token: string;
  tokenType: string;
  expiresIn: number;
  user: User;
}

export interface HealthResponse {
  status: string;
  environment: string;
  timestamp: string;
  database: string;
  agenticAi: string;
  details: Record<string, string>;
}

export interface WorkflowResult {
  workflow_id: string;
  customer_id?: string;
  objective: string;
  plan: string[];
  current_step: string;
  completed_steps: string[];
  tool_results: Record<string, any>;
  validation_results: Record<string, any>;
  errors: string[];
  approval_status: string;
  final_outcome: string;
  execution_logs: string[];
}

export interface Survey {
  id: string;
  customerId: string;
  monthlyKwh: number;
  roofAreaSqm: number;
  gridType: string;
  roofOrientation: string;
  roofTilt?: number;
  propertyAddress: string;
  latitude?: number;
  longitude?: number;
  surveyStatus: string;
  notes?: string;
  createdAt: string;
  updatedAt: string;
  images: { id: string; imageType: string; fileUrl: string; fileName: string }[];
  workflows: { workflowId: string; status: string; resultJson?: string; validationJson?: string; errorMessage?: string }[];
}

export interface ComplianceAssessment {
  id: string;
  siteInspectionId: string;
  workflowId?: string;
  gridCompliant: boolean;
  complianceStatus: string;
  riskLevel: string;
  complianceNotes?: string;
  validationStatus?: string;
  createdAt: string;
  updatedAt: string;
  violations?: string[];
  recommendations?: string[];
}

export interface SiteTelemetry {
  id: string;
  siteInspectionId: string;
  measurementType: string;
  measurementValue: number;
  unit: string;
  recordedAt: string;
}

export interface SitePhoto {
  id: string;
  siteInspectionId: string;
  photoType: string;
  fileUrl: string;
  fileName: string;
  createdAt: string;
}

export interface SiteInspection {
  id: string;
  fieldJobId: string;
  checkInLatitude?: number;
  checkInLongitude?: number;
  checkInAt?: string;
  roofAreaMeasuredSqm?: number;
  roofOrientation: string;
  roofTilt?: number;
  gridTypeObserved: string;
  phaseCount?: number;
  mainBreakerRating?: number;
  inverterLocationSuitable?: boolean;
  safetyNotes?: string;
  technicianNotes?: string;
  inspectionStatus: string;
  createdAt: string;
  updatedAt: string;
  telemetry: SiteTelemetry[];
  photos: SitePhoto[];
  complianceAssessment?: ComplianceAssessment;
}

export interface FieldJob {
  id: string;
  solarSurveyId: string;
  technicianId: string;
  technicianName: string;
  customerName: string;
  customerPhone: string;
  propertyAddress: string;
  monthlyKwh: number;
  roofAreaSqm: number;
  latitude?: number;
  longitude?: number;
  status: string;
  priority: string;
  assignedAt: string;
  scheduledAt?: string;
  createdAt: string;
  updatedAt: string;
  hasInspection: boolean;
  inspectionStatus?: string;
  compliance?: ComplianceAssessment;
}

