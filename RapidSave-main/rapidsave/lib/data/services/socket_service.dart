import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../core/constants/app_strings.dart';
import '../../core/network/dio_client.dart';

class SocketService {
  static final SocketService _instance = SocketService._();
  factory SocketService() => _instance;
  SocketService._();

  IO.Socket? _socket;
  bool _connecting = false;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (isConnected) return;
    if (_connecting) return;

    final token = await DioClient().getToken();
    if (token == null) return;

    _connecting = true;

    // Dispose stale socket before creating a new one
    if (_socket != null) {
      _socket!.dispose();
      _socket = null;
    }

    final completer = Completer<void>();

    _socket = IO.io(
      AppStrings.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      _connecting = false;
      if (!completer.isCompleted) completer.complete();
    });

    _socket!.onConnectError((err) {
      _connecting = false;
      if (!completer.isCompleted) completer.complete(); // proceed even on error
    });

    _socket!.onDisconnect((_) {
      print('Socket disconnected');
    });

    _socket!.connect();

    // Wait up to 8 seconds for the connection to be established
    await completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () { _connecting = false; },
    );
  }

  void joinConversation(String conversationId) {
    _socket?.emit(AppStrings.eventJoinConversation, {
      'conversation_id': conversationId,
    });
  }

  void leaveConversation(String conversationId) {
    _socket?.emit(AppStrings.eventLeaveConversation, {
      'conversation_id': conversationId,
    });
  }

  void sendMessage({
    required String conversationId,
    required String content,
    String? replyTo,
  }) {
    _socket?.emit(AppStrings.eventSendMessage, {
      'conversation_id': conversationId,
      'content': content,
      if (replyTo != null) 'reply_to': replyTo,
    });
  }

  void sendTyping(String conversationId) {
    _socket?.emit(AppStrings.eventTyping, {'conversation_id': conversationId});
  }

  void sendReaction({
    required String conversationId,
    required String messageId,
    required String emoji,
  }) {
    _socket?.emit(AppStrings.eventAddReaction, {
      'conversation_id': conversationId,
      'message_id': messageId,
      'emoji': emoji,
    });
  }

  void onNewMessage(void Function(Map<String, dynamic>) handler) {
    _socket?.on(AppStrings.eventNewMessage, (data) {
      handler(data as Map<String, dynamic>);
    });
  }

  void onTyping(void Function(Map<String, dynamic>) handler) {
    _socket?.on(AppStrings.eventTyping, (data) {
      handler(data as Map<String, dynamic>);
    });
  }

  void onReactionUpdate(void Function(Map<String, dynamic>) handler) {
    _socket?.on(AppStrings.eventReactionUpdate, (data) {
      handler(data as Map<String, dynamic>);
    });
  }

  void onReceiptUpdate(void Function(Map<String, dynamic>) handler) {
    _socket?.on(AppStrings.eventReceiptUpdate, (data) {
      handler(data as Map<String, dynamic>);
    });
  }

  // ── Delivery tracking ────────────────────────────────────────────────────
  void joinDelivery(String deliveryId) {
    _socket?.emit(AppStrings.eventJoinDelivery, {'delivery_id': deliveryId});
  }

  void leaveDelivery(String deliveryId) {
    _socket?.emit(AppStrings.eventLeaveDelivery, {'delivery_id': deliveryId});
  }

  void onDriverLocation(void Function(Map<String, dynamic>) handler) {
    _socket?.on(AppStrings.eventDriverLocation, (data) {
      if (data is Map<String, dynamic>) handler(data);
    });
  }

  void onDeliveryStatusUpdate(void Function(Map<String, dynamic>) handler) {
    _socket?.on(AppStrings.eventDeliveryStatusUpdate, (data) {
      if (data is Map<String, dynamic>) handler(data);
    });
  }

  void off(String event) {
    _socket?.off(event);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
