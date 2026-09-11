import { fireEvent, render, screen, waitFor } from '@testing-library/react';
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
    fireEvent.change(screen.getByLabelText('SKU'), { target: { value: 'P-NEW' } });
    fireEvent.change(screen.getByLabelText('NAME'), { target: { value: 'New panel' } });
    fireEvent.click(screen.getByRole('button', { name: 'Save equipment' }));
    await waitFor(() => expect(request).toHaveBeenCalledWith('', 'POST', expect.objectContaining({ sku: 'P-NEW', name: 'New panel' })));
  });
  it('displays a failed quote and offers no reservation', async () => {
    request.mockImplementation(async path => path.startsWith('?') ? { items: [], total: 0 } : path === '/proposals' ? [{ id: 'approved', recommendedKw: 5 }] : path.includes('/equipment') ? [{ id: 'q', status: 'FAILED', error: 'Exchange service unavailable', createdAt: new Date().toISOString() }] : []);
    render(<InventoryPage />);
    await screen.findByRole('option', { name: 'approved · 5 kW' });
    fireEvent.change(screen.getByLabelText('Approved proposal'), { target: { value: 'approved' } });
    expect(await screen.findByText('Exchange service unavailable')).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: 'Reserve this equipment' })).not.toBeInTheDocument();
  });
});
