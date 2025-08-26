import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

class SocketService extends ChangeNotifier {
  IO.Socket? _socket;
  Function(Map<String, dynamic>)? _onOrderStatusChanged;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  bool _isConnected = false;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 10;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  SocketService() {
    print('🏗️ SocketService: Constructor called');
    _initializeNotifications();
  }

  // Helper method to safely notify listeners without causing build-time setState
  void _safeNotifyListeners() {
    // Use scheduleMicrotask to defer the notification until after the current build cycle
    scheduleMicrotask(() {
      if (hasListeners) {
        notifyListeners();
      }
    });
  }

  Future<void> _initializeNotifications() async {
    print('🔔 SocketService: Initializing notifications...');

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    // Request permissions for notifications
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    print('✅ SocketService: Notifications initialized');
  }

  void _handleOrderUpdate(Map<String, dynamic> data) {
    print('🔄 SocketService: _handleOrderUpdate called');
    print('🔄 Processing order update: $data');
    print('🔄 Callback set: ${_onOrderStatusChanged != null}');
    print('🔄 Is connected: $_isConnected');

    if (_onOrderStatusChanged == null) {
      print('❌ SocketService: No callback set! Cannot process update.');
      return;
    }

    if (!_isConnected) {
      print('❌ SocketService: Not connected! Cannot process update reliably.');
      return;
    }

    try {
      final orderId = data['order_id'];
      final oldStatus = data['old_status'];
      final newStatus = data['new_status'];
      final oldDriverId = data['old_driver_id'];
      final newDriverId = data['new_driver_id'];
      final brandName = data['brand_name'];

      print('📦 SocketService: Extracted data:');
      print('   - Order ID: $orderId');
      print('   - Old Status: $oldStatus');
      print('   - New Status: $newStatus');
      print('   - Old Driver ID: $oldDriverId');
      print('   - New Driver ID: $newDriverId');
      print('   - Brand Name: $brandName');

      // Filter: Only process orders for TVP brand
      if (brandName != 'TVP') {
        print('🚫 SocketService: Order not for TVP brand ($brandName), ignoring...');
        return;
      }

      // CRITICAL: Check for new order available (status == 'green' && driver_id == null)
      if (newStatus == 'green' && newDriverId == null && orderId != null) {
        print('🆕 SocketService: POTENTIAL NEW TVP ORDER DETECTED! Order ID: $orderId');

        // Create payload for provider to handle new order
        final newOrderPayload = {
          'order_id': orderId,
          'new_status': newStatus,
          'new_driver_id': newDriverId,
          'old_status': oldStatus,
          'old_driver_id': oldDriverId,
          'brand_name': brandName,
          '_is_new_order_event': true,
          '_fetch_order_details': true,
          '_timestamp': DateTime.now().millisecondsSinceEpoch,
        };

        print('🔔 SocketService: Calling callback with new TVP order payload...');
        _onOrderStatusChanged!(newOrderPayload);

        // Show notification for potential new order
        print('📱 SocketService: Showing notification for new TVP order...');
        _showNewOrderNotification(orderId);

      } else if (newStatus == 'green' && newDriverId != null) {
        // Order accepted by someone else
        print('👤 SocketService: TVP Order accepted by driver $newDriverId');
        _onOrderStatusChanged!(data);

      } else if (newStatus == 'blue') {
        // Order completed
        print('🏁 SocketService: TVP Order $orderId completed');
        _onOrderStatusChanged!(data);

      } else {
        // Handle other status changes
        print('🔄 SocketService: Other TVP status change, calling callback...');
        _onOrderStatusChanged!(data);
      }

      print('✅ SocketService: TVP order update processing completed');

    } catch (e) {
      print('❌ SocketService: Error processing order update: $e');
      print('❌ Stack trace: ${StackTrace.current}');

      // Fallback - still notify the provider even if there's an error
      if (_onOrderStatusChanged != null) {
        print('🔄 SocketService: Attempting fallback callback...');
        try {
          _onOrderStatusChanged!(data);
        } catch (fallbackError) {
          print('❌ SocketService: Fallback callback also failed: $fallbackError');
        }
      }
    }
  }

// Update the connect method to ensure proper connection
  void connect() {
    print('🔌 SocketService: connect() called');

    if (_isConnecting) {
      print('🔌 SocketService: Already connecting, skipping...');
      return;
    }

    if (_socket?.connected == true) {
      print('🔌 SocketService: Already connected, skipping...');
      return;
    }

    _isConnecting = true;
    print('🔌 SocketService: Attempting to connect to https://thevillage-backend.onrender.com');

    _socket?.dispose(); // Dispose previous socket if exists

    _socket = IO.io(
      'https://thevillage-backend.onrender.com',
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'timeout': 30000, // Increased timeout
        'forceNew': true,
        'reconnection': true,
        'reconnectionDelay': 1000,
        'reconnectionAttempts': _maxReconnectAttempts,
        'reconnectionDelayMax': 5000,
        'randomizationFactor': 0.5,
        // Send client identification
        'extraHeaders': {
          'x-client-id': 'TVP'
        },
      },
    );

    print('🔌 SocketService: Socket created, setting up event listeners...');
    _setupSocketEventListeners();

    print('🔌 SocketService: Calling connect()...');
    _socket!.connect();
  }

// Add this method to test socket connectivity
  void testConnection() {
    if (_socket?.connected == true) {
      print('🧪 SocketService: Testing connection...');
      _socket!.emit('ping', {
        'test': 'connection_test',
        'client_id': 'TVP',
        'timestamp': DateTime.now().toIso8601String()
      });
    } else {
      print('❌ SocketService: Cannot test - not connected');
    }
  }

  void _setupSocketEventListeners() {
    _socket!.on('connect', (data) {
      print('✅ SocketService: Connected successfully at ${DateTime.now()}');
      print('✅ SocketService: Socket ID: ${_socket!.id}');
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      _cancelReconnectTimer();
      _startHeartbeat();

      // Identify client to server
      _socket!.emit('client_identify', {'client_id': 'TVP', 'type': 'driver_app'});

      // Immediately re-establish callback if it exists
      if (_onOrderStatusChanged != null) {
        print('🔗 SocketService: Re-establishing callback after connection...');
      }

      // Use safe notification method
      _safeNotifyListeners();

      // Test connection with a ping
      Timer(Duration(seconds: 1), () {
        print('🧪 SocketService: Testing connection with ping...');
        _socket!.emit('ping', {
          'test': 'from_flutter_tvp_driver_app',
          'client_id': 'TVP',
          'timestamp': DateTime.now().toIso8601String()
        });
      });
    });

    _socket!.on('disconnect', (data) {
      print('❌ SocketService: Disconnected at ${DateTime.now()}: $data');
      _isConnected = false;
      _isConnecting = false;
      _stopHeartbeat();

      // Use safe notification method to prevent build-time setState
      _safeNotifyListeners();
      _startReconnectTimer();
    });

    _socket!.on('connect_error', (error) {
      print('❌ SocketService: Connection error at ${DateTime.now()}: $error');
      _isConnected = false;
      _isConnecting = false;
      _reconnectAttempts++;

      // Use safe notification method to prevent build-time setState
      _safeNotifyListeners();

      if (_reconnectAttempts < _maxReconnectAttempts) {
        _startReconnectTimer();
      } else {
        print('❌ SocketService: Max reconnection attempts reached');
        _cancelReconnectTimer();
      }
    });

    _socket!.on('reconnect', (data) {
      print('🔄 SocketService: Reconnected successfully at ${DateTime.now()}');
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;

      // Re-identify client after reconnection
      _socket!.emit('client_identify', {'client_id': 'TVP', 'type': 'driver_app'});

      // Use safe notification method
      _safeNotifyListeners();
    });

    _socket!.on('order_status_or_driver_changed', (data) {
      print('🔔 *** SOCKET EVENT RECEIVED *** order_status_or_driver_changed');
      print('🔔 Timestamp: ${DateTime.now()}');
      print('🔔 Raw data: $data');
      print('🔔 Data type: ${data.runtimeType}');

      // Convert data to Map<String, dynamic> if needed
      Map<String, dynamic> eventData;
      if (data is Map<String, dynamic>) {
        eventData = data;
      } else if (data is Map) {
        eventData = Map<String, dynamic>.from(data);
      } else {
        print('❌ SocketService: Unexpected data type, attempting conversion...');
        try {
          eventData = Map<String, dynamic>.from(data);
        } catch (e) {
          print('❌ SocketService: Failed to convert data: $e');
          return;
        }
      }

      print('🔔 Processed event data: $eventData');
      _handleOrderUpdate(eventData);
    });

    _socket!.on('new_order_created', (data) {
      print('🆕 *** NEW ORDER CREATED EVENT *** ');
      print('🆕 Timestamp: ${DateTime.now()}');
      print('🆕 Raw data: $data');

      Map<String, dynamic> eventData;
      if (data is Map<String, dynamic>) {
        eventData = data;
      } else if (data is Map) {
        eventData = Map<String, dynamic>.from(data);
      } else {
        try {
          eventData = Map<String, dynamic>.from(data);
        } catch (e) {
          print('❌ SocketService: Failed to convert new order data: $e');
          return;
        }
      }

      // Check brand filter first
      final brandName = eventData['brand_name'];
      if (brandName != 'TVP') {
        print('🚫 SocketService: New order not for TVP brand ($brandName), ignoring...');
        return;
      }

      // Process as new order available
      final orderId = eventData['order_id'];
      if (orderId != null) {
        final newOrderPayload = {
          'order_id': orderId,
          'new_status': 'green',
          'new_driver_id': null,
          'brand_name': brandName,
          '_is_new_order_available': true,
          '_requires_api_fetch': true,
        };

        print('🔔 SocketService: Processing new TVP order creation...');
        _handleOrderUpdate(newOrderPayload);
      }
    });

    // Listen for pong responses
    _socket!.on('pong', (data) {
      print('🏓 SocketService: Received pong response: $data');
    });

    // Listen for ANY events for debugging
    _socket!.onAny((event, data) {
      if (event != 'pong' && event != 'ping') { // Filter out heartbeat noise
        print('🎯 SocketService: Received event: "$event" with data: $data');
      }
    });
  }

  Future<void> _showNewOrderNotification(int orderId) async {
    print('📱 SocketService: _showNewOrderNotification called for TVP order $orderId');

    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'new_orders_channel',
        'New Orders',
        channelDescription: 'Notifications for new TVP delivery orders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        autoCancel: false, // Keep notification until dismissed
        ongoing: true, // Make it persistent
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
      DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _notificationsPlugin.show(
        orderId.hashCode,
        'New TVP Delivery Order Available! 🚚',
        'Tap to view TVP Order #$orderId',
        platformChannelSpecifics,
        payload: jsonEncode({'order_id': orderId, 'type': 'new_order', 'brand': 'TVP'}),
      );

      print('✅ SocketService: Notification shown successfully for TVP order $orderId');
    } catch (e) {
      print('❌ SocketService: Error showing notification: $e');
    }
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_isConnected && _socket != null) {
        print('💓 SocketService: Sending heartbeat...');
        _socket!.emit('ping', {
          'heartbeat': true,
          'client_id': 'TVP',
          'timestamp': DateTime.now().toIso8601String()
        });
      } else {
        print('💔 SocketService: Cannot send heartbeat - not connected');
        _stopHeartbeat();
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _startReconnectTimer() {
    _cancelReconnectTimer();

    print('🔄 SocketService: Starting reconnect timer...');
    _reconnectTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isConnected && !_isConnecting && _reconnectAttempts < _maxReconnectAttempts) {
        print('🔄 SocketService: Reconnect attempt ${_reconnectAttempts + 1}/${_maxReconnectAttempts}...');
        connect();
      } else if (_reconnectAttempts >= _maxReconnectAttempts) {
        print('❌ SocketService: Max reconnect attempts reached');
        _cancelReconnectTimer();
      } else if (_isConnected) {
        print('✅ SocketService: Reconnected, canceling timer');
        _cancelReconnectTimer();
      }
    });
  }

  void _cancelReconnectTimer() {
    if (_reconnectTimer != null) {
      print('⏹️ SocketService: Canceling reconnect timer');
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
    }
  }

  void setOnOrderStatusChanged(Function(Map<String, dynamic>) callback) {
    print('🔗 SocketService: setOnOrderStatusChanged called');
    print('🔗 Previous callback existed: ${_onOrderStatusChanged != null}');
    print('🔗 Current connection status: $_isConnected');

    _onOrderStatusChanged = callback;

    print('✅ SocketService: Callback set successfully');
  }

  // Force reconnection
  void forceReconnect() {
    print('🔄 SocketService: Force reconnect requested');
    _isConnected = false;
    _isConnecting = false;
    _reconnectAttempts = 0;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    connect();
  }

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  int get reconnectAttempts => _reconnectAttempts;

  void disconnect() {
    print('🔌 SocketService: disconnect() called');
    _cancelReconnectTimer();
    _stopHeartbeat();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _isConnecting = false;
    _onOrderStatusChanged = null;
    print('✅ SocketService: Disconnected and cleaned up');
  }

  @override
  void dispose() {
    print('🗑️ SocketService: dispose() called');
    disconnect();
    super.dispose();
  }
}