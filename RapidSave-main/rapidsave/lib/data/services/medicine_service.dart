import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';

class MedicineService {
  final _dio = DioClient().dio;

  Future<List<Map<String, dynamic>>> searchMedicines({
    String? query,
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await _dio.get(
        '/medicines',
        queryParameters: {
          if (query != null && query.isNotEmpty) 'search': query,
          if (category != null) 'category': category,
          'page': page,
          'limit': limit,
        },
      );
      final data = res.data['data'] as Map<String, dynamic>;
      final list = data['medicines'] as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to fetch medicines');
    }
  }

  Future<Map<String, dynamic>> getMedicineById(String id) async {
    try {
      final res = await _dio.get('/medicines/$id');
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to fetch medicine');
    }
  }

  /// Admin-only: add a new medicine to the central catalog.
  /// Admin-only: add a new medicine to the central catalog.
  /// [unit] is required by the backend schema (e.g. "Tablet", "Syrup").
  Future<Map<String, dynamic>> createMedicine({
    required String name,
    required String unit,
    String? category,
    String? description,
  }) async {
    try {
      final res = await _dio.post('/medicines', data: {
        'name': name,
        'unit': unit,
        if (category != null && category.isNotEmpty) 'category': category,
        if (description != null && description.isNotEmpty) 'description': description,
      });
      final raw = res.data['data'];
      if (raw is Map<String, dynamic>) return raw['medicine'] as Map<String, dynamic>? ?? raw;
      return raw as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to create medicine');
    }
  }

  /// Returns inventory records for pharmacies that stock this medicine.
  /// Each record includes populated `pharmacy` and `medicine` fields.
  Future<List<Map<String, dynamic>>> getInventoryForMedicine(
    String medicineId, {
    double? lat,
    double? lng,
    double radius = 10,
  }) async {
    try {
      final res = await _dio.get(
        '/inventory/medicine/$medicineId',
        queryParameters: {
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
          'radius': radius,
        },
      );
      final raw = res.data['data'];
      if (raw is List) {
        return raw.cast<Map<String, dynamic>>();
      }
      if (raw is Map) {
        final list = raw['inventory'] as List<dynamic>?;
        return list?.cast<Map<String, dynamic>>() ?? [];
      }
      return [];
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to fetch pharmacies');
    }
  }
}
