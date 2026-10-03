import { Bell } from 'lucide-react';
import { useEffect, useState } from 'react';
import { NavLink } from 'react-router-dom';

import { api } from '../services/api';

export function NotificationBell() {
  const [unread, setUnread] = useState(0);

  useEffect(() => {
    const loadCount = () => api.getNotificationUnreadCount().then(setUnread).catch(() => undefined);
    void loadCount();
    const timer = window.setInterval(loadCount, 15000);
    return () => window.clearInterval(timer);
  }, []);

  return (
    <div className="notification-center">
      <NavLink
        to="/notifications"
        className={({ isActive }) => `notification-bell${isActive ? ' is-active' : ''}`}
        aria-label={`Open notifications${unread ? `, ${unread} unread` : ''}`}
      >
        <Bell size={20} />
        {unread > 0 && <span>{unread > 99 ? '99+' : unread}</span>}
      </NavLink>
    </div>
  );
}
