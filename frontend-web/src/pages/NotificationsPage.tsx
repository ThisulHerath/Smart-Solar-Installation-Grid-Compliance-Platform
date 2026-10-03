import {
  Bell,
  CheckCheck,
  ClipboardList,
  HardHat,
  RefreshCw,
  Trash2,
} from 'lucide-react';
import { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';

import { api } from '../services/api';
import { AppNotification } from '../types/auth';
import '../styles/notifications.css';

type Filter = 'all' | 'unread';

function relativeTime(value: string) {
  const seconds = Math.max(1, Math.floor((Date.now() - new Date(value).getTime()) / 1000));
  if (seconds < 60) return 'Just now';
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
  if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
  return `${Math.floor(seconds / 86400)}d ago`;
}

function NotificationIcon({ type }: { type: string }) {
  if (type === 'FIELD_JOB_ASSIGNED') return <HardHat size={22} />;
  return <ClipboardList size={22} />;
}

export function NotificationsPage() {
  const navigate = useNavigate();
  const [items, setItems] = useState<AppNotification[]>([]);
  const [filter, setFilter] = useState<Filter>('all');
  const [loading, setLoading] = useState(true);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');

  const unreadCount = items.filter(item => !item.isRead).length;
  const visibleItems = useMemo(
    () => filter === 'unread' ? items.filter(item => !item.isRead) : items,
    [filter, items],
  );

  const load = async () => {
    setLoading(true);
    setError('');
    try {
      setItems(await api.getNotifications(100));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unable to load notifications.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { void load(); }, []);

  const openItem = async (item: AppNotification) => {
    if (!item.isRead) {
      await api.markNotificationRead(item.id);
      setItems(values => values.map(value => value.id === item.id ? { ...value, isRead: true } : value));
    }
    if (item.actionUrl) navigate(item.actionUrl);
  };

  const deleteItem = async (item: AppNotification) => {
    setBusyId(item.id);
    setError('');
    try {
      await api.deleteNotification(item.id);
      setItems(values => values.filter(value => value.id !== item.id));
      setNotice('Notification deleted.');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unable to delete notification.');
    } finally {
      setBusyId(null);
    }
  };

  const markAllRead = async () => {
    setError('');
    try {
      await api.markAllNotificationsRead();
      setItems(values => values.map(value => ({ ...value, isRead: true })));
      setNotice('All notifications marked as read.');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unable to update notifications.');
    }
  };

  const clearRead = async () => {
    setError('');
    try {
      const count = await api.deleteReadNotifications();
      setItems(values => values.filter(value => !value.isRead));
      setNotice(count ? `${count} read notification${count === 1 ? '' : 's'} deleted.` : 'There are no read notifications to delete.');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unable to clear read notifications.');
    }
  };

  return (
    <main className="notifications-page">
      <header className="notifications-hero">
        <div className="notifications-hero__icon"><Bell size={27} /></div>
        <div>
          <p>MESSAGE CENTRE</p>
          <h1>Notifications</h1>
          <span>Keep track of new surveys, assigned field work, visits, and project updates.</span>
        </div>
        <button type="button" className="notifications-refresh" onClick={() => void load()} disabled={loading}>
          <RefreshCw size={17} className={loading ? 'is-spinning' : ''} /> Refresh
        </button>
      </header>

      <section className="notifications-toolbar" aria-label="Notification controls">
        <div className="notification-filters">
          <button type="button" className={filter === 'all' ? 'is-active' : ''} onClick={() => setFilter('all')}>All <span>{items.length}</span></button>
          <button type="button" className={filter === 'unread' ? 'is-active' : ''} onClick={() => setFilter('unread')}>Unread <span>{unreadCount}</span></button>
        </div>
        <div className="notification-actions">
          <button type="button" onClick={() => void markAllRead()} disabled={!unreadCount}><CheckCheck size={16} /> Mark all read</button>
          <button type="button" onClick={() => void clearRead()} disabled={!items.some(item => item.isRead)}><Trash2 size={16} /> Clear read</button>
        </div>
      </section>

      {error && <p className="notifications-alert is-error" role="alert">{error}</p>}
      {notice && !error && <p className="notifications-alert" role="status">{notice}</p>}

      <section className="notifications-list" aria-live="polite">
        {loading && <div className="notifications-empty"><RefreshCw className="is-spinning" /><strong>Loading notifications…</strong></div>}
        {!loading && visibleItems.length === 0 && (
          <div className="notifications-empty">
            <Bell size={34} />
            <strong>{filter === 'unread' ? 'You are all caught up' : 'No notifications yet'}</strong>
            <span>{filter === 'unread' ? 'New updates will appear here.' : 'Project and assignment updates will appear here when they arrive.'}</span>
          </div>
        )}
        {!loading && visibleItems.map(item => (
          <article key={item.id} className={`notification-card${item.isRead ? '' : ' is-unread'}`}>
            <button type="button" className="notification-card__main" onClick={() => void openItem(item)}>
              <span className="notification-card__icon"><NotificationIcon type={item.type} /></span>
              <span className="notification-card__copy">
                <span className="notification-card__heading"><strong>{item.title}</strong>{!item.isRead && <i>New</i>}</span>
                <span className="notification-card__message">{item.message}</span>
                <time dateTime={item.createdAt} title={new Date(item.createdAt).toLocaleString()}>{relativeTime(item.createdAt)}</time>
              </span>
            </button>
            <button
              type="button"
              className="notification-card__delete"
              aria-label={`Delete ${item.title}`}
              title="Delete notification"
              disabled={busyId === item.id}
              onClick={() => void deleteItem(item)}
            >
              <Trash2 size={17} />
            </button>
          </article>
        ))}
      </section>
    </main>
  );
}
