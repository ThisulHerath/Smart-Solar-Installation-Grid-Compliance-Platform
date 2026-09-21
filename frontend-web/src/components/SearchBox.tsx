import { useEffect, useId, useRef, useState } from 'react';
import { Search, X } from 'lucide-react';
import './interaction.css';

export function SearchBox({ value, onChange, label, suggestions = [], loading = false, scope }: {
  value: string; onChange: (value: string) => void; label: string; suggestions?: string[]; loading?: boolean; scope: string;
}) {
  const input = useRef<HTMLInputElement>(null), id = useId();
  const [open, setOpen] = useState(false), [active, setActive] = useState(-1);
  const key = `smartsolar-search-${scope}`;
  const [recent, setRecent] = useState<string[]>(() => {
    try { const data: unknown = JSON.parse(localStorage.getItem(key) || '[]'); return Array.isArray(data) ? data.filter((v): v is string => typeof v === 'string').slice(0, 5) : []; } catch { return []; }
  });
  const options = loading ? [] : [...new Set(value ? suggestions.filter(s => s.toLowerCase().includes(value.toLowerCase())) : recent)].slice(0, 5);
  useEffect(() => {
    const shortcut = (e: KeyboardEvent) => { if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k') { e.preventDefault(); input.current?.focus(); setOpen(true); } };
    window.addEventListener('keydown', shortcut); return () => window.removeEventListener('keydown', shortcut);
  }, []);
  const select = (text: string) => {
    onChange(text); setOpen(false); setActive(-1);
    if (text.trim()) { const next = [text.trim(), ...recent.filter(s => s !== text.trim())].slice(0, 5); setRecent(next); try { localStorage.setItem(key, JSON.stringify(next)); } catch { /* Search works when storage is unavailable. */ } }
  };
  return <div className="solar-search" onBlur={e => { if (!e.currentTarget.contains(e.relatedTarget)) setOpen(false); }}>
    <label htmlFor={id}>{label}</label><div className="solar-search-input"><Search size={18} aria-hidden="true" />
      <input id={id} ref={input} role="combobox" autoComplete="off" aria-autocomplete="list" aria-expanded={open} aria-controls={`${id}-list`} aria-activedescendant={open && active >= 0 ? `${id}-${active}` : undefined}
        value={value} placeholder="Search by name or reference" spellCheck={false} onChange={e => { onChange(e.target.value); setOpen(false); setActive(-1); }}
        onKeyDown={e => {
          if (e.key === 'Escape') { setOpen(false); setActive(-1); }
          if (e.key === 'ArrowDown' || e.key === 'ArrowUp') { e.preventDefault(); setOpen(true); setActive(n => options.length ? (n + (e.key === 'ArrowDown' ? 1 : -1) + options.length) % options.length : -1); }
          if (e.key === 'Enter') { e.preventDefault(); select(active >= 0 && options[active] ? options[active] : value); }
        }} />
      {value ? <button type="button" aria-label="Clear search" onClick={() => { onChange(''); setActive(-1); input.current?.focus(); }}><X size={16} /></button> : null}
    </div>
    {open && <div className="solar-search-menu"><small>{value ? 'Suggestions' : 'Recent searches'}</small>
      {loading ? <div role="status" aria-label="Loading search results" className="search-skeleton"><span /><span /><span /></div> : null}
      <ul id={`${id}-list`} role="listbox" aria-label="Search suggestions">{!loading && options.map((option, index) => <li key={option} id={`${id}-${index}`} role="option" aria-selected={index === active} onMouseDown={e => e.preventDefault()} onClick={() => select(option)}>{option}</li>)}</ul>
      {!loading && !options.length && <p>{value ? 'No suggestions. Try a shorter name, check the reference, or clear your filters.' : 'Search for a record, then press Enter to save it here.'}</p>}
      {!value && recent.length > 0 && <button type="button" onClick={() => { setRecent([]); try { localStorage.removeItem(key); } catch { /* optional storage */ } }}>Clear recent searches</button>}
    </div>}
  </div>;
}
