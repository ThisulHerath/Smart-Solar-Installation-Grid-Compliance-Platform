import { AuthResponse } from '../types/auth';
export type Challenge = { challengeId: string; maskedEmail: string; expiresAt: string; resendAfterSeconds: number };
export type Registration = { fullName: string; email: string; password: string; phoneNumber?: string };
export type AccountAction = 'password' | 'account-deletion';
async function post<T>(path: string, body: unknown, authenticated = false): Promise<T> {
  const token = localStorage.getItem('smartsolar_token');
  const response = await fetch(`${import.meta.env.VITE_API_BASE_URL || 'http://localhost:5116'}/api/auth/${path}`, {
    method: 'POST', headers: { 'Content-Type': 'application/json', ...(authenticated && token ? { Authorization: `Bearer ${token}` } : {}) }, body: JSON.stringify(body),
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    if (response.status === 401 && authenticated) { localStorage.removeItem('smartsolar_token'); window.location.assign('/login'); }
    throw new Error(data.message || (data.errors && Object.values(data.errors).flat().join(' ')) || (response.status === 429 ? 'Too many attempts. Please wait a minute and try again.' : 'We could not complete this request. Please try again.'));
  }
  return data;
}
export const accountApi = {
  requestRegistration: (details: Registration) => post<Challenge>('register/request-otp', details),
  verifyRegistration: (challengeId: string, code: string) => post<AuthResponse>('register', { challengeId, code }),
  requestAction: (action: AccountAction, newPassword?: string) => post<Challenge>(`${action}/request-otp`, { newPassword }, true),
  confirmAction: (action: AccountAction, challengeId: string, code: string) => post<{ message: string }>(`${action}/confirm`, { challengeId, code }, true),
};
