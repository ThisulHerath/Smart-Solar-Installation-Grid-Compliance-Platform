import { useEffect, useState } from 'react';
import { Quote } from '../services/inventoryService';

const money = (n: number) => n.toLocaleString('en-LK', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const stages: Record<string, [string, string]> = {
  EquipmentRequirements: ['System requirements reviewed', 'Panel rating and inverter capacity checked.'],
  ExchangeRateTool: ['Exchange rate verified', 'USD to LKR conversion checked against the rate provider.'],
  EquipmentPricingAgent: ['Equipment estimate prepared', 'Compatible equipment and quantities priced.'],
  PricingValidator: ['Calculations checked', 'Catalog prices and line totals independently verified.'],
  InventoryAvailabilityValidator: ['Stock availability checked', 'Availability at quotation time checked; checked again when reserving.'],
  FormatResult: ['Estimate recorded', 'Results returned for storage and staff review.'],
};

export function EquipmentEstimate({ quote, canWrite, busy, onReserve, onRelease }: { quote: Quote; canWrite: boolean; busy: boolean; onReserve: () => void; onRelease: () => void }) {
  const [now, setNow] = useState(Date.now());
  useEffect(() => { const timer = setInterval(() => setNow(Date.now()), 30000); return () => clearInterval(timer); }, []);
  const expired = new Date(quote.expiresAt).getTime() <= now;
  const status = quote.status === 'VALIDATED' && expired ? 'EXPIRED' : quote.status;
  const labels: Record<string, string> = { VALIDATED: 'Ready to reserve', RESERVED: 'Equipment reserved', RELEASED: 'Reservation released', FAILED: 'Estimate unavailable', PROCESSING: 'Preparing estimate', EXPIRED: 'Estimate expired' };
  return <article className="estimate-sheet">
    <header className="estimate-heading"><div><p className="eyebrow">EQUIPMENT ESTIMATE</p><h3>Quote {quote.id.slice(0, 8).toUpperCase()}</h3><p>Prepared {new Date(quote.createdAt).toLocaleString()}</p></div><span className={`inventory-status status-${status.toLowerCase()}`}>{labels[status] || status}</span></header>
    {quote.error && <p role="alert" className="inventory-error">{quote.error}</p>}
    {quote.result?.lines && <>
      <div className="inventory-table estimate-lines"><table><caption className="sr-only">Equipment estimate line items</caption><thead><tr><th>Equipment</th><th>Quantity</th><th>Unit price · LKR</th><th>Amount · LKR</th></tr></thead><tbody>
        {quote.result.lines.map(line => <tr key={line.inventoryItemId}><td><strong>{line.name}</strong><small>USD {money(line.unitPriceUsd)} / unit</small></td><td>{line.quantity}</td><td>{money(line.unitPriceLkr)}</td><td>{money(line.totalPriceLkr)}</td></tr>)}
      </tbody></table></div>
      <div className="estimate-summary"><div><strong>What this estimate covers</strong><p>Equipment only. Installation charges and taxes are excluded.</p><small>{status === 'RESERVED' ? 'Stock is held against this proposal.' : status === 'RELEASED' ? 'Stock has been returned to availability.' : `Valid for reservation until ${new Date(quote.expiresAt).toLocaleString()}`}</small></div><div className="estimate-total"><span>Total equipment estimate</span><strong><small>LKR</small> {money(quote.result.totalPriceLkr)}</strong></div></div>
      <div className="estimate-conversion"><span>Conversion used: <strong>USD 1 = LKR {quote.result.exchangeRate.toLocaleString('en-LK', { maximumFractionDigits: 6 })}</strong></span><span>Rate updated {new Date(quote.result.rateTimestamp).toLocaleString()}</span></div>
      <details className="estimate-workflow"><summary>How this estimate was prepared <span>{quote.result.executionLogs?.length || 0} recorded steps</span></summary>
        <ol>{(quote.result.executionLogs || []).map((log, i) => { const stage = stages[log.split(':')[0]]; return <li key={i}><span className="estimate-step-number">{i + 1}</span><div><strong>{stage?.[0] || 'Recorded workflow activity'}</strong><p>{stage?.[1] || log}</p></div></li>; })}</ol>
        <details className="estimate-technical"><summary>Technical execution record</summary><ul>{(quote.result.executionLogs || []).map((log, i) => <li key={i}>{log}</li>)}</ul></details>
      </details>
    </>}
    <footer className="estimate-actions"><div>{canWrite && quote.status === 'VALIDATED' && <button disabled={busy || expired} onClick={onReserve}>{expired ? 'Request a new estimate above' : 'Reserve this equipment'}</button>}
      {canWrite && quote.status === 'RESERVED' && <button className="inventory-secondary" disabled={busy} onClick={onRelease}>Release equipment</button>}</div><small>Reference {quote.id.slice(0, 8).toUpperCase()}</small></footer>
  </article>;
}
