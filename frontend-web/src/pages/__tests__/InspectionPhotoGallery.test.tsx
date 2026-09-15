import { fireEvent, render, screen } from '@testing-library/react';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { InspectionPhotoGallery } from '../../components/InspectionPhotoGallery';

afterEach(() => vi.unstubAllGlobals());
describe('Site inspection photos', () => {
  it('loads the selected survey with authorization and opens its labelled photo', async () => {
    localStorage.setItem('smartsolar_token', 'test-token');
    const request = vi.fn().mockResolvedValue({ ok: true, json: async () => [{ id: 'photo-1', fieldJobId: 'job-1', technicianName: 'Site technician', photoType: 'ElectricalPanel', fileUrl: '/uploads/site-photos/test.jpg', fileName: 'test.jpg', createdAt: '2026-09-15T10:00:00Z' }] });
    vi.stubGlobal('fetch', request);
    render(<InspectionPhotoGallery surveyId="survey-1" />);
    const link = await screen.findByRole('link', { name: /Open electrical panel photo in full size/i });
    expect(link).toHaveAttribute('href', 'http://localhost:5116/uploads/site-photos/test.jpg');
    expect(link).toHaveAttribute('target', '_blank');
    expect(request).toHaveBeenCalledWith(expect.stringContaining('/surveys/survey-1/photos'), { headers: { Authorization: 'Bearer test-token' } });
    fireEvent.error(screen.getByRole('img'));
    expect(screen.getByText(/Photo unavailable/)).toBeInTheDocument();
  });
  it('distinguishes no photos from a failed request', async () => {
    const request = vi.fn().mockResolvedValueOnce({ ok: true, json: async () => [] }).mockResolvedValueOnce({ ok: false });
    vi.stubGlobal('fetch', request);
    render(<InspectionPhotoGallery jobId="job-1" />);
    expect(await screen.findByText(/No technician photos/)).toBeInTheDocument();
    fireEvent.click(screen.getByRole('button', { name: 'Refresh photos' }));
    expect(await screen.findByRole('alert')).toHaveTextContent('Unable to load site photos');
  });
});
