import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import 'dart:io';

class ConversationService {
  final _dio = DioClient().dio;

  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final res = await _dio.get('/conversations');
      final data = res.data['data'] as Map<String, dynamic>;
      final list = data['conversations'] as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to fetch conversations');
    }
  }

  Future<Map<String, dynamic>> getConversationById(String id) async {
    try {
      final res = await _dio.get('/conversations/$id');
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to fetch conversation');
    }
  }

  Future<List<Map<String, dynamic>>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final res = await _dio.get(
        '/conversations/$conversationId/messages',
        queryParameters: {'page': page, 'limit': limit},
      );
      // Backend returns the array directly in 'data'
      final raw = res.data['data'];
      if (raw is List) return raw.cast<Map<String, dynamic>>();
      if (raw is Map<String, dynamic>) {
        final list = (raw['messages'] ?? raw['data'] ?? []) as List<dynamic>;
        return list.cast<Map<String, dynamic>>();
      }
      return [];
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to fetch messages');
    }
  }

  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String content,
    String messageType = 'text',
    String? replyTo,
  }) async {
    try {
      final res = await _dio.post(
        '/conversations/$conversationId/messages',
        data: {
          'content': content,
          'message_type': messageType,
          if (replyTo != null) 'reply_to': replyTo,
        },
      );
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to send message');
    }
  }

  /// Upload an image message. Backend stores it on Cloudinary and returns
  /// the URL as the message content.
  Future<Map<String, dynamic>> sendImageMessage({
    required String conversationId,
    required File imageFile,
    String? replyTo,
  }) async {
    try {
      final formData = FormData.fromMap({
        'message_type': 'image',
        'content': 'image', // placeholder — backend overwrites with Cloudinary URL
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
        if (replyTo != null) 'reply_to': replyTo,
      });
      final res = await _dio.post(
        '/conversations/$conversationId/messages',
        data: formData,
      );
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to send image');
    }
  }

  Future<void> addReaction({
    required String conversationId,
    required String messageId,
    required String emoji,
  }) async {
    try {
      await _dio.post(
        '/conversations/$conversationId/messages/$messageId/reactions',
        data: {'emoji': emoji},
      );
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to add reaction');
    }
  }

  /// Get existing conversation for an order, or create one if none exists.
  /// Works even before a delivery is dispatched.
  Future<Map<String, dynamic>?> getOrCreateConversation(String orderId) async {
    try {
      final res = await _dio.post('/conversations', data: {'order_id': orderId});
      final raw = res.data['data'];
      if (raw is Map<String, dynamic>) return raw;
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      final serverMsg = e.response?.data?['message'] as String?;
      throw Exception(serverMsg ?? e.message ?? 'Failed to get conversation');
    }
  }

  /// Find the conversation linked to an order without creating one.
  Future<Map<String, dynamic>?> getConversationByOrder(String orderId) async {
    try {
      final res = await _dio.get('/conversations/by-order/$orderId');
      final raw = res.data['data'];
      if (raw is Map<String, dynamic>) return raw;
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw e.error ?? Exception('Failed to get conversation');
    }
  }
}
