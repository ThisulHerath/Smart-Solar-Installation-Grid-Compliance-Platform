import { useState } from 'react';
import { Copy, Check } from 'lucide-react';
import './interaction.css';
export function RecordReference({ label, value }: { label: string; value: string }) {
  const [message, setMessage] = useState('');
  return <div className="record-reference"><span>{label}</span><code title={value}>{value}</code><button type="button" aria-label={`Copy ${label}`} onClick={async () => { try { await navigator.clipboard.writeText(value); setMessage('Copied'); } catch { setMessage('Select the reference to copy it.'); } }}>{message === 'Copied' ? <Check size={16} /> : <Copy size={16} />}</button><small role="status">{message}</small></div>;
}
