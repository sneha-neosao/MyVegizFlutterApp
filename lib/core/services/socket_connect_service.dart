import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../utils/logger.dart';

class CustomerTrackingSocketService {
  IO.Socket? _socket;

  // ===========================================================================
  // STREAMS
  // ===========================================================================

  final StreamController<Map<String, dynamic>> _messageController =
  StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<bool> _connectionController =
  StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get messageStream =>
      _messageController.stream;

  Stream<bool> get connectionStream =>
      _connectionController.stream;

  // ===========================================================================
  // CONFIGURATION
  // ===========================================================================

  String? _socketUrl;
  String? _jwtToken;
  String? _currentOrderId;

  // ===========================================================================
  // STATE
  // ===========================================================================

  bool _manuallyDisconnected = false;
  bool _disposed = false;
  bool _isSubscribed = false;

  // ===========================================================================
  // GETTERS
  // ===========================================================================

  bool get isConnected => _socket?.connected == true;

  bool get isSubscribed => _isSubscribed;

  String? get currentOrderId => _currentOrderId;

  // ===========================================================================
  // START TRACKING
  // ===========================================================================

  Future<void> startTracking({
    required String socketUrl,
    required String jwtToken,
    required String orderId,
  }) async {
    if (_disposed) {
      logger.w(
        'CustomerTrackingSocketService: Service already disposed',
      );
      return;
    }

    if (orderId.trim().isEmpty) {
      logger.e(
        'CustomerTrackingSocketService: Order ID cannot be empty',
      );
      return;
    }

    _socketUrl = socketUrl;
    _jwtToken = jwtToken;
    _currentOrderId = orderId;

    _manuallyDisconnected = false;
    _isSubscribed = false;

    logger.i(
      'CustomerTrackingSocketService: Starting tracking',
    );

    logger.d(
      'Tracking order: $_currentOrderId',
    );

    await _connect();
  }

  // ===========================================================================
  // CONNECT
  // ===========================================================================

  Future<void> _connect() async {
    if (_disposed || _manuallyDisconnected) {
      return;
    }

    if (_socketUrl == null || _socketUrl!.trim().isEmpty) {
      logger.e(
        'CustomerTrackingSocketService: Socket URL is missing',
      );
      return;
    }

    if (_jwtToken == null || _jwtToken!.trim().isEmpty) {
      logger.e(
        'CustomerTrackingSocketService: JWT token is missing',
      );
      return;
    }

    if (_currentOrderId == null ||
        _currentOrderId!.trim().isEmpty) {
      logger.e(
        'CustomerTrackingSocketService: Order ID is missing',
      );
      return;
    }

    if (isConnected) {
      logger.i(
        'CustomerTrackingSocketService: Already connected',
      );

      // Make sure order is subscribed.
      if (!_isSubscribed) {
        _subscribeToOrder();
      }

      return;
    }

    try {
      // Dispose previous socket before creating a new one.
      _socket?.dispose();
      _socket = null;

      logger.i(
        'CustomerTrackingSocketService: Connecting to $_socketUrl',
      );

      final options = IO.OptionBuilder()
      // WebSocket recommended by documentation.
          .setTransports(['websocket'])

      // We manually call connect().
          .disableAutoConnect()

      // Socket.IO automatic reconnection.
          .enableReconnection()

      // Keep retrying.
          .setReconnectionAttempts(double.infinity)

      // First retry after 1 second.
          .setReconnectionDelay(1000)

      // Maximum retry delay 5 seconds.
          .setReconnectionDelayMax(5000)

      // JWT and Order ID through query parameters.
          .setQuery({
        'token': _jwtToken!,
        'order_id': _currentOrderId!,
      })

      // Force a fresh socket.
          .enableForceNew()

          .build();

      _socket = IO.io(
        _socketUrl!,
        options,
      );

      _registerSocketListeners();

      _socket!.connect();
    } catch (e, stackTrace) {
      logger.e(
        'CustomerTrackingSocketService: Connection exception',
        error: e,
        stackTrace: stackTrace,
      );

      _emitConnectionState(false);
    }
  }

  // ===========================================================================
  // SOCKET LISTENERS
  // ===========================================================================

  void _registerSocketListeners() {
    final socket = _socket;

    if (socket == null) {
      return;
    }

    // -------------------------------------------------------------------------
    // CONNECTED
    // -------------------------------------------------------------------------

    socket.onConnect((_) {
      logger.i(
        'CustomerTrackingSocketService: Socket connected',
      );

      logger.i(
        'Socket ID: ${socket.id}',
      );

      _emitConnectionState(true);

      // IMPORTANT:
      //
      // Every time the socket connects/reconnects,
      // subscribe to the order again.
      _isSubscribed = false;

      _subscribeToOrder();
    });

    // -------------------------------------------------------------------------
    // CONNECT ERROR
    // -------------------------------------------------------------------------

    socket.onConnectError((error) {
      logger.e(
        'CustomerTrackingSocketService: Connection error: $error',
      );

      _emitConnectionState(false);

      _addMessage(
        'connection:error',
        {
          'error': error?.toString(),
        },
      );
    });

    // -------------------------------------------------------------------------
    // DISCONNECTED
    // -------------------------------------------------------------------------

    socket.onDisconnect((reason) {
      logger.w(
        'CustomerTrackingSocketService: Socket disconnected: $reason',
      );

      _emitConnectionState(false);

      // Do NOT permanently stop tracking.
      //
      // Socket.IO will automatically reconnect.
      //
      // When it reconnects, onConnect() will call
      // order:subscribe again.
      _isSubscribed = false;

      _addMessage(
        'connection:disconnected',
        {
          'reason': reason?.toString(),
        },
      );
    });

    // -------------------------------------------------------------------------
    // GENERAL ERROR
    // -------------------------------------------------------------------------

    socket.onError((error) {
      logger.e(
        'CustomerTrackingSocketService: Socket error: $error',
      );

      _addMessage(
        'socket:error',
        {
          'error': error?.toString(),
        },
      );
    });

    // -------------------------------------------------------------------------
    // RECONNECT
    // -------------------------------------------------------------------------

    socket.onReconnect((attempt) {
      logger.i(
        'CustomerTrackingSocketService: Reconnected. '
            'Attempt: $attempt',
      );

      _emitConnectionState(true);

      // onConnect normally handles subscription.
      //
      // Keeping this here as an additional safety mechanism.
      _isSubscribed = false;

      _subscribeToOrder();
    });

    // -------------------------------------------------------------------------
    // RECONNECT ATTEMPT
    // -------------------------------------------------------------------------

    socket.onReconnectAttempt((attempt) {
      logger.i(
        'CustomerTrackingSocketService: Reconnect attempt: $attempt',
      );

      _addMessage(
        'connection:reconnect_attempt',
        {
          'attempt': attempt,
        },
      );
    });

    // -------------------------------------------------------------------------
    // RECONNECT ERROR
    // -------------------------------------------------------------------------

    socket.onReconnectError((error) {
      logger.e(
        'CustomerTrackingSocketService: Reconnect error: $error',
      );

      _addMessage(
        'connection:reconnect_error',
        {
          'error': error?.toString(),
        },
      );
    });

    // -------------------------------------------------------------------------
    // RECONNECT FAILED
    // -------------------------------------------------------------------------

    socket.onReconnectFailed((_) {
      logger.e(
        'CustomerTrackingSocketService: Reconnection failed',
      );

      _emitConnectionState(false);

      _addMessage(
        'connection:reconnect_failed',
        {},
      );
    });

    // =========================================================================
    // SERVER EVENTS
    // =========================================================================

    // -------------------------------------------------------------------------
    // ORDER SUBSCRIBED
    // -------------------------------------------------------------------------

    socket.on(
      'order:subscribed',
      _handleOrderSubscribed,
    );

    // -------------------------------------------------------------------------
    // ORDER ASSIGNED
    // -------------------------------------------------------------------------

    socket.on(
      'order:assigned',
      _handleOrderAssigned,
    );

    // -------------------------------------------------------------------------
    // LOCATION UPDATE
    // -------------------------------------------------------------------------

    socket.on(
      'location:update',
      _handleLocationUpdate,
    );

    // -------------------------------------------------------------------------
    // ORDER COMPLETED
    // -------------------------------------------------------------------------

    socket.on(
      'order:completed',
      _handleOrderCompleted,
    );

    // -------------------------------------------------------------------------
    // SERVER ERROR
    // -------------------------------------------------------------------------

    socket.on(
      'error',
      _handleServerError,
    );
  }

  // ===========================================================================
  // ORDER SUBSCRIBE
  // ===========================================================================

  void _subscribeToOrder() {
    if (_disposed) {
      return;
    }

    if (!isConnected) {
      logger.w(
        'CustomerTrackingSocketService: '
            'Cannot subscribe. Socket not connected.',
      );
      return;
    }

    if (_currentOrderId == null ||
        _currentOrderId!.trim().isEmpty) {
      logger.e(
        'CustomerTrackingSocketService: '
            'Cannot subscribe. Order ID missing.',
      );
      return;
    }

    final payload = {
      'order_id': _currentOrderId,
    };

    logger.i(
      'CustomerTrackingSocketService: '
          'Sending order:subscribe',
    );

    logger.d(
      'order:subscribe payload: $payload',
    );

    try {
      _socket!.emit(
        'order:subscribe',
        payload,
      );
    } catch (e, stackTrace) {
      logger.e(
        'CustomerTrackingSocketService: '
            'Failed to subscribe to order',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ===========================================================================
  // SERVER: ORDER SUBSCRIBED
  // ===========================================================================

  void _handleOrderSubscribed(dynamic data) {
    logger.i(
      'CustomerTrackingSocketService: '
          'order:subscribed received',
    );

    logger.d(
      'order:subscribed data: $data',
    );

    if (data is! Map) {
      logger.e(
        'CustomerTrackingSocketService: '
            'Invalid order:subscribed payload',
      );

      _addMessage(
        'order:subscribed',
        {
          'data': data,
          'invalid_payload': true,
        },
      );

      return;
    }

    final payload = Map<String, dynamic>.from(data);

    _isSubscribed = true;

    // -------------------------------------------------------------------------
    // Validate order ID
    // -------------------------------------------------------------------------

    final responseOrderId =
    payload['order_id']?.toString();

    if (responseOrderId != null &&
        _currentOrderId != null &&
        responseOrderId != _currentOrderId) {
      logger.w(
        'CustomerTrackingSocketService: '
            'Received different order ID. '
            'Expected=$_currentOrderId '
            'Received=$responseOrderId',
      );
    }

    // -------------------------------------------------------------------------
    // Last known location
    // -------------------------------------------------------------------------

    final location = _extractLocation(
      payload['location'],
    );

    if (location != null) {
      logger.i(
        'CustomerTrackingSocketService: '
            'Last known driver location received',
      );

      _addMessage(
        'location:update',
        {
          'order_id': responseOrderId ?? _currentOrderId,
          'lat': location['lat'],
          'lng': location['lng'],
          'bearing': location['bearing'],
          'timestamp': location['timestamp'],
          'source': 'order:subscribed',
        },
      );
    }

    _addMessage(
      'order:subscribed',
      payload,
    );
  }

  // ===========================================================================
  // SERVER: ORDER ASSIGNED
  // ===========================================================================

  void _handleOrderAssigned(dynamic data) {
    logger.i(
      'CustomerTrackingSocketService: '
          'order:assigned received',
    );

    logger.d(
      'order:assigned data: $data',
    );

    if (data is! Map) {
      logger.e(
        'CustomerTrackingSocketService: '
            'Invalid order:assigned payload',
      );

      _addMessage(
        'order:assigned',
        {
          'data': data,
          'invalid_payload': true,
        },
      );

      return;
    }

    final payload = Map<String, dynamic>.from(data);

    final deliveryId =
    payload['delivery_id'];

    final deliveryName =
    payload['delivery_name']?.toString();

    logger.i(
      'Driver assigned: '
          'id=$deliveryId, '
          'name=$deliveryName',
    );

    // -------------------------------------------------------------------------
    // Initial driver location
    // -------------------------------------------------------------------------

    final initialLocation = _extractLocation(
      payload['initial_location'],
    );

    if (initialLocation != null) {
      _addMessage(
        'location:update',
        {
          'order_id': _currentOrderId,
          'lat': initialLocation['lat'],
          'lng': initialLocation['lng'],
          'bearing': initialLocation['bearing'],
          'timestamp': initialLocation['timestamp'],
          'source': 'order:assigned',
        },
      );
    }

    _addMessage(
      'order:assigned',
      payload,
    );
  }

  // ===========================================================================
  // SERVER: LOCATION UPDATE
  // ===========================================================================

  void _handleLocationUpdate(dynamic data) {
    logger.d(
      'CustomerTrackingSocketService: '
          'location:update received: $data',
    );

    if (data is! Map) {
      logger.e(
        'CustomerTrackingSocketService: '
            'Invalid location:update payload',
      );

      _addMessage(
        'location:error',
        {
          'data': data,
          'invalid_payload': true,
        },
      );

      return;
    }

    final payload = Map<String, dynamic>.from(data);

    // -------------------------------------------------------------------------
    // Check order ID
    // -------------------------------------------------------------------------

    final updateOrderId =
    payload['order_id']?.toString();

    if (updateOrderId != null &&
        _currentOrderId != null &&
        updateOrderId != _currentOrderId) {
      logger.w(
        'CustomerTrackingSocketService: '
            'Ignoring location for another order. '
            'Current=$_currentOrderId '
            'Received=$updateOrderId',
      );

      return;
    }

    // -------------------------------------------------------------------------
    // Parse location
    // -------------------------------------------------------------------------

    final location = _extractLocation(payload);

    if (location == null) {
      logger.e(
        'CustomerTrackingSocketService: '
            'Invalid latitude/longitude received',
      );

      _addMessage(
        'location:error',
        {
          'data': payload,
          'invalid_location': true,
        },
      );

      return;
    }

    // -------------------------------------------------------------------------
    // Normalize location event
    // -------------------------------------------------------------------------

    final normalizedPayload = {
      'event': 'location:update',
      'order_id': updateOrderId ?? _currentOrderId,
      'lat': location['lat'],
      'lng': location['lng'],
      'bearing': location['bearing'] ?? payload['bearing'] ?? payload['heading'],
      'timestamp': location['timestamp'],
    };

    _messageController.add(
      normalizedPayload,
    );
  }

  // ===========================================================================
  // SERVER: ORDER COMPLETED
  // ===========================================================================

  void _handleOrderCompleted(dynamic data) {
    logger.i(
      'CustomerTrackingSocketService: '
          'order:completed received',
    );

    logger.d(
      'order:completed data: $data',
    );

    if (data is! Map) {
      _addMessage(
        'order:completed',
        {
          'data': data,
          'invalid_payload': true,
        },
      );

      return;
    }

    final payload = Map<String, dynamic>.from(data);

    final completedOrderId =
    payload['order_id']?.toString();

    // Ignore completion for another order.
    if (completedOrderId != null &&
        _currentOrderId != null &&
        completedOrderId != _currentOrderId) {
      logger.w(
        'CustomerTrackingSocketService: '
            'Ignoring completion for another order.',
      );

      return;
    }

    _addMessage(
      'order:completed',
      payload,
    );

    // Tracking for this order is finished.
    _isSubscribed = false;
  }

  // ===========================================================================
  // SERVER ERROR
  // ===========================================================================

  void _handleServerError(dynamic data) {
    logger.e(
      'CustomerTrackingSocketService: '
          'Server error: $data',
    );

    _addMessage(
      'error',
      {
        'data': data,
      },
    );
  }

  // ===========================================================================
  // LOCATION PARSER
  // ===========================================================================

  Map<String, dynamic>? _extractLocation(
      dynamic data,
      ) {
    if (data is! Map) {
      return null;
    }

    final map = Map<String, dynamic>.from(data);

    final latValue = map['lat'] ?? map['latitude'];
    final lngValue = map['lng'] ?? map['longitude'];

    if (latValue == null || lngValue == null) {
      return null;
    }

    final lat = double.tryParse(
      latValue.toString(),
    );

    final lng = double.tryParse(
      lngValue.toString(),
    );

    if (lat == null || lng == null) {
      return null;
    }

    // Basic geographic validation.
    if (lat < -90 || lat > 90) {
      return null;
    }

    if (lng < -180 || lng > 180) {
      return null;
    }

    final bearingValue = map['bearing'] ?? map['heading'];
    final bearing = bearingValue != null
        ? double.tryParse(bearingValue.toString())
        : null;

    return {
      'lat': lat,
      'lng': lng,
      'bearing': bearing,
      'timestamp': map['timestamp']?.toString(),
    };
  }

  // ===========================================================================
  // GENERIC MESSAGE
  // ===========================================================================

  void _addMessage(
      String event,
      dynamic data,
      ) {
    if (_messageController.isClosed) {
      return;
    }

    final Map<String, dynamic> message;

    if (data is Map) {
      message = {
        'event': event,
        ...Map<String, dynamic>.from(data),
      };
    } else {
      message = {
        'event': event,
        'data': data,
      };
    }

    _messageController.add(message);
  }

  // ===========================================================================
  // MANUAL RESUBSCRIBE
  // ===========================================================================

  void resubscribe() {
    if (!isConnected) {
      logger.w(
        'CustomerTrackingSocketService: '
            'Cannot resubscribe. Socket disconnected.',
      );
      return;
    }

    _isSubscribed = false;

    _subscribeToOrder();
  }

  // ===========================================================================
  // CHANGE ORDER
  // ===========================================================================

  Future<void> changeOrder({
    required String orderId,
  }) async {
    if (orderId.trim().isEmpty) {
      logger.e(
        'CustomerTrackingSocketService: '
            'Cannot change to empty order ID',
      );
      return;
    }

    logger.i(
      'CustomerTrackingSocketService: '
          'Changing tracking order '
          '$_currentOrderId -> $orderId',
    );

    _currentOrderId = orderId;
    _isSubscribed = false;

    if (!isConnected) {
      return;
    }

    _subscribeToOrder();
  }

  // ===========================================================================
  // SEND GENERIC EVENT
  // ===========================================================================

  void sendMessage(
      String event, [
        dynamic data,
      ]) {
    if (!isConnected) {
      logger.w(
        'CustomerTrackingSocketService: '
            'Socket not connected',
      );
      return;
    }

    try {
      if (data == null) {
        _socket!.emit(event);
      } else {
        _socket!.emit(
          event,
          data,
        );
      }

      logger.d(
        'CustomerTrackingSocketService: '
            'Event sent: $event',
      );
    } catch (e, stackTrace) {
      logger.e(
        'CustomerTrackingSocketService: '
            'Failed to send event $event',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ===========================================================================
  // STOP TRACKING
  // ===========================================================================

  void stopTracking() {
    logger.i(
      'CustomerTrackingSocketService: '
          'Stopping order tracking',
    );

    _currentOrderId = null;
    _isSubscribed = false;
  }

  // ===========================================================================
  // DISCONNECT
  // ===========================================================================

  void disconnect() {
    logger.i(
      'CustomerTrackingSocketService: '
          'Manual disconnect',
    );

    _manuallyDisconnected = true;

    _currentOrderId = null;
    _isSubscribed = false;

    _socket?.disconnect();
    _socket?.dispose();

    _socket = null;

    _emitConnectionState(false);
  }

  // ===========================================================================
  // CONNECTION STATE
  // ===========================================================================

  void _emitConnectionState(bool connected) {
    if (_connectionController.isClosed) {
      return;
    }

    _connectionController.add(connected);
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    logger.i(
      'CustomerTrackingSocketService: Disposing service',
    );

    _manuallyDisconnected = true;

    _socket?.disconnect();
    _socket?.dispose();

    _socket = null;

    _currentOrderId = null;
    _isSubscribed = false;

    if (!_messageController.isClosed) {
      _messageController.close();
    }

    if (!_connectionController.isClosed) {
      _connectionController.close();
    }
  }
}