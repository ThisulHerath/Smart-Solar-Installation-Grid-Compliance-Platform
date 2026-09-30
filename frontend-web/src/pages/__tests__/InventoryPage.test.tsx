import { act, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { InventoryPage } from '../InventoryPage';
import { inventoryRequest } from '../../services/inventoryService';
import { useAuth } from '../../context/AuthContext';

vi.mock('../../services/inventoryService', () => ({ inventoryRequest: vi.fn() }));
vi.mock('../../context/AuthContext', () => ({ useAuth: vi.fn() }));
const request = vi.mocked(inventoryRequest);
const panel = { id: 'panel', name: 'Solar panel', sku: 'P-500', capacityWatts: 500, quantityInStock: 15, reservedQuantity: 10, availableQuantity: 5, reorderLevel: 5, unitPriceUsd: 450, active: true, lowStock: true, category: 'PANEL' };

describe('Inventory workflows', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.mocked(useAuth).mockReturnValue({ user: { roles: ['INVENTORY_OFFICER'] } } as ReturnType<typeof useAuth>);
    request.mockImplementation(async (path) => path.startsWith('?') ? { items: [panel], total: 1 } : []);
  });
  it('debounces query changes and aborts the previous request', async () => {
    vi.useFakeTimers();
    try {
      render(<InventoryPage />);
      await act(async () => { await vi.advanceTimersByTimeAsync(250); });
      const initial = request.mock.calls.find(call => call[0].startsWith('?'))!;
      const signal = initial[3]!;
      const search = screen.getByRole('combobox', { name: 'Search inventory' });
      fireEvent.change(search, { target: { value: 'P' } });
      expect(signal.aborted).toBe(true);
      await act(async () => { await vi.advanceTimersByTimeAsync(200); });
      fireEvent.change(search, { target: { value: 'Panel' } });
      await act(async () => { await vi.advanceTimersByTimeAsync(249); });
      expect(request.mock.calls.filter(call => call[0].startsWith('?'))).toHaveLength(1);
      await act(async () => { await vi.advanceTimersByTimeAsync(1); });
      expect(request.mock.calls.filter(call => call[0].startsWith('?'))).toHaveLength(2);
      expect(request.mock.calls.filter(call => call[0].startsWith('?'))[1][0]).toContain('search=Panel');
    } finally { vi.useRealTimers(); }
  });
  it('renders availability and low stock', async () => {
    render(<InventoryPage />);
    expect(await screen.findByText('Solar panel')).toBeInTheDocument();
    expect(screen.getByText('Low stock')).toBeInTheDocument();
    expect(screen.getByText('Reorder at 5')).toBeInTheDocument();
  });
  it('hides mutation controls from engineers', async () => {
    vi.mocked(useAuth).mockReturnValue({ user: { roles: ['SENIOR_ENGINEER'] } } as ReturnType<typeof useAuth>);
    render(<InventoryPage />); await screen.findByText('Solar panel');
    expect(screen.queryByRole('button', { name: 'Add equipment' })).not.toBeInTheDocument();
    expect(screen.queryByRole('button', { name: 'Deactivate' })).not.toBeInTheDocument();
  });
  it('shows service errors', async () => {
    request.mockRejectedValue(new Error('Inventory unavailable'));
    render(<InventoryPage />);
    expect(await screen.findByRole('alert')).toHaveTextContent('Inventory unavailable');
  });
  it('submits a new item without trusted client reservation fields', async () => {
    render(<InventoryPage />); await screen.findByText('Solar panel');
    fireEvent.click(screen.getByRole('button', { name: 'Add equipment' }));
    expect(screen.getByRole('dialog', { name: 'Add equipment' })).toBeInTheDocument();
    expect(screen.getByLabelText('SKU')).toHaveFocus();
    fireEvent.change(screen.getByLabelText('SKU'), { target: { value: 'P-NEW' } });
    fireEvent.change(screen.getByLabelText('Equipment name'), { target: { value: 'New panel' } });
    fireEvent.click(screen.getByRole('button', { name: 'Save equipment' }));
    await waitFor(() => expect(request).toHaveBeenCalledWith('', 'POST', expect.objectContaining({ sku: 'P-NEW', name: 'New panel' })));
  });
  it('keeps save errors inside the dialog and restores focus when cancelled', async () => {
    render(<InventoryPage />); await screen.findByText('Solar panel');
    const trigger = screen.getByRole('button', { name: 'Add equipment' });
    trigger.focus(); fireEvent.click(trigger);
    request.mockRejectedValue(new Error('SKU already exists'));
    fireEvent.change(screen.getByLabelText('SKU'), { target: { value: 'P-500' } });
    fireEvent.change(screen.getByLabelText('Equipment name'), { target: { value: 'Duplicate panel' } });
    fireEvent.click(screen.getByRole('button', { name: 'Save equipment' }));
    expect(await screen.findByRole('alert')).toHaveTextContent('SKU already exists');
    expect(screen.getByRole('dialog')).toContainElement(screen.getByRole('alert'));
    fireEvent.keyDown(screen.getByRole('dialog'), { key: 'Escape' });
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
    expect(trigger).toHaveFocus();
  });
  it('displays a failed quote and offers no reservation', async () => {
    request.mockImplementation(async path => path.startsWith('?') ? { items: [], total: 0 } : path === '/proposals' ? [{ id: 'approved', solarSurveyId: 'survey', projectName: 'Colombo Home Solar', fullName: 'Sample Homeowner', propertyAddress: 'Colombo', recommendedKw: 5, inventoryRequestStatus: 'REQUESTED', inventoryRequestedAt: new Date().toISOString() }] : path.includes('/equipment') ? [{ id: 'q', status: 'FAILED', error: 'Exchange service unavailable', createdAt: new Date().toISOString() }] : []);
    render(<InventoryPage />);
    await screen.findByRole('option', { name: 'Colombo Home Solar · Sample Homeowner · 5 kW · approved' });
    fireEvent.change(screen.getByLabelText('Approved proposal'), { target: { value: 'approved' } });
    expect(await screen.findByText('Exchange service unavailable')).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: 'Reserve this equipment' })).not.toBeInTheDocument();
  });

  it('shows the customer context and lets an engineer request inventory preparation', async () => {
    vi.mocked(useAuth).mockReturnValue({ user: { roles: ['SENIOR_ENGINEER'] } } as ReturnType<typeof useAuth>);
    const proposal = { id: 'proposal-12345678', solarSurveyId: 'survey', projectName: 'Malabe Family Solar', fullName: 'Nimali Perera', propertyAddress: 'Malabe rooftop', recommendedKw: 5, inventoryRequestStatus: 'NOT_REQUESTED', inventoryRequestedAt: null };
    request.mockImplementation(async path => path.startsWith('?') ? { items: [], total: 0 } : path === '/proposals' ? [proposal] : []);
    render(<InventoryPage />);
    await screen.findByRole('option', { name: 'Malabe Family Solar · Nimali Perera · 5 kW · proposal' });
    fireEvent.change(screen.getByLabelText('Approved proposal'), { target: { value: proposal.id } });
    expect(screen.getByLabelText('Selected customer and proposal')).toHaveTextContent('Nimali Perera');
    expect(screen.getByLabelText('Selected customer and proposal')).toHaveTextContent('Malabe rooftop');
    const requestButton = screen.getByRole('button', { name: 'Request inventory preparation' });
    await waitFor(() => expect(requestButton).toBeEnabled());
    fireEvent.click(requestButton);
    await waitFor(() => expect(request).toHaveBeenCalledWith(`/proposals/${proposal.id}/request`, 'POST'));
    expect(screen.queryByRole('button', { name: 'Calculate equipment price' })).not.toBeInTheDocument();
  });
});
