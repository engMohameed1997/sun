import React, { createContext, useContext } from 'react';
import { useWebSocket } from '../hooks/useWebSocket';

const NotificationContext = createContext();

export const NotificationProvider = ({ children }) => {
  const ws = useWebSocket();
  return (
    <NotificationContext.Provider value={ws}>
      {children}
    </NotificationContext.Provider>
  );
};

export const useNotification = () => useContext(NotificationContext);
