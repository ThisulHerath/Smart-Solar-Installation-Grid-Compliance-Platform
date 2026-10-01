const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:5116';

export type StaffRole = 'SENIOR_ENGINEER' | 'FIELD_TECHNICIAN' | 'ADMINISTRATOR' | 'INVENTORY_OFFICER';

export interface ManagedUser {
  id: string;
  fullName: string;
  email: string;
  phoneNumber?: string;
  roles: string[];
  isActive: boolean;
  createdAt: string;
}

export interface CreateManagedUserInput {
  fullName: string;
  email: string;
  password: string;
  phoneNumber?: string;
  role: StaffRole;
}

async function request<T>(path: string, method = 'GET', body?: unknown): Promise<T> {
  const token = localStorage.getItem('smartsolar_token') ?? sessionStorage.getItem('smartsolar_token');
  const response = await fetch(`${API_BASE_URL}/api/admin/users${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({}));
    if (response.status === 404) {
      throw new Error('User management is ready, but the API needs a restart to load its new endpoint.');
    }
    throw new Error(error.message || `Request failed (${response.status}).`);
  }

  return response.json();
}

export const userManagementService = {
  list: () => request<ManagedUser[]>(''),
  create: (input: CreateManagedUserInput) => request<ManagedUser>('', 'POST', input),
  updateStatus: (id: string, isActive: boolean) =>
    request<ManagedUser>(`/${id}/status`, 'PUT', { isActive }),
};
