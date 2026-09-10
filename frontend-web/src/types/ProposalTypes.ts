// Phase 4: Engineering Proposal TypeScript types

export interface ApprovalAuditLog {
  id: string;
  decision: 'Approved' | 'Rejected' | 'RevisionRequested';
  comment?: string;
  userId: string;
  workflowId?: string;
  timestamp: string;
}

export interface EngineeringProposalSummary {
  id: string;
  solarSurveyId: string;
  workflowId?: string;
  recommendedKw: number;
  panelCount: number;
  inverterSizeKw: number;
  estimatedCostLkr: number;
  gridComplianceStatus: string;
  riskLevel: string;
  safetyStatus: string;
  proposalStatus: ProposalStatus;
  requiresApproval: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface EngineeringProposal extends EngineeringProposalSummary {
  recommendationSummary?: string;
  engineerNotes?: string;
  guardrailResultJson?: string;
  validationResultJson?: string;
  customerName?: string;
  propertyAddress?: string;
  auditLogs: ApprovalAuditLog[];
}

export type ProposalStatus =
  | 'Draft'
  | 'Processing'
  | 'PendingApproval'
  | 'Approved'
  | 'Rejected'
  | 'RevisionRequested'
  | 'Failed';

export interface CreateProposalRequest {
  solarSurveyId: string;
  notes?: string;
}

export interface ApproveProposalRequest {
  comment?: string;
}

export interface RejectProposalRequest {
  comment: string;
}

export interface ReviseProposalRequest {
  comment: string;
}

export interface ValidationResult {
  valid: boolean;
  requiresApproval: boolean;
  checks: string[];
  violations: string[];
  overrideReason: string;
}

export interface GuardrailResult {
  safetyStatus: string;
  riskLevel: string;
  requiresApproval: boolean;
  issues: string[];
  recommendations: string[];
  recommendationSummary?: string;
}
