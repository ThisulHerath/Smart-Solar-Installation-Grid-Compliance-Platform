import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { describe, expect, it, vi } from 'vitest';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { ProposalDetailPage } from '../ProposalDetailPage';
import { approveProposal, getProposal } from '../../services/proposalService';

vi.mock('../../services/proposalService', () => ({
  getProposal: vi.fn(),
  approveProposal: vi.fn(),
  rejectProposal: vi.fn(),
  reviseProposal: vi.fn(),
}));

const pendingProposal = {
  id: 'proposal-1', solarSurveyId: 'survey-1', workflowId: 'wf-1',
  recommendedKw: 12, panelCount: 30, inverterSizeKw: 12, estimatedCostLkr: 3000000,
  gridComplianceStatus: 'COMPLIANT', riskLevel: 'LOW', safetyStatus: 'SAFE',
  proposalStatus: 'PendingApproval' as const, requiresApproval: true,
  recommendationSummary: 'Ready for engineering review.',
  guardrailResultJson: null, validationResultJson: JSON.stringify({
    valid: true, requiresApproval: true, checks: ['PASS:recommended_kw_positive'],
    violations: [], overrideReason: '',
  }), auditLogs: [], customerName: 'Homeowner', propertyAddress: 'Solar Road',
  createdAt: '2026-09-11T00:00:00Z', updatedAt: '2026-09-11T00:00:00Z',
};

describe('Proposal approval flow', () => {
  it('opens confirmation and submits approval with the API result', async () => {
    (getProposal as any).mockResolvedValue(pendingProposal);
    (approveProposal as any).mockResolvedValue({ ...pendingProposal, proposalStatus: 'Approved' });

    render(
      <MemoryRouter initialEntries={['/proposals/proposal-1']}>
        <Routes>
          <Route path="/proposals/:id" element={<ProposalDetailPage />} />
        </Routes>
      </MemoryRouter>,
    );

    await waitFor(() => expect(screen.getByRole('button', { name: /Approve Proposal/i })).toBeInTheDocument());
    fireEvent.click(screen.getByRole('button', { name: /Approve Proposal/i }));
    fireEvent.click(screen.getByRole('button', { name: /Confirm Approval/i }));

    await waitFor(() => expect(approveProposal).toHaveBeenCalledWith('proposal-1', { comment: '' }));
    await waitFor(() => expect(screen.getByText('Approved')).toBeInTheDocument());
  });
});