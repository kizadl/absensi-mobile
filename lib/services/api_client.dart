import 'package:dio/dio.dart';

import '../config/env.dart';
import 'secure_storage_service.dart';

/// Wraps a configured [Dio] instance:
/// - base URL from [Env.baseUrl]
/// - JSON Accept header
/// - interceptor that injects the Sanctum bearer token on every request
class ApiClient {
  ApiClient({SecureStorageService? storage, Dio? dio})
      : _storage = storage ?? SecureStorageService(),
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: Env.baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              headers: {'Accept': 'application/json'},
              // Let us read non-2xx bodies (422/409) instead of throwing
              // on every error status.
              validateStatus: (status) =>
                  status != null && status >= 200 && status < 500,
            )) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final SecureStorageService _storage;
  final Dio _dio;

  Dio get dio => _dio;
}
