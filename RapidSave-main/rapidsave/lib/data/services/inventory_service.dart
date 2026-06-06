import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';

class InventoryService {
  final _dio = DioClient().dio;

  Future<List<Map<String, dynamic>>> getPharmacyInventory(
    String pharmacyId, {
    bool? inStock,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final res = await _dio.get(
        '/inventory/pharmacy/$pharmacyId',
        queryParameters: {
          if (inStock != null) 'in_stock': inStock,
          if (search != null && search.isNotEmpty) 'search': search,
          'page': page,
          'limit': limit,
        },
      );
      final data = res.data['data'] as Map<String, dynamic>;
      // Backend returns 'items', not 'inventory'
      final list = (data['items'] ?? data['inventory'] ?? []) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to fetch inventory');
    }
  }

  Future<Map<String, dynamic>> upsertInventory({
    required String medicineId,
    required int price,
    required int quantity,
    String? expiryDate,
  }) async {
    try {
      final res = await _dio.post(
        '/inventory',
        data: {
          'medicine_id': medicineId,
          'price': price,
          'quantity': quantity,
          if (expiryDate != null) 'expiry_date': expiryDate,
        },
      );
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to update inventory');
    }
  }

  Future<void> deleteInventoryItem(String id) async {
    try {
      await _dio.delete('/inventory/$id');
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to delete inventory item');
    }
  }
}
