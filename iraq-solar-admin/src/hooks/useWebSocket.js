import { useState, useEffect, useRef } from 'react';
import { useAuth } from './useAuth';
import { API_BASE_URL } from '../utils/constants';

export const useWebSocket = () => {
  const [notifications, setNotifications] = useState([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const { token } = useAuth();
  const ws = useRef(null);

  useEffect(() => {
    if (!token) return;

    const wsUrl = API_BASE_URL.replace('http', 'ws') + '/admin/notifications/ws?token=' + token;
    
    const connect = () => {
      ws.current = new WebSocket(wsUrl);
      
      ws.current.onmessage = (event) => {
        const data = JSON.parse(event.data);
        setNotifications((prev) => [data, ...prev]);
        setUnreadCount((prev) => prev + 1);
      };

      ws.current.onclose = () => {
        setTimeout(connect, 3000); // Reconnect
      };
    };

    connect();

    return () => {
      if (ws.current) {
        ws.current.close();
      }
    };
  }, [token]);

  const markAsRead = (id) => {
    setNotifications(notifications.map(n => n.id === id ? { ...n, read: true } : n));
    setUnreadCount(Math.max(0, unreadCount - 1));
  };

  return { notifications, unreadCount, markAsRead };
};
