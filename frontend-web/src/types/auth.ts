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
