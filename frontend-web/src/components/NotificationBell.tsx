import { Bell, CheckCheck, ClipboardList, HardHat } from 'lucide-react';
import { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { api } from '../services/api';
import { AppNotification } from '../types/auth';

function relativeTime(value: string) {
  const seconds = Math.max(1, Math.floor((Date.now() - new Date(value).getTime()) / 1000));
  if (seconds < 60) return 'Just now';
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
  if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
  return `${Math.floor(seconds / 86400)}d ago`;
}

export function NotificationBell() {
  const navigate = useNavigate();
  const root = useRef<HTMLDivElement>(null);
  const [open, setOpen] = useState(false);
  const [items, setItems] = useState<AppNotification[]>([]);
  const [unread, setUnread] = useState(0);
  const [loading, setLoading] = useState(false);

  const loadCount = async () => setUnread(await api.getNotificationUnreadCount());
  const loadItems = async () => {
    setLoading(true);
    try { setItems(await api.getNotifications()); } finally { setLoading(false); }
  };

  useEffect(() => {
    loadCount().catch(() => undefined);
    const timer = window.setInterval(() => loadCount().catch(() => undefined), 15000);
    return () => window.clearInterval(timer);
  }, []);

  useEffect(() => {
    const close = (event: MouseEvent) => { if (!root.current?.contains(event.target as Node)) setOpen(false); };
    document.addEventListener('mousedown', close);
    return () => document.removeEventListener('mousedown', close);
  }, []);

  const toggle = () => {
    const next = !open;
    setOpen(next);
    if (next) loadItems().catch(() => undefined);
  };

  const openItem = async (item: AppNotification) => {
    if (!item.isRead) {
      await api.markNotificationRead(item.id);
      setItems(values => values.map(value => value.id === item.id ? { ...value, isRead: true } : value));
      setUnread(value => Math.max(0, value - 1));
    }
    setOpen(false);
    if (item.actionUrl) navigate(item.actionUrl);
  };

  return <div className="notification-center" ref={root}>
    <button type="button" className="notification-bell" aria-label={`Notifications${unread ? `, ${unread} unread` : ''}`} aria-expanded={open} onClick={toggle}>
      <Bell size={20} />
      {unread > 0 && <span>{unread > 99 ? '99+' : unread}</span>}
    </button>
    {open && <section className="notification-panel" aria-label="Notifications">
      <header><div><strong>Notifications</strong><small>{unread ? `${unread} unread` : 'You are all caught up'}</small></div>{unread > 0 && <button type="button" onClick={async () => { await api.markAllNotificationsRead(); setUnread(0); setItems(values => values.map(value => ({ ...value, isRead: true }))); }}><CheckCheck size={15} /> Mark all read</button>}</header>
      <div className="notification-list">
        {loading && <p className="notification-state">Loading notifications…</p>}
        {!loading && !items.length && <p className="notification-state">No notifications yet.</p>}
        {!loading && items.map(item => <button key={item.id} type="button" className={`notification-item${item.isRead ? '' : ' is-unread'}`} onClick={() => openItem(item)}>
          <span className="notification-item__icon">{item.type === 'FIELD_JOB_ASSIGNED' ? <HardHat size={18} /> : <ClipboardList size={18} />}</span>
          <span><strong>{item.title}</strong><small>{item.message}</small><time>{relativeTime(item.createdAt)}</time></span>
        </button>)}
      </div>
    </section>}
  </div>;
}
