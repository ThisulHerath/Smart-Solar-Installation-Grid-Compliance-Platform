import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { AssignTechnicianForm } from '../../components/AssignTechnicianForm';
import { api } from '../../services/api';

vi.mock('../../services/api', () => ({ api: {
  getSurveys: vi.fn(), getTechnicians: vi.fn(), createFieldJob: vi.fn(),
} }));
describe('Technician assignment', () => {
  beforeEach(() => {
    vi.resetAllMocks();
    vi.mocked(api.getSurveys).mockResolvedValue([{ id: 'survey-1', propertyAddress: 'Manual test rooftop', monthlyKwh: 600, surveyStatus: 'AnalysisComplete' }] as any);
    vi.mocked(api.getTechnicians).mockResolvedValue([{ id: 'tech-1', fullName: 'Field Technician', email: 'technician@example.test' }]);
  });
  it('assigns the selected real IDs and highlights missing selections before assigning', async () => {
    const done = vi.fn();
    vi.mocked(api.createFieldJob).mockResolvedValue({ id: 'job-1' } as any);
    render(<AssignTechnicianForm onAssigned={done} onCancel={vi.fn()} />);
    const submit = await screen.findByRole('button', { name: 'Assign site visit' });
    expect(submit).toBeEnabled();
    fireEvent.click(submit);
    expect(api.createFieldJob).not.toHaveBeenCalled();
    expect(screen.getByLabelText('Customer survey')).toHaveFocus();
    expect(screen.getByLabelText('Customer survey')).toHaveAttribute('aria-invalid', 'true');
    fireEvent.change(screen.getByLabelText('Customer survey'), { target: { value: 'survey-1' } });
    fireEvent.change(screen.getByLabelText('Technician'), { target: { value: 'tech-1' } });
    fireEvent.change(screen.getByLabelText('Priority'), { target: { value: 'High' } });
    fireEvent.click(submit);
    await waitFor(() => expect(done).toHaveBeenCalledWith({ id: 'job-1' }));
    expect(api.createFieldJob).toHaveBeenCalledWith({ solarSurveyId: 'survey-1', technicianId: 'tech-1', priority: 'High' });
  });
  it('retains selections and shows a server rejection without claiming success', async () => {
    const done = vi.fn();
    vi.mocked(api.createFieldJob).mockRejectedValue(new Error('Select an active field technician.'));
    render(<AssignTechnicianForm onAssigned={done} onCancel={vi.fn()} />);
    await screen.findByLabelText('Customer survey');
    fireEvent.change(screen.getByLabelText('Customer survey'), { target: { value: 'survey-1' } });
    fireEvent.change(screen.getByLabelText('Technician'), { target: { value: 'tech-1' } });
    fireEvent.click(screen.getByRole('button', { name: 'Assign site visit' }));
    expect(await screen.findByRole('alert')).toHaveTextContent('Select an active field technician.');
    expect(screen.getByLabelText('Customer survey')).toHaveValue('survey-1');
    expect(done).not.toHaveBeenCalled();
  });
  it('explains an empty technician list', async () => {
    vi.mocked(api.getTechnicians).mockResolvedValue([]);
    render(<AssignTechnicianForm onAssigned={vi.fn()} onCancel={vi.fn()} />);
    expect(await screen.findByText('No active field technicians are available.')).toBeInTheDocument();
    fireEvent.click(screen.getByRole('button', { name: 'Assign site visit' }));
    expect(api.createFieldJob).not.toHaveBeenCalled();
  });
});
