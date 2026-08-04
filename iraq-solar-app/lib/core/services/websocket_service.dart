import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' show debugPrint, ValueNotifier;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../network/api_client.dart';
import 'auth_storage.dart';

/// Connection status for the WebSocket service.
enum WSConnectionStatus { disconnected, connecting, connected, error }

/// Parsed WebSocket message from the server.
class WSMessage {
  final int version;
  final String id;
  final String type; // "order", "notification", "system"
  final String event; // "order.status_changed", "notification.created", etc.
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  WSMessage({
    required this.version,
    required this.id,
    required this.type,
    required this.event,
    required this.payload,
    required this.timestamp,
  });

  factory WSMessage.fromJson(Map<String, dynamic> json) {
    return WSMessage(
      version: json['version'] ?? 1,
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      event: json['event'] ?? '',
      payload: json['payload'] is Map<String, dynamic>
          ? json['payload'] as Map<String, dynamic>
          : <String, dynamic>{},
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Whether this is a notification message.
  bool get isNotification => type == 'notification';

  /// Whether this is an order message.
  bool get isOrder => type == 'order';
}

/// Singleton WebSocket service for real-time notifications.
///
/// Uses the same Singleton pattern as [CartService].
/// Reads the JWT token fresh from [AuthStorageService] on every connection attempt,
/// supporting token refresh without service restart.
class WebSocketService {
  static final WebSocketService instance = WebSocketService._internal();
  WebSocketService._internal();

  // --- Public Notifiers ---

  /// Current connection status.
  final ValueNotifier<WSConnectionStatus> connectionStatus =
      ValueNotifier(WSConnectionStatus.disconnected);

  /// Unread notification count — updated by the service, read by UI.
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier(0);

  // --- Stream for incoming messages ---

  final StreamController<WSMessage> _messageController =
      StreamController<WSMessage>.broadcast();

  /// Stream of all incoming WebSocket messages.
  Stream<WSMessage> get messageStream => _messageController.stream;

  /// Convenience stream: only notification messages.
  Stream<WSMessage> get notificationStream =>
      messageStream.where((msg) => msg.isNotification);

  /// Convenience stream: only order messages.
  Stream<WSMessage> get orderStream =>
      messageStream.where((msg) => msg.isOrder);

  // --- Internal State ---

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectDelay = 30; // seconds
  bool _intentionalDisconnect = false;

  /// Connect to the WebSocket server.
  ///
  /// Reads the JWT token fresh from [AuthStorageService] each time.
  Future<void> connect() async {
    // Prevent multiple simultaneous connections
    if (connectionStatus.value == WSConnectionStatus.connecting ||
        connectionStatus.value == WSConnectionStatus.connected) {
      return;
    }

    _intentionalDisconnect = false;
    connectionStatus.value = WSConnectionStatus.connecting;

    try {
      final token = await AuthStorageService.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('[WebSocketService] No token available, skipping connection');
        connectionStatus.value = WSConnectionStatus.disconnected;
        return;
      }

      final wsUrl = _buildWsUrl(token);
      debugPrint('[WebSocketService] Connecting to $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Wait for the connection to be ready
      await _channel!.ready;

      connectionStatus.value = WSConnectionStatus.connected;
      _reconnectAttempts = 0;
      debugPrint('[WebSocketService] Connected successfully');

      // Start heartbeat
      _startHeartbeat();

      // Listen for messages
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('[WebSocketService] Connection failed: $e');
      connectionStatus.value = WSConnectionStatus.error;
      _scheduleReconnect();
    }
  }

  /// Disconnect cleanly.
  void disconnect() {
    _intentionalDisconnect = true;
    _cleanup();
    connectionStatus.value = WSConnectionStatus.disconnected;
    debugPrint('[WebSocketService] Disconnected intentionally');
  }

  /// Increment unread count (called when a new notification arrives).
  void incrementUnread() {
    unreadCountNotifier.value++;
  }

  /// Decrement unread count (called when a notification is marked as read).
  void decrementUnread() {
    if (unreadCountNotifier.value > 0) {
      unreadCountNotifier.value--;
    }
  }

  /// Set unread count to a specific value (called after REST API fetch).
  void setUnread(int count) {
    unreadCountNotifier.value = count < 0 ? 0 : count;
  }

  /// Reset unread count to zero (e.g., after marking all as read).
  void resetUnread() {
    unreadCountNotifier.value = 0;
  }

  // --- Private Methods ---

  /// Build the WebSocket URL from the API base URL.
  String _buildWsUrl(String token) {
    // ApiClient.baseUrl is like "http://10.0.2.2:8080/api/v1"
    String base = ApiClient.baseUrl;

    // Convert http:// → ws://, https:// → wss://
    if (base.startsWith('https://')) {
      base = 'wss://${base.substring(8)}';
    } else if (base.startsWith('http://')) {
      base = 'ws://${base.substring(7)}';
    }

    return '$base/ws/notifications?token=$token';
  }

  void _onMessage(dynamic data) {
    try {
      final Map<String, dynamic> json =
          jsonDecode(data.toString()) as Map<String, dynamic>;
      final message = WSMessage.fromJson(json);

      debugPrint('[WebSocketService] Received: type=${message.type} event=${message.event}');

      // Auto-increment unread count for new notifications
      if (message.isNotification && message.event == 'notification.created') {
        incrementUnread();
      }

      _messageController.add(message);
    } catch (e) {
      debugPrint('[WebSocketService] Failed to parse message: $e');
    }
  }

  void _onError(dynamic error) {
    debugPrint('[WebSocketService] Stream error: $error');
    connectionStatus.value = WSConnectionStatus.error;
    _cleanup();
    if (!_intentionalDisconnect) {
      _scheduleReconnect();
    }
  }

  void _onDone() {
    debugPrint('[WebSocketService] Connection closed');
    _cleanup();
    if (!_intentionalDisconnect) {
      connectionStatus.value = WSConnectionStatus.disconnected;
      _scheduleReconnect();
    }
  }

  void _cleanup() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _subscription?.cancel();
    _subscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  /// Reconnect with exponential backoff: 1s, 2s, 4s, 8s, 16s, max 30s.
  void _scheduleReconnect() {
    if (_intentionalDisconnect) return;

    _reconnectTimer?.cancel();
    final delay = min(
      pow(2, _reconnectAttempts).toInt(),
      _maxReconnectDelay,
    );
    _reconnectAttempts++;

    debugPrint('[WebSocketService] Reconnecting in ${delay}s (attempt $_reconnectAttempts)');
    connectionStatus.value = WSConnectionStatus.disconnected;

    _reconnectTimer = Timer(Duration(seconds: delay), () {
      connect();
    });
  }

  /// Send a ping every 25 seconds to keep the connection alive.
  /// This is a WebSocket-level text ping — the server's gorilla/websocket
  /// handles protocol-level Ping/Pong separately.
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_channel != null &&
          connectionStatus.value == WSConnectionStatus.connected) {
        try {
          // Send a lightweight text message as application-level keepalive
          _channel!.sink.add(jsonEncode({'type': 'ping'}));
        } catch (e) {
          debugPrint('[WebSocketService] Heartbeat failed: $e');
        }
      }
    });
  }
}
