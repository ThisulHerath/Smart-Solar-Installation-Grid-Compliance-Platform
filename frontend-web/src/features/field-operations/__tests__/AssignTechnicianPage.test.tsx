import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { AssignTechnicianPage } from '../pages/AssignTechnicianPage';
import { api } from '../../../services/api';

vi.mock('../../../services/api', () => ({ api: {
  getSurveys: vi.fn(), getTechnicians: vi.fn(), createFieldJob: vi.fn(),
} }));

describe('AssignTechnicianPage', () => {
  beforeEach(() => {
    vi.resetAllMocks();
    vi.mocked(api.getSurveys).mockResolvedValue([{ id: 'survey-1', propertyAddress: '45 Park Road, Colombo', monthlyKwh: 600, surveyStatus: 'AnalysisComplete' }] as any);
    vi.mocked(api.getTechnicians).mockResolvedValue([{ id: 'tech-1', fullName: 'Lead Field Technician', email: 'field@test.local' }]);
  });

  it('keeps assignment separate and shows a clear confirmation', async () => {
    vi.mocked(api.createFieldJob).mockResolvedValue({
      id: 'job-1', technicianName: 'Lead Field Technician', propertyAddress: '45 Park Road, Colombo',
      latitude: 6.902, longitude: 79.861,
    } as any);

    render(<MemoryRouter><AssignTechnicianPage /></MemoryRouter>);
    expect(screen.getByRole('heading', { level: 1, name: 'Assign a technician' })).toBeInTheDocument();

    fireEvent.change(await screen.findByLabelText('Customer survey'), { target: { value: 'survey-1' } });
    fireEvent.change(screen.getByLabelText(/Field technician/), { target: { value: 'tech-1' } });
    fireEvent.click(screen.getByRole('button', { name: 'Assign site visit' }));

    await waitFor(() => expect(screen.getByText('Lead Field Technician is assigned')).toBeInTheDocument());
    expect(screen.getByText(/Homeowner map location included/i)).toBeInTheDocument();
    expect(screen.getByRole('link', { name: /Open customer location/i })).toHaveAttribute(
      'href',
      expect.stringContaining('destination=6.902%2C79.861'),
    );
    expect(screen.getByRole('link', { name: /View field jobs/i })).toHaveAttribute('href', '/field-jobs');
  });
});
