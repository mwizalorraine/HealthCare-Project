import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/app_strings.dart';
import '../errors/app_exception.dart';

class DioClient {
  DioClient._();
  static final DioClient _instance = DioClient._();
  factory DioClient() => _instance;

  late final Dio dio;
  final _storage = const FlutterSecureStorage();
  final _unauthorizedController = StreamController<void>.broadcast();

  Stream<void> get onUnauthorized => _unauthorizedController.stream;

  void init() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppStrings.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: AppStrings.tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          final response = error.response;
          if (response == null) {
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                error: const NetworkException('No internet connection'),
              ),
            );
          }
          final data = response.data;
          final message = data is Map
              ? data['message'] ?? 'Something went wrong'
              : 'Something went wrong';
          final code = response.statusCode;

          AppException exception;
          switch (code) {
            case 401:
              // Clear stored token and notify listeners so auth state is reset.
              _storage.delete(key: AppStrings.tokenKey);
              _unauthorizedController.add(null);
              exception = AuthException(message, statusCode: code);
            case 403:
              exception = AuthException(message, statusCode: code);
            case 404:
              exception = NotFoundException(message, statusCode: code);
            case 422:
              exception = ValidationException(
                message,
                errors: data is Map ? data['errors'] : null,
                statusCode: code,
              );
            default:
              if (code != null && code >= 500) {
                exception = ServerException(message, statusCode: code);
              } else {
                exception = AppException(message, statusCode: code);
              }
          }

          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: exception,
              response: response,
            ),
          );
        },
      ),
    );

    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: false,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
      ),
    );
  }

  Future<void> setToken(String token) async {
    await _storage.write(key: AppStrings.tokenKey, value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: AppStrings.tokenKey);
  }

  Future<String?> getToken() async {
    return _storage.read(key: AppStrings.tokenKey);
  }
}
