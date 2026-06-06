import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';

class NotificationService {
  final _dio = DioClient().dio;

  Future<List<Map<String, dynamic>>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await _dio.get(
        '/notifications',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = res.data['data'] as Map<String, dynamic>;
      final list = data['notifications'] as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to fetch notifications');
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _dio.patch('/notifications/$id/read');
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to mark notification as read');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _dio.patch('/notifications/read-all');
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to mark all notifications as read');
    }
  }

  Future<void> sendTestNotification() async {
    try {
      await _dio.post('/notifications/test');
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to send test notification');
    }
  }
}
