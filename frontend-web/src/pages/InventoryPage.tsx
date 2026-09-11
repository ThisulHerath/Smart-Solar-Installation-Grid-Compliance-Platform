import { useEffect, useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { InventoryItem, Quote, Supplier, inventoryRequest as request } from '../services/inventoryService';
import './InventoryPage.css';

type Draft = Partial<InventoryItem>;
const empty: Draft = { sku: '', name: '', category: 'PANEL', manufacturer: '', model: '', supplierId: null, capacityWatts: 500, quantityInStock: 0, reorderLevel: 5, unitPriceUsd: 1, active: true };
const money = (value: number) => new Intl.NumberFormat('en-LK', { maximumFractionDigits: 2 }).format(value);

export function InventoryPage() {
  const { user } = useAuth();
  const canWrite = user?.roles.some(role => ['ADMINISTRATOR', 'INVENTORY_OFFICER'].includes(role));
  const [items, setItems] = useState<InventoryItem[]>([]), [total, setTotal] = useState(0);
  const [search, setSearch] = useState(''), [category, setCategory] = useState(''), [sort, setSort] = useState('name'), [low, setLow] = useState(false), [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true), [busy, setBusy] = useState(false), [error, setError] = useState(''), [notice, setNotice] = useState('');
  const [draft, setDraft] = useState<Draft | null>(null), [suppliers, setSuppliers] = useState<Supplier[]>([]);
  const [proposals, setProposals] = useState<{ id: string; recommendedKw: number }[]>([]), [proposal, setProposal] = useState(''), [quotes, setQuotes] = useState<Quote[]>([]);
  const [reservations, setReservations] = useState<{ id: string; equipmentQuoteId: string; itemName: string; quantity: number; status: string; totalPriceLkr: number }[]>([]);
  const [revision, setRevision] = useState(0);
  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    request<{ items: InventoryItem[]; total: number }>(`?${new URLSearchParams({ search, sort, page: String(page), pageSize: '10', lowStock: String(low), ...(category ? { category } : {}) })}`)
      .then(data => { if (!cancelled) { setItems(data.items); setTotal(data.total); } })
      .catch(e => { if (!cancelled) setError(e.message); }).finally(() => { if (!cancelled) setLoading(false); });
    return () => { cancelled = true; };
  }, [search, category, sort, low, page, revision]);
  useEffect(() => {
    Promise.all([request<Supplier[]>('/suppliers'), request<typeof proposals>('/proposals'), request<typeof reservations>('/reservations')])
      .then(([s, p, r]) => { setSuppliers(s); setProposals(p); setReservations(r); }).catch(e => setError(e.message));
  }, [revision]);
  useEffect(() => {
    let cancelled = false;
    setQuotes([]);
    if (proposal) request<Quote[]>(`/proposals/${proposal}/equipment`).then(data => { if (!cancelled) setQuotes(data); }).catch(e => { if (!cancelled) setError(e.message); });
    return () => { cancelled = true; };
  }, [proposal, revision]);
  async function act(action: () => Promise<unknown>, message: string) {
    setBusy(true); setError(''); setNotice('');
    try { await action(); setNotice(message); setRevision(x => x + 1); } catch (e) { setError((e as Error).message); } finally { setBusy(false); }
  }
  return <main className="inventory-page">
    <header className="inventory-heading"><div><p className="eyebrow">EQUIPMENT & PROCUREMENT</p><h1>Inventory</h1><p>Manage equipment, review pricing, and reserve stock for approved proposals.</p></div>
      {canWrite && <button className="btn btn-primary" onClick={() => setDraft({ ...empty })}>Add equipment</button>}</header>
    {error && <div role="alert" className="inventory-error">{error}</div>}{notice && <p role="status">{notice}</p>}
    <section className="inventory-panel">
      <div className="inventory-toolbar">
        <input aria-label="Search inventory" placeholder="Search name or SKU" value={search} onChange={e => { setSearch(e.target.value); setPage(1); }} />
        <select aria-label="Category" value={category} onChange={e => { setCategory(e.target.value); setPage(1); }}><option value="">All categories</option><option>PANEL</option><option>INVERTER</option></select>
        <select aria-label="Sort inventory" value={sort} onChange={e => setSort(e.target.value)}><option value="name">Name</option><option value="sku">SKU</option><option value="stock">Available stock</option><option value="price">USD price</option></select>
        <label><input type="checkbox" checked={low} onChange={e => { setLow(e.target.checked); setPage(1); }} /> Low stock only</label>
      </div>
      {loading ? <p role="status">Loading inventory…</p> : <div className="inventory-table"><table><thead><tr><th>Equipment</th><th>Supplier</th><th>Stock</th><th>Reserved</th><th>Available</th><th>USD / unit</th><th>Status</th>{canWrite && <th>Actions</th>}</tr></thead>
        <tbody>{items.map(item => <tr key={item.id}><td><strong>{item.name}</strong><small>{item.sku} · {item.capacityWatts} W · {item.model}</small></td><td>{item.supplier?.name || '—'}</td><td>{item.quantityInStock}</td><td>{item.reservedQuantity}</td><td>{item.availableQuantity}<small>Reorder at {item.reorderLevel}</small></td><td>${money(item.unitPriceUsd)}</td><td>{!item.active ? 'Inactive' : item.lowStock ? <span className="stock-low">Low stock</span> : 'Available'}</td>{canWrite && <td><button disabled={busy} onClick={() => setDraft({ ...item })}>Edit</button> {item.active && <button disabled={busy} onClick={() => act(() => request(`/${item.id}`, 'DELETE'), 'Equipment deactivated.')}>Deactivate</button>}</td>}</tr>)}</tbody></table>{items.length === 0 && <p>No equipment matches your filters.</p>}</div>}
      <div className="inventory-toolbar"><button disabled={page === 1} onClick={() => setPage(page - 1)}>Previous</button><span>Page {page} · {total} items</span><button disabled={page * 10 >= total} onClick={() => setPage(page + 1)}>Next</button></div>
    </section>
    {draft && canWrite && <section className="inventory-panel"><h2>{draft.id ? 'Edit equipment' : 'Add equipment'}</h2><form className="inventory-form" onSubmit={e => { e.preventDefault(); act(async () => { await request(draft.id ? `/${draft.id}` : '', draft.id ? 'PUT' : 'POST', draft); setDraft(null); }, 'Equipment saved.'); }}>
      {(['sku', 'name', 'manufacturer', 'model'] as const).map(key => <label key={key}>{key.toUpperCase()}<input required={key === 'sku' || key === 'name'} maxLength={key === 'sku' ? 80 : 200} value={draft[key] || ''} onChange={e => setDraft({ ...draft, [key]: e.target.value })} /></label>)}
      <label>Category<select value={draft.category} onChange={e => setDraft({ ...draft, category: e.target.value as InventoryItem['category'] })}><option>PANEL</option><option>INVERTER</option></select></label>
      <label>Supplier<select value={draft.supplierId || ''} onChange={e => setDraft({ ...draft, supplierId: e.target.value || null })}><option value="">No supplier</option>{suppliers.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}</select></label>
      {([['capacityWatts', 'Capacity (watts)'], ['quantityInStock', 'Stock quantity'], ['reorderLevel', 'Reorder level'], ['unitPriceUsd', 'Unit price (USD)']] as const).map(([key, label]) => <label key={key}>{label}<input type="number" required min={key === 'unitPriceUsd' || key === 'capacityWatts' ? 0.01 : 0} max={1000000} step={key === 'unitPriceUsd' || key === 'capacityWatts' ? '0.01' : '1'} value={draft[key]} onChange={e => setDraft({ ...draft, [key]: Number(e.target.value) })} /></label>)}
      <label><input type="checkbox" checked={draft.active} onChange={e => setDraft({ ...draft, active: e.target.checked })} /> Active</label><div><button disabled={busy} type="submit">Save equipment</button> <button type="button" onClick={() => setDraft(null)}>Cancel</button></div>
    </form></section>}
    {canWrite && <details className="inventory-panel"><summary>Add supplier</summary><form className="inventory-form" onSubmit={e => { e.preventDefault(); const form = e.currentTarget; const data = new FormData(form); act(async () => { await request('/suppliers', 'POST', { name: data.get('name'), contactEmail: data.get('email') || null, phone: data.get('phone') || null }); form.reset(); }, 'Supplier added.'); }}><label>Name<input name="name" required maxLength={200} /></label><label>Email<input name="email" type="email" /></label><label>Phone<input name="phone" maxLength={50} /></label><button disabled={busy}>Save supplier</button></form></details>}
    <section className="inventory-panel"><h2>Proposal equipment & pricing</h2><p>Project policy: 500 W panels and an inverter rated for the approved capacity. Equipment estimates exclude installation and taxes.</p>
      <div className="inventory-toolbar"><select aria-label="Approved proposal" value={proposal} onChange={e => setProposal(e.target.value)}><option value="">Select approved proposal</option>{proposals.map(p => <option key={p.id} value={p.id}>{p.id.slice(0, 8)} · {p.recommendedKw} kW</option>)}</select>{canWrite && <button disabled={!proposal || busy} onClick={() => act(() => request(`/proposals/${proposal}/price`, 'POST'), 'Pricing workflow finished. Review the result below.')}>Calculate equipment price</button>}</div>
      {quotes.length === 0 && <p>No pricing results for this selection.</p>}{quotes.map(quote => <article className="quote-card" key={quote.id}><h3>{quote.status} <small>{new Date(quote.createdAt).toLocaleString()}</small></h3>{quote.error && <p role="alert">{quote.error}</p>}
        {quote.result?.lines && <><p className="quote-total">LKR {money(quote.result.totalPriceLkr)}</p><p>USD → LKR {quote.result.exchangeRate} · Rate dated {new Date(quote.result.rateTimestamp).toLocaleString()}</p><ul>{quote.result.lines.map(line => <li key={line.inventoryItemId}>{line.quantity} × {line.name} — LKR {money(line.totalPriceLkr)}</li>)}</ul><small>Quote expires {new Date(quote.expiresAt).toLocaleString()}</small><details><summary>Workflow activity</summary><ol>{quote.result.executionLogs.map((log, i) => <li key={i}>{log}</li>)}</ol></details></>}
        {canWrite && quote.status === 'VALIDATED' && <button disabled={busy || new Date(quote.expiresAt) <= new Date()} onClick={() => act(() => request('/reserve', 'POST', { quoteId: quote.id }), 'Equipment reserved.')}>Reserve this equipment</button>}
        {canWrite && quote.status === 'RESERVED' && <button disabled={busy} onClick={() => act(() => request(`/${quote.id}/release`, 'POST'), 'Reservation released.')}>Release equipment</button>}
      </article>)}<p><a href="https://www.exchangerate-api.com" target="_blank" rel="noreferrer">Rates By Exchange Rate API</a></p>
    </section>
    <section className="inventory-panel"><h2>Reservations</h2>{reservations.length === 0 ? <p>No reservations yet.</p> : <div className="inventory-table"><table><thead><tr><th>Equipment</th><th>Quantity</th><th>Status</th><th>Equipment cost</th></tr></thead><tbody>{reservations.map(r => <tr key={r.id}><td>{r.itemName}</td><td>{r.quantity}</td><td>{r.status}</td><td>LKR {money(r.totalPriceLkr)}</td></tr>)}</tbody></table></div>}</section>
  </main>;
}
