import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../models/user_model.dart';

class AuthService {
  final _dio = DioClient().dio;

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    try {
      final res = await _dio.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          if (phone != null) 'phone': phone,
        },
      );
      return res.data;
    } on DioException catch (e) {
      throw e.error ?? Exception('Registration failed');
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return res.data;
    } on DioException catch (e) {
      throw e.error ?? Exception('Login failed');
    }
  }

  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final res = await _dio.post(
        '/auth/verify-email',
        data: {'email': email, 'code': code},
      );
      return res.data;
    } on DioException catch (e) {
      throw e.error ?? Exception('Verification failed');
    }
  }

  Future<void> resendVerificationCode(String email) async {
    try {
      await _dio.post('/auth/resend-verification', data: {'email': email});
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to resend code');
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to send reset email');
    }
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        '/auth/reset-password',
        data: {'token': token, 'new_password': newPassword},
      );
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to reset password');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        '/auth/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to change password');
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final res = await _dio.get('/users/me');
      return UserModel.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to get profile');
    }
  }

  Future<UserModel> updateProfile({String? name, String? phone}) async {
    try {
      final res = await _dio.patch(
        '/users/me',
        data: {
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
        },
      );
      return UserModel.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw e.error ?? Exception('Failed to update profile');
    }
  }
}
