import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/api_config.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../services/storage_service.dart';

/// WebSocket connection state
enum WebSocketState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// WebSocket service provider
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final authState = ref.watch(authProvider);
  return WebSocketService(
    ref: ref,
    userId: authState.user?['_id'] as String?,
  );
});

/// WebSocket connection state provider
final webSocketStateProvider = StateProvider<WebSocketState>((ref) {
  return WebSocketState.disconnected;
});

/// WebSocket service for real-time updates
/// Provides instant notifications with automatic reconnection
class WebSocketService {
  final Ref _ref;
  final String? userId;
  final StorageService _storage = StorageService();
  
  IO.Socket? _socket;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _initialReconnectDelay = Duration(seconds: 1);
  
  // Event listeners
  final Map<String, List<Function(dynamic)>> _listeners = {};
  
  WebSocketService({
    required Ref ref,
    required this.userId,
  }) : _ref = ref;
  
  /// Initialize WebSocket connection
  Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      print('🌐 WebSocket already connected');
      return;
    }
    
    final token = await _storage.getAccessToken();
    if (token == null || userId == null) {
      print('⚠️ Cannot connect WebSocket: Missing auth credentials');
      return;
    }
    
    try {
      _ref.read(webSocketStateProvider.notifier).state = WebSocketState.connecting;
      print('🔌 Connecting to WebSocket server...');
      
      // Use base URL for WebSocket connection
      // Socket.IO server runs on same server as API (port 443 for HTTPS)
      final wsUrl = ApiConfig.baseUrl;
      
      _socket = IO.io(
        wsUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling']) // Enable polling fallback
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(_maxReconnectAttempts)
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setExtraHeaders({'Accept': '*/*'}) // Add headers for compatibility
            .setAuth({
              'token': token,
              'userId': userId,
            })
            .build(),
      );
      
      // Connection success
      _socket!.onConnect((_) {
        print('✅ WebSocket connected successfully');
        _ref.read(webSocketStateProvider.notifier).state = WebSocketState.connected;
        _reconnectAttempts = 0;
        _reconnectTimer?.cancel();
        
        // Join user's personal room
        _socket!.emit('join', {'userId': userId});
        print('📥 Joined user room: user_$userId');
      });
      
      // Connection error
      _socket!.onConnectError((error) {
        print('❌ WebSocket connection error: $error');
        _ref.read(webSocketStateProvider.notifier).state = WebSocketState.error;
        _handleReconnect();
      });
      
      // Disconnection
      _socket!.onDisconnect((_) {
        print('🔌 WebSocket disconnected');
        _ref.read(webSocketStateProvider.notifier).state = WebSocketState.disconnected;
        _handleReconnect();
      });
      
      // Reconnect attempt
      _socket!.on('reconnect_attempt', (attemptNumber) {
        print('🔄 WebSocket reconnect attempt: $attemptNumber');
        _ref.read(webSocketStateProvider.notifier).state = WebSocketState.reconnecting;
      });
      
      // Generic error handler
      _socket!.on('error', (error) {
        print('⚠️ WebSocket error: $error');
      });
      
      // Manually connect (auto-connect is enabled but being explicit)
      _socket!.connect();
      
    } catch (e) {
      print('❌ Failed to initialize WebSocket: $e');
      _ref.read(webSocketStateProvider.notifier).state = WebSocketState.error;
      _handleReconnect();
    }
  }
  
  /// Handle reconnection with exponential backoff
  void _handleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('❌ Max reconnection attempts reached. Falling back to polling.');
      _ref.read(webSocketStateProvider.notifier).state = WebSocketState.error;
      return;
    }
    
    _reconnectAttempts++;
    final delay = _initialReconnectDelay * (_reconnectAttempts * 2);
    
    print('⏳ Scheduling reconnect in ${delay.inSeconds}s (attempt $_reconnectAttempts/$_maxReconnectAttempts)');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      print('🔄 Attempting to reconnect...');
      connect();
    });
  }
  
  /// Listen to a specific event
  void on(String event, Function(dynamic) handler) {
    if (_socket == null) {
      print('⚠️ Cannot add listener: WebSocket not initialized');
      return;
    }
    
    // Store listener for cleanup
    _listeners[event] ??= [];
    _listeners[event]!.add(handler);
    
    // Register with socket.io
    _socket!.on(event, handler);
    print('👂 Registered listener for event: $event');
  }
  
  /// Remove a specific event listener
  void off(String event, [Function(dynamic)? handler]) {
    if (_socket == null) return;
    
    if (handler != null) {
      _socket!.off(event, handler);
      _listeners[event]?.remove(handler);
    } else {
      _socket!.off(event);
      _listeners[event]?.clear();
    }
    
    print('🔇 Removed listener for event: $event');
  }
  
  /// Emit an event to the server
  void emit(String event, dynamic data) {
    if (_socket == null || !_socket!.connected) {
      print('⚠️ Cannot emit event: WebSocket not connected');
      return;
    }
    
    _socket!.emit(event, data);
    print('📤 Emitted event: $event');
  }
  
  /// Disconnect WebSocket
  void disconnect() {
    print('🔌 Disconnecting WebSocket...');
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    
    // Clear all listeners
    for (final event in _listeners.keys) {
      _socket?.off(event);
    }
    _listeners.clear();
    
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    
    _ref.read(webSocketStateProvider.notifier).state = WebSocketState.disconnected;
    print('✅ WebSocket disconnected and cleaned up');
  }
  
  /// Check if WebSocket is connected
  bool get isConnected => _socket?.connected ?? false;
  
  /// Get current connection state
  WebSocketState get state => _ref.read(webSocketStateProvider);
  
  /// Dispose resources
  void dispose() {
    disconnect();
  }
}
