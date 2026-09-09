import { AuthResponse, HealthResponse, User, WorkflowResult, Survey, FieldJob, ComplianceAssessment } from '../types/auth';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:5116';

class ApiService {
  private getHeaders(): HeadersInit {
    const token = localStorage.getItem('smartsolar_token');
    const headers: HeadersInit = {
      'Content-Type': 'application/json',
    };
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }
    return headers;
  }

  // Health
  async getHealth(): Promise<HealthResponse> {
    const res = await fetch(`${API_BASE_URL}/api/health`, {
      headers: this.getHeaders(),
    });
    if (!res.ok) {
      throw new Error(`Health check failed: ${res.statusText}`);
    }
    return res.json();
  }

  // Auth
  async login(email: string, password: string): Promise<AuthResponse> {
    const res = await fetch(`${API_BASE_URL}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    });
    if (!res.ok) {
      const errorData = await res.json().catch(() => ({}));
      throw new Error(errorData.message || 'Invalid email or password.');
    }
    return res.json();
  }

  async getMe(): Promise<User> {
    const res = await fetch(`${API_BASE_URL}/api/auth/me`, {
      headers: this.getHeaders(),
    });
    if (!res.ok) {
      throw new Error('Failed to fetch user session.');
    }
    return res.json();
  }

  // Architecture Verification Endpoints
  async testAdminEndpoint(): Promise<any> {
    const res = await fetch(`${API_BASE_URL}/api/admin/test`, {
      headers: this.getHeaders(),
    });
    if (!res.ok) {
      throw new Error(`Status ${res.status}: Access Denied (Administrator role required)`);
    }
    return res.json();
  }

  async testEngineerEndpoint(): Promise<any> {
    const res = await fetch(`${API_BASE_URL}/api/engineer/test`, {
      headers: this.getHeaders(),
    });
    if (!res.ok) {
      throw new Error(`Status ${res.status}: Access Denied (Senior Engineer role required)`);
    }
    return res.json();
  }

  // Internal AI Trigger via ASP.NET Core
  async triggerAiWorkflow(objective: string): Promise<WorkflowResult> {
    const res = await fetch(`${API_BASE_URL}/api/agent-workflows/test`, {
      method: 'POST',
      headers: this.getHeaders(),
      body: JSON.stringify({ objective }),
    });
    if (!res.ok) {
      const errorData = await res.json().catch(() => ({}));
      throw new Error(errorData.message || `AI workflow invocation error: ${res.statusText}`);
    }
    return res.json();
  }

  async getSurveys(): Promise<Survey[]> {
    const res = await fetch(`${API_BASE_URL}/api/surveys`, { headers: this.getHeaders() });
    if (!res.ok) throw new Error(`Unable to load surveys (${res.status}).`);
    return res.json();
  }

  async getSurvey(id: string): Promise<Survey> {
    const res = await fetch(`${API_BASE_URL}/api/surveys/${id}`, { headers: this.getHeaders() });
    if (!res.ok) throw new Error(`Unable to load survey (${res.status}).`);
    return res.json();
  }

  async getFieldJobs(status?: string): Promise<FieldJob[]> {
    const query = status ? `?status=${encodeURIComponent(status)}` : '';
    const res = await fetch(`${API_BASE_URL}/api/field-jobs${query}`, { headers: this.getHeaders() });
    if (!res.ok) throw new Error(`Unable to load field jobs (${res.status}).`);
    return res.json();
  }

  async getFieldJob(id: string): Promise<FieldJob> {
    const res = await fetch(`${API_BASE_URL}/api/field-jobs/${id}`, { headers: this.getHeaders() });
    if (!res.ok) throw new Error(`Unable to load field job (${res.status}).`);
    return res.json();
  }

  async createFieldJob(data: { solarSurveyId: string; technicianId: string; scheduledAt?: string; priority?: string }): Promise<FieldJob> {
    const res = await fetch(`${API_BASE_URL}/api/field-jobs`, {
      method: 'POST',
      headers: this.getHeaders(),
      body: JSON.stringify(data),
    });
    if (!res.ok) throw new Error(`Unable to create field job (${res.status}).`);
    return res.json();
  }

  async assignFieldJob(jobId: string, data: { technicianId: string; scheduledAt?: string; priority?: string }): Promise<FieldJob> {
    const res = await fetch(`${API_BASE_URL}/api/field-jobs/${jobId}/assign`, {
      method: 'PUT',
      headers: this.getHeaders(),
      body: JSON.stringify(data),
    });
    if (!res.ok) throw new Error(`Unable to assign field job (${res.status}).`);
    return res.json();
  }

  async evaluateJobCompliance(jobId: string): Promise<ComplianceAssessment> {
    const res = await fetch(`${API_BASE_URL}/api/field-jobs/${jobId}/evaluate-compliance`, {
      method: 'POST',
      headers: this.getHeaders(),
    });
    if (!res.ok) throw new Error(`Unable to evaluate compliance (${res.status}).`);
    return res.json();
  }
}

export const api = new ApiService();

