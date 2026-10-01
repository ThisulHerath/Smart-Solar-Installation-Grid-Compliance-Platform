import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { TechnicianJobsPage } from '../TechnicianJobsPage';

vi.mock('../../context/AuthContext', () => ({
  useAuth: () => ({ token: 'technician-token' }),
}));

const assignedJob = {
  id: 'job-1',
  propertyAddress: '45 Park Road, Colombo',
  customerName: 'Sample Homeowner',
  status: 'Assigned',
  priority: 'Medium',
  latitude: 6.9271,
  longitude: 79.8612,
};

describe('TechnicianJobsPage route planning', () => {
  beforeEach(() => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      ok: true,
      json: async () => [assignedJob],
    }));
  });

  it('requires the technician location and builds a route from technician to homeowner', async () => {
    const getCurrentPosition = vi.fn().mockImplementation(success => success({
      coords: { latitude: 7.2906, longitude: 80.6337, accuracy: 12.4 },
    }));
    Object.defineProperty(navigator, 'geolocation', {
      configurable: true,
      value: { getCurrentPosition },
    });

    render(<TechnicianJobsPage />);

    expect(await screen.findByText('Sample Homeowner')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /2\. Navigate to customer home/i })).toBeDisabled();

    fireEvent.click(screen.getByRole('button', { name: /1\. Get my current location/i }));

    const routeLink = await screen.findByRole('link', {
      name: /Navigate from my location to Sample Homeowner's home/i,
    });
    expect(getCurrentPosition).toHaveBeenCalledWith(
      expect.any(Function),
      expect.any(Function),
      expect.objectContaining({ enableHighAccuracy: true }),
    );
    expect(routeLink).toHaveAttribute('href', expect.stringContaining('origin=7.2906%2C80.6337'));
    expect(routeLink).toHaveAttribute('href', expect.stringContaining('destination=6.9271%2C79.8612'));
    expect(routeLink).toHaveAttribute('href', expect.stringContaining('travelmode=driving'));
    await waitFor(() => expect(screen.getByText(/approximately 12 m accuracy/i)).toBeInTheDocument());
  });
});
