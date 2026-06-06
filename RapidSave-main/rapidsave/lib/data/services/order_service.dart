import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';

class OrderService {
  final _dio = DioClient().dio;

  // ── Patient ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createOrder({
    required String pharmacyId,
    required List<Map<String, dynamic>> items,
    required bool delivery,
    String? notes,
  }) async {
    try {
      final res = await _dio.post(
        '/orders',
        data: {
          'pharmacy_id': pharmacyId,
          'type': delivery ? 'delivery' : 'reservation',
          'items': items,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to create order');
    }
  }

  Future<List<Map<String, dynamic>>> getMyOrders({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await _dio.get(
        '/orders/my',
        queryParameters: {
          if (status != null) 'status': status,
          'page': page,
          'limit': limit,
        },
      );
      final data = res.data['data'] as Map<String, dynamic>;
      final list = data['orders'] as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to fetch orders');
    }
  }

  Future<Map<String, dynamic>> getOrderById(String id) async {
    try {
      final res = await _dio.get('/orders/$id');
      final data = res.data['data'] as Map<String, dynamic>;
      // Backend returns { order: {...}, items: [...] }
      // Merge items into the order map so detail screens can read all fields flat.
      final order = data['order'] as Map<String, dynamic>? ?? data;
      final items = data['items'] as List<dynamic>? ?? order['items'] as List<dynamic>? ?? [];
      return {...order, 'items': items};
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to fetch order');
    }
  }

  Future<Map<String, dynamic>> uploadPaymentProof({
    required String orderId,
    required String filePath,
    required String provider,
    required String reference,
  }) async {
    try {
      final formData = FormData.fromMap({
        'payment_proof': await MultipartFile.fromFile(filePath),
        'provider': provider,
        'reference': reference,
      });
      final res = await _dio.post('/orders/$orderId/payment-proof', data: formData);
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to upload payment proof');
    }
  }

  Future<void> cancelOrder(String id) async {
    try {
      await _dio.patch('/orders/$id/status', data: {'status': 'cancelled'});
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to cancel order');
    }
  }

  // ── Pharmacy Admin ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPharmacyOrders({
    String? status,
    String? pharmacyId,
    int page = 1,
    int limit = 30,
  }) async {
    try {
      final res = await _dio.get(
        '/orders/pharmacy',
        queryParameters: {
          if (status != null && status != 'all') 'status': status,
          if (pharmacyId != null) 'pharmacy_id': pharmacyId,
          'page': page,
          'limit': limit,
        },
      );
      final data = res.data['data'] as Map<String, dynamic>;
      final list = data['orders'] as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to fetch pharmacy orders');
    }
  }

  Future<Map<String, dynamic>> updateOrderStatus(
    String orderId,
    String status,
  ) async {
    try {
      final res = await _dio.patch(
        '/orders/$orderId/status',
        data: {'status': status},
      );
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to update order status');
    }
  }

  Future<List<Map<String, dynamic>>> getPendingPayments({
    String? pharmacyId,
    int page = 1,
    int limit = 30,
  }) async {
    try {
      final res = await _dio.get(
        '/orders/pending-payments',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (pharmacyId != null) 'pharmacy_id': pharmacyId,
        },
      );
      // Backend sends the array directly in 'data' (not wrapped in {orders:[...]})
      final raw = res.data['data'];
      if (raw is List) return raw.cast<Map<String, dynamic>>();
      if (raw is Map<String, dynamic>) {
        final list = (raw['orders'] ?? raw['data'] ?? []) as List<dynamic>;
        return list.cast<Map<String, dynamic>>();
      }
      return [];
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to fetch pending payments');
    }
  }

  Future<void> verifyPayment(String orderId, String action, {String? reason}) async {
    try {
      await _dio.patch(
        '/orders/$orderId/payment/verify',
        data: {
          'action': action, // 'verify' or 'reject'
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to verify payment');
    }
  }
}
