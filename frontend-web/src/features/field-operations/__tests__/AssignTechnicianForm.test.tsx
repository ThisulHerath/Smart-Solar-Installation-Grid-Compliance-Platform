import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { AssignTechnicianForm } from '../components/AssignTechnicianForm';
import { api } from '../../../services/api';

vi.mock('../../../services/api', () => ({ api: {
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
    fireEvent.click(screen.getByLabelText('Customer survey'));
    fireEvent.click(screen.getByRole('option', { name: /Manual test rooftop/i }));
    fireEvent.click(screen.getByLabelText('Field technician'));
    fireEvent.click(screen.getByRole('option', { name: /Field Technician/i }));
    fireEvent.click(screen.getByRole('radio', { name: /High/i }));
    fireEvent.click(submit);
    await waitFor(() => expect(done).toHaveBeenCalledWith({ id: 'job-1' }));
    expect(api.createFieldJob).toHaveBeenCalledWith({ solarSurveyId: 'survey-1', technicianId: 'tech-1', priority: 'High' });
  });
  it('retains selections and shows a server rejection without claiming success', async () => {
    const done = vi.fn();
    vi.mocked(api.createFieldJob).mockRejectedValue(new Error('Select an active field technician.'));
    render(<AssignTechnicianForm onAssigned={done} onCancel={vi.fn()} />);
    await screen.findByLabelText('Customer survey');
    fireEvent.click(screen.getByLabelText('Customer survey'));
    fireEvent.click(screen.getByRole('option', { name: /Manual test rooftop/i }));
    fireEvent.click(screen.getByLabelText('Field technician'));
    fireEvent.click(screen.getByRole('option', { name: /Field Technician/i }));
    fireEvent.click(screen.getByRole('button', { name: 'Assign site visit' }));
    expect(await screen.findByRole('alert')).toHaveTextContent('Select an active field technician.');
    expect(screen.getByLabelText('Customer survey')).toHaveTextContent('Manual test rooftop');
    expect(done).not.toHaveBeenCalled();
  });
  it('filters surveys and presents the selected customer site clearly', async () => {
    vi.mocked(api.getSurveys).mockResolvedValue([
      { id: 'survey-1', propertyAddress: '12 Lake Road, Malabe', projectName: 'Lake Road solar', customerName: 'Pasan Janadeepa', surveyStatus: 'AnalysisComplete' },
      { id: 'survey-2', propertyAddress: '44 Hill Street, Kandy', projectName: 'Hill Street solar', customerName: 'Nethsara Silva', surveyStatus: 'Failed' },
    ] as any);
    render(<AssignTechnicianForm onAssigned={vi.fn()} onCancel={vi.fn()} />);
    await screen.findByLabelText('Customer survey');
    fireEvent.click(screen.getByLabelText('Customer survey'));
    fireEvent.change(screen.getByLabelText('Search customer survey'), { target: { value: 'Pasan' } });
    expect(screen.getByRole('option', { name: /Lake Road solar.*Pasan Janadeepa.*12 Lake Road.*Analysis Complete/i })).toBeInTheDocument();
    expect(screen.queryByRole('option', { name: /44 Hill Street/i })).not.toBeInTheDocument();
    fireEvent.click(screen.getByRole('option', { name: /Lake Road solar.*Pasan Janadeepa.*12 Lake Road/i }));
    const summary = screen.getByRole('article', { name: 'Selected survey details' });
    expect(summary).toHaveTextContent('12 Lake Road, Malabe');
    expect(summary).toHaveTextContent('Pasan Janadeepa');
    expect(summary).toHaveTextContent('SURVEY-1');
    expect(summary).toHaveTextContent('Analysis Complete');
  });
  it('explains an empty technician list', async () => {
    vi.mocked(api.getTechnicians).mockResolvedValue([]);
    render(<AssignTechnicianForm onAssigned={vi.fn()} onCancel={vi.fn()} />);
    expect(await screen.findByText('No active field technicians are available.')).toBeInTheDocument();
    fireEvent.click(screen.getByRole('button', { name: 'Assign site visit' }));
    expect(api.createFieldJob).not.toHaveBeenCalled();
  });

  it('requires date and time together before creating an assignment', async () => {
    vi.mocked(api.createFieldJob).mockResolvedValue({ id: 'job-1' } as any);
    render(<AssignTechnicianForm onAssigned={vi.fn()} onCancel={vi.fn()} />);
    await screen.findByLabelText('Customer survey');
    fireEvent.click(screen.getByLabelText('Customer survey'));
    fireEvent.click(screen.getByRole('option', { name: /Manual test rooftop/i }));
    fireEvent.click(screen.getByLabelText('Field technician'));
    fireEvent.click(screen.getByRole('option', { name: /Field Technician/i }));
    fireEvent.click(screen.getByLabelText('Visit date'));
    fireEvent.click(screen.getByRole('button', { name: 'Next week' }));
    fireEvent.click(screen.getByRole('button', { name: 'Assign site visit' }));
    expect(api.createFieldJob).not.toHaveBeenCalled();
    expect(screen.getByLabelText('Arrival time')).toHaveFocus();
    expect(screen.getByLabelText('Arrival time')).toHaveAttribute('aria-invalid', 'true');
  });
});
