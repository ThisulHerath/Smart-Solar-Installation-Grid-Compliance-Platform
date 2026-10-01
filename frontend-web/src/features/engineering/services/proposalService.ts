import {
  EngineeringProposal,
  EngineeringProposalSummary,
  CreateProposalRequest,
  ApproveProposalRequest,
  RejectProposalRequest,
  ReviseProposalRequest,
} from '../types/ProposalTypes';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:5116';

function getHeaders(): HeadersInit {
  const token = localStorage.getItem('smartsolar_token');
  const headers: HeadersInit = { 'Content-Type': 'application/json' };
  if (token) headers['Authorization'] = `Bearer ${token}`;
  return headers;
}

async function handleResponse<T>(res: Response): Promise<T> {
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error((err as any).message || `Request failed: ${res.status} ${res.statusText}`);
  }
  return res.json() as Promise<T>;
}

// ── Proposals API ─────────────────────────────────────────────────────────────

export async function getProposals(): Promise<EngineeringProposalSummary[]> {
  const res = await fetch(`${API_BASE_URL}/api/proposals`, { headers: getHeaders() });
  return handleResponse<EngineeringProposalSummary[]>(res);
}

export async function getPendingProposals(): Promise<EngineeringProposalSummary[]> {
  const res = await fetch(`${API_BASE_URL}/api/proposals/pending`, { headers: getHeaders() });
  return handleResponse<EngineeringProposalSummary[]>(res);
}

export async function getProposal(id: string): Promise<EngineeringProposal> {
  const res = await fetch(`${API_BASE_URL}/api/proposals/${id}`, { headers: getHeaders() });
  return handleResponse<EngineeringProposal>(res);
}

export async function getProposalsBySurvey(surveyId: string): Promise<EngineeringProposalSummary[]> {
  const res = await fetch(`${API_BASE_URL}/api/proposals/survey/${surveyId}`, { headers: getHeaders() });
  return handleResponse<EngineeringProposalSummary[]>(res);
}

export async function createProposal(req: CreateProposalRequest): Promise<EngineeringProposal> {
  const res = await fetch(`${API_BASE_URL}/api/proposals`, {
    method: 'POST',
    headers: getHeaders(),
    body: JSON.stringify(req),
  });
  return handleResponse<EngineeringProposal>(res);
}

export async function approveProposal(id: string, req: ApproveProposalRequest): Promise<EngineeringProposal> {
  const res = await fetch(`${API_BASE_URL}/api/proposals/${id}/approve`, {
    method: 'POST',
    headers: getHeaders(),
    body: JSON.stringify(req),
  });
  return handleResponse<EngineeringProposal>(res);
}

export async function rejectProposal(id: string, req: RejectProposalRequest): Promise<EngineeringProposal> {
  const res = await fetch(`${API_BASE_URL}/api/proposals/${id}/reject`, {
    method: 'POST',
    headers: getHeaders(),
    body: JSON.stringify(req),
  });
  return handleResponse<EngineeringProposal>(res);
}

export async function reviseProposal(id: string, req: ReviseProposalRequest): Promise<EngineeringProposal> {
  const res = await fetch(`${API_BASE_URL}/api/proposals/${id}/revise`, {
    method: 'POST',
    headers: getHeaders(),
    body: JSON.stringify(req),
  });
  return handleResponse<EngineeringProposal>(res);
}
