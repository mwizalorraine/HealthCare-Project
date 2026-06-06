import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';

class DeliveryService {
  final _dio = DioClient().dio;

  Future<List<Map<String, dynamic>>> getMyDeliveries() async {
    try {
      final res = await _dio.get('/deliveries/my');
      final data = res.data['data'] as Map<String, dynamic>;
      final list = data['deliveries'] as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to fetch deliveries');
    }
  }

  Future<Map<String, dynamic>?> getDeliveryByOrder(String orderId) async {
    try {
      final res = await _dio.get('/deliveries/order/$orderId');
      return res.data['data'] as Map<String, dynamic>?;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw e.error ?? Exception('Failed to fetch delivery');
    }
  }

  Future<Map<String, dynamic>?> getDeliveryById(String id) async {
    try {
      final res = await _dio.get('/deliveries/$id');
      return res.data['data'] as Map<String, dynamic>?;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw e.error ?? Exception('Failed to fetch delivery');
    }
  }

  /// Pharmacy admin creates a delivery for an order.
  /// coordinates: [longitude, latitude] (GeoJSON format)
  Future<Map<String, dynamic>> createDelivery({
    required String orderId,
    required String address,
    required double lat,
    required double lng,
    String? riderName,
    String? riderPhone,
    String? estimatedAt,
  }) async {
    try {
      final res = await _dio.post('/deliveries', data: {
        'order_id': orderId,
        'address': address,
        'coordinates': [lng, lat], // GeoJSON: [longitude, latitude]
        if (riderName != null && riderName.isNotEmpty) 'rider_name': riderName,
        if (riderPhone != null && riderPhone.isNotEmpty) 'rider_phone': riderPhone,
        if (estimatedAt != null) 'estimated_at': estimatedAt,
      });
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to create delivery');
    }
  }

  /// Pharmacy admin updates delivery status.
  /// status: assigned | in_transit | delivered | failed
  Future<Map<String, dynamic>> updateDeliveryStatus(
    String deliveryId,
    String status,
  ) async {
    try {
      final res = await _dio.patch(
        '/deliveries/$deliveryId/status',
        data: {'status': status},
      );
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to update delivery status');
    }
  }
}
