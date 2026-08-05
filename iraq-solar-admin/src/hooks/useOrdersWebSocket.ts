import { useEffect, useRef, useCallback, useState } from 'react';
import type {
  WSMessage,
  WSMessageType,
  OrderFull,
  OrderStatusChangedPayload,
} from '../types';

export type WSConnectionStatus = 'idle' | 'connecting' | 'connected' | 'disconnected' | 'error';

export interface UseOrdersWebSocketOptions {
  /** Called when a brand-new order arrives */
  onNewOrder?: (order: OrderFull) => void;
  /** Called when an order's status is changed by anyone */
  onStatusChanged?: (payload: OrderStatusChangedPayload) => void;
  /** Called when an order is cancelled */
  onOrderCancelled?: (payload: OrderStatusChangedPayload) => void;
  /** Base URL of the API (e.g. "http://localhost:8080"). Defaults to VITE_API_BASE_URL */
  baseUrl?: string;
  /** JWT token for auth */
  token?: string | null;
  /** Whether to attempt connection. Set false to lazily connect. */
  enabled?: boolean;
}

const MAX_BACKOFF_MS = 30_000; // 30 seconds max retry delay
const PING_INTERVAL_MS = 25_000; // send ping every 25s

function getWsUrl(baseUrl?: string): string {
  const base =
    baseUrl ||
    import.meta.env.VITE_API_BASE_URL ||
    'http://localhost:8080';
  // Convert http(s) → ws(s)
  return base.replace(/^http/, 'ws') + '/api/v1/ws/orders';
}

/**
 * useOrdersWebSocket
 *
 * Manages a WebSocket connection to the orders hub with:
 * - Automatic connection on mount
 * - Exponential backoff reconnect on disconnect/error
 * - Heartbeat pings every 25s to keep the connection alive
 * - Role-based callbacks (onNewOrder, onStatusChanged, onOrderCancelled)
 */
export function useOrdersWebSocket(options: UseOrdersWebSocketOptions = {}) {
  const {
    onNewOrder,
    onStatusChanged,
    onOrderCancelled,
    baseUrl,
    token,
    enabled = true,
  } = options;

  const [status, setStatus] = useState<WSConnectionStatus>('idle');
  const wsRef = useRef<WebSocket | null>(null);
  const retryCountRef = useRef(0);
  const retryTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const pingTimerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const manualCloseRef = useRef(false);

  // Use refs for callbacks so they don't trigger reconnect
  const onNewOrderRef = useRef(onNewOrder);
  const onStatusChangedRef = useRef(onStatusChanged);
  const onOrderCancelledRef = useRef(onOrderCancelled);
  useEffect(() => { onNewOrderRef.current = onNewOrder; }, [onNewOrder]);
  useEffect(() => { onStatusChangedRef.current = onStatusChanged; }, [onStatusChanged]);
  useEffect(() => { onOrderCancelledRef.current = onOrderCancelled; }, [onOrderCancelled]);

  const clearTimers = useCallback(() => {
    if (retryTimerRef.current) clearTimeout(retryTimerRef.current);
    if (pingTimerRef.current) clearInterval(pingTimerRef.current);
    retryTimerRef.current = null;
    pingTimerRef.current = null;
  }, []);

  const startPingInterval = useCallback((ws: WebSocket) => {
    pingTimerRef.current = setInterval(() => {
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({ type: 'ping' as WSMessageType }));
      }
    }, PING_INTERVAL_MS);
  }, []);

  const connect = useCallback(() => {
    if (!enabled) return;
    if (wsRef.current && wsRef.current.readyState <= WebSocket.OPEN) return;

    manualCloseRef.current = false;
    setStatus('connecting');

    const wsUrl = getWsUrl(baseUrl);
    // Append token as query param (server reads it from query if not in headers)
    const url = token ? `${wsUrl}?token=${encodeURIComponent(token)}` : wsUrl;

    const ws = new WebSocket(url);
    wsRef.current = ws;

    ws.onopen = () => {
      retryCountRef.current = 0;
      setStatus('connected');
      startPingInterval(ws);
    };

    ws.onmessage = (event: MessageEvent) => {
      try {
        const msg: WSMessage = JSON.parse(event.data as string);
        switch (msg.type) {
          case 'order.new':
            onNewOrderRef.current?.(msg.payload as OrderFull);
            break;
          case 'order.status_changed':
            onStatusChangedRef.current?.(msg.payload as OrderStatusChangedPayload);
            break;
          case 'order.cancelled':
            onOrderCancelledRef.current?.(msg.payload as OrderStatusChangedPayload);
            break;
          // pong is handled transparently
          default:
            break;
        }
      } catch {
        // Ignore parse errors
      }
    };

    ws.onerror = () => {
      setStatus('error');
    };

    ws.onclose = () => {
      clearTimers();
      if (manualCloseRef.current) {
        setStatus('disconnected');
        return;
      }
      // Exponential backoff reconnect
      setStatus('disconnected');
      const backoff = Math.min(1000 * Math.pow(2, retryCountRef.current), MAX_BACKOFF_MS);
      retryCountRef.current += 1;
      retryTimerRef.current = setTimeout(connect, backoff);
    };
  }, [enabled, baseUrl, token, startPingInterval, clearTimers]);

function safelyCloseWebSocket(ws: WebSocket) {
  ws.onmessage = null;
  ws.onerror = null;

  if (ws.readyState === WebSocket.CONNECTING) {
    ws.onopen = () => {
      ws.onclose = null;
      ws.close();
    };
    ws.onclose = null;
  } else {
    ws.onopen = null;
    ws.onclose = null;
    if (ws.readyState === WebSocket.OPEN) {
      ws.close();
    }
  }
}

  const disconnect = useCallback(() => {
    manualCloseRef.current = true;
    clearTimers();
    if (wsRef.current) {
      const ws = wsRef.current;
      wsRef.current = null;
      safelyCloseWebSocket(ws);
    }
    setStatus('disconnected');
  }, [clearTimers]);

  // Connect on mount / when token changes
  useEffect(() => {
    if (enabled) {
      connect();
    }
    return () => {
      manualCloseRef.current = true;
      clearTimers();
      if (wsRef.current) {
        const ws = wsRef.current;
        wsRef.current = null;
        safelyCloseWebSocket(ws);
      }
    };
  }, [enabled, token]); // eslint-disable-line react-hooks/exhaustive-deps

  return { status, connect, disconnect };
}
