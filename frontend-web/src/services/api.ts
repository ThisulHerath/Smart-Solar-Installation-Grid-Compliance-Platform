import { AuthResponse, HealthResponse, User, WorkflowResult } from '../types/auth';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:5000';

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
}

export const api = new ApiService();
