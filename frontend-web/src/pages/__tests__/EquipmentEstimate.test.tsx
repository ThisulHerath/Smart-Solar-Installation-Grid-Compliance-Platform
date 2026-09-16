import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { EquipmentEstimate } from '../../components/EquipmentEstimate';
import { Quote } from '../../services/inventoryService';

const quote: Quote = { id: 'quote123456', engineeringProposalId: 'proposal', status: 'VALIDATED', createdAt: '2026-09-15T00:00:00Z', expiresAt: '2099-01-01T00:00:00Z', result: {
  exchangeRate: 300, rateTimestamp: '2026-09-15T00:00:00Z', totalPriceLkr: 450000,
  lines: [{ inventoryItemId: 'panel', name: 'Solar panel', quantity: 10, unitPriceUsd: 100, unitPriceLkr: 30000, totalPriceLkr: 300000 }, { inventoryItemId: 'inverter', name: 'Inverter', quantity: 1, unitPriceUsd: 500, unitPriceLkr: 150000, totalPriceLkr: 150000 }],
  executionLogs: ['ExchangeRateTool: validated provider response'] } };
describe('Equipment estimate', () => {
  it('itemizes the stored estimate and shows recorded workflow stages', () => {
    const reserve = vi.fn();
    render(<EquipmentEstimate quote={quote} canWrite busy={false} onReserve={reserve} onRelease={vi.fn()} />);
    expect(screen.getByText('450,000.00', { exact: false })).toBeInTheDocument();
    expect(screen.getByText('30,000.00')).toBeInTheDocument();
    expect(screen.getByText('Exchange rate verified')).toBeInTheDocument();
    expect(screen.queryByText('Stock availability checked')).not.toBeInTheDocument();
    fireEvent.click(screen.getByRole('button', { name: 'Reserve this equipment' }));
    expect(reserve).toHaveBeenCalledOnce();
  });
  it('prevents reservation of an expired quote', () => {
    render(<EquipmentEstimate quote={{ ...quote, expiresAt: '2020-01-01T00:00:00Z' }} canWrite busy={false} onReserve={vi.fn()} onRelease={vi.fn()} />);
    expect(screen.getByText('Estimate expired')).toBeInTheDocument();
    expect(screen.getByRole('button')).toBeDisabled();
  });
});
