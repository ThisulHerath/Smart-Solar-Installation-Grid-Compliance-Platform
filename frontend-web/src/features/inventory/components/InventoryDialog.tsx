import { ReactNode, useEffect, useRef } from 'react';

export function InventoryDialog({ title, busy, onClose, children }: { title: string; busy: boolean; onClose: () => void; children: ReactNode }) {
  const panel = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const previous = document.activeElement as HTMLElement | null;
    const overflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    panel.current?.querySelector<HTMLElement>('input, select, button')?.focus();
    return () => { document.body.style.overflow = overflow; previous?.focus(); };
  }, []);
  return <div className="inventory-dialog-backdrop"><div ref={panel} className="inventory-dialog" role="dialog" aria-modal="true" aria-labelledby="inventory-dialog-title" onKeyDown={e => {
    if (e.key === 'Escape' && !busy) { e.preventDefault(); onClose(); }
    if (e.key === 'Tab') {
      const elements = Array.from(panel.current?.querySelectorAll<HTMLElement>('button:not(:disabled), input:not(:disabled), select:not(:disabled), [tabindex="0"]') || []);
      const first = elements[0], last = elements[elements.length - 1];
      if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last?.focus(); }
      if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first?.focus(); }
    }
  }}>
    <header><p className="eyebrow">SMARTSOLAR · EQUIPMENT CATALOG</p><h2 id="inventory-dialog-title">{title}</h2><p>Keep your equipment specifications and stock records up to date.</p></header>
    {children}
  </div></div>;
}
