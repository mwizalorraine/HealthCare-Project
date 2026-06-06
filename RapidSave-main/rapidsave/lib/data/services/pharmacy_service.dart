import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';

class PharmacyService {
  final _dio = DioClient().dio;

  // ── Patient / Public ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getNearbyPharmacies({
    required double lat,
    required double lng,
    double radius = 10,
    String? insurance,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await _dio.get(
        '/pharmacies/nearby',
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'radius': radius,
          'page': page,
          'limit': limit,
          if (insurance != null && insurance.isNotEmpty) 'insurance': insurance,
        },
      );
      // The backend returns the array directly in 'data' (not wrapped
      // in { pharmacies: [...] }), so handle both shapes.
      final raw = res.data['data'];
      if (raw is List) {
        return raw.cast<Map<String, dynamic>>();
      }
      if (raw is Map<String, dynamic>) {
        final list = (raw['pharmacies'] ?? raw['data'] ?? []) as List<dynamic>;
        return list.cast<Map<String, dynamic>>();
      }
      return [];
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to fetch pharmacies');
    }
  }

  Future<Map<String, dynamic>> getPharmacyById(String id) async {
    try {
      final res = await _dio.get('/pharmacies/$id');
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to fetch pharmacy');
    }
  }

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

  // ── Pharmacy Admin ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMyPharmacies() async {
    try {
      final res = await _dio.get('/pharmacies/mine');
      final raw = res.data['data'];
      if (raw is List) return raw.cast<Map<String, dynamic>>();
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw e.error ?? Exception('Failed to fetch pharmacies');
    }
  }

  Future<Map<String, dynamic>?> getMyPharmacy() async {
    try {
      final res = await _dio.get('/pharmacies/me');
      final raw = res.data['data'];
      if (raw == null) return null;
      if (raw is Map<String, dynamic>) {
        // Handle { pharmacy: {...} } or pharmacy fields directly in data
        return raw['pharmacy'] as Map<String, dynamic>? ?? raw;
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw e.error ?? Exception('Failed to fetch my pharmacy');
    }
  }

  Future<List<Map<String, dynamic>>> getAllPharmacies({int page = 1, int limit = 50}) async {
    try {
      final res = await _dio.get('/pharmacies', queryParameters: {'page': page, 'limit': limit});
      final data = res.data['data'] as Map<String, dynamic>;
      final list = (data['pharmacies'] ?? data['data'] ?? []) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to fetch pharmacies');
    }
  }

  Future<void> verifyPharmacy(String id) async {
    try {
      await _dio.patch('/pharmacies/$id/verify');
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to verify pharmacy');
    }
  }

  Future<Map<String, dynamic>> updateMyPharmacy(
    Map<String, dynamic> updates,
  ) async {
    try {
      final res = await _dio.patch('/pharmacies/me', data: updates);
      final data = res.data['data'] as Map<String, dynamic>;
      return data['pharmacy'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to update pharmacy');
    }
  }

  Future<Map<String, dynamic>> createPharmacy({
    required String name,
    required String licenseNumber,
    required String address,
    required String phone,
    required double lat,
    required double lng,
    List<String>? acceptedInsurances,
  }) async {
    try {
      final res = await _dio.post('/pharmacies', data: {
        'name': name,
        'license_number': licenseNumber,
        'address': address,
        'phone': phone,
        'coordinates': [lng, lat], // GeoJSON: [longitude, latitude]
        if (acceptedInsurances != null && acceptedInsurances.isNotEmpty)
          'accepted_insurances': acceptedInsurances,
      });
      // Backend returns the pharmacy object directly inside 'data'
      final raw = res.data['data'];
      if (raw is Map<String, dynamic>) {
        return raw['pharmacy'] as Map<String, dynamic>? ?? raw;
      }
      return raw as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to create pharmacy');
    }
  }

  Future<bool> toggleOpen() async {
    try {
      final res = await _dio.patch('/pharmacies/me/toggle-open');
      final data = res.data['data'] as Map<String, dynamic>;
      return data['is_open'] as bool? ?? false;
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to toggle pharmacy status');
    }
  }

  Future<bool> toggleOpenById(String id) async {
    try {
      final res = await _dio.patch('/pharmacies/$id/open');
      final data = res.data['data'] as Map<String, dynamic>;
      return data['is_open'] as bool? ?? false;
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to toggle pharmacy status');
    }
  }

  Future<Map<String, dynamic>> updatePharmacyById(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final res = await _dio.patch('/pharmacies/$id', data: updates);
      final raw = res.data['data'];
      if (raw is Map<String, dynamic>) return raw;
      return {};
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to update pharmacy');
    }
  }
}
