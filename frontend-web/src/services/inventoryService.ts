export interface Supplier { id: string; name: string }
export interface InventoryItem {
  id: string; sku: string; name: string; category: 'PANEL' | 'INVERTER'; manufacturer: string; model: string;
  supplierId: string | null; supplier?: Supplier; capacityWatts: number; quantityInStock: number; reservedQuantity: number;
  availableQuantity: number; reorderLevel: number; unitPriceUsd: number; active: boolean; lowStock: boolean; version: string;
}
export interface Quote {
  id: string; engineeringProposalId: string; status: string; error?: string; createdAt: string; expiresAt: string;
  result?: { exchangeRate: number; rateTimestamp: string; totalPriceLkr: number; executionLogs: string[];
    lines: { inventoryItemId: string; name: string; quantity: number; unitPriceUsd: number; unitPriceLkr: number; totalPriceLkr: number }[] };
}
export async function inventoryRequest<T>(path: string, method = 'GET', body?: unknown): Promise<T> {
  const response = await fetch(`${import.meta.env.VITE_API_BASE_URL || 'http://localhost:5116'}/api/inventory${path}`, {
    method, headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${localStorage.getItem('smartsolar_token') || ''}` },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  if (!response.ok) {
    const error = await response.json().catch(() => ({}));
    throw new Error(error.message || error.detail || (error.errors ? Object.values(error.errors).flat().join(' ') : `Request failed (${response.status}).`));
  }
  return response.status === 204 ? undefined as T : response.json();
}
