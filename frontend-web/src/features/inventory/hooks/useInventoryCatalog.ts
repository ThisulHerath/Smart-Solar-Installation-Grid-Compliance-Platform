import { useEffect, useState } from 'react';
import { InventoryItem, inventoryRequest } from '../services/inventoryService';

/** Server state and cancellation belong here; the page only renders and edits filters. */
export function useInventoryCatalog(query: string, revision: number) {
  const [state, setState] = useState({ items: [] as InventoryItem[], total: 0, loading: true, error: '' });
  useEffect(() => {
    const controller = new AbortController();
    setState(previous => ({ ...previous, loading: true, error: '' }));
    const timer = window.setTimeout(() => {
      inventoryRequest<{ items: InventoryItem[]; total: number }>(`?${query}`, 'GET', undefined, controller.signal)
        .then(data => { if (!controller.signal.aborted) setState({ ...data, loading: false, error: '' }); })
        .catch(error => { if (!controller.signal.aborted) setState(previous => ({ ...previous, loading: false, error: error instanceof Error ? error.message : 'Unable to load equipment.' })); });
    }, 250);
    return () => { window.clearTimeout(timer); controller.abort(); };
  }, [query, revision]);
  return state;
}
