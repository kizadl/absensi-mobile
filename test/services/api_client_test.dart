import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:epresensi/services/api_client.dart';
import 'package:epresensi/services/secure_storage_service.dart';

class MockSecureStorageService extends Mock
    implements SecureStorageService {}

void main() {
  group('ApiClient', () {
    late MockSecureStorageService mockStorage;
    late ApiClient apiClient;

    setUp(() {
      mockStorage = MockSecureStorageService();
    });

    test('creates Dio with correct base options when none provided', () {
      apiClient = ApiClient(storage: mockStorage);

      expect(apiClient.dio, isNotNull);
      expect(apiClient.dio.options.baseUrl, isNotEmpty);
      expect(apiClient.dio.options.headers['Accept'], equals('application/json'));
      expect(
        apiClient.dio.options.connectTimeout,
        equals(const Duration(seconds: 15)),
      );
      expect(
        apiClient.dio.options.receiveTimeout,
        equals(const Duration(seconds: 15)),
      );
    });

    test('uses provided Dio instance', () {
      final customDio = Dio(BaseOptions(baseUrl: 'http://custom.example.com'));
      apiClient = ApiClient(storage: mockStorage, dio: customDio);

      expect(apiClient.dio, same(customDio));
    });

    test('uses default SecureStorageService when none provided', () {
      apiClient = ApiClient();

      expect(apiClient.dio, isNotNull);
      // The injected storage should be usable (constructor initializes it)
    });

    test('has interceptor registered', () {
      apiClient = ApiClient(storage: mockStorage);

      // Verify that at least one interceptor is registered
      expect(apiClient.dio.interceptors, isNotEmpty);
    });

    test('validateStatus accepts 2xx to 4xx responses', () {
      apiClient = ApiClient(storage: mockStorage);

      final validateStatus = apiClient.dio.options.validateStatus;

      expect(validateStatus(200), isTrue);
      expect(validateStatus(201), isTrue);
      expect(validateStatus(400), isTrue);
      expect(validateStatus(422), isTrue);
      expect(validateStatus(409), isTrue);
      expect(validateStatus(499), isTrue);
      expect(validateStatus(500), isFalse);
      expect(validateStatus(503), isFalse);
    });

    test('validateStatus rejects null status', () {
      apiClient = ApiClient(storage: mockStorage);

      final validateStatus = apiClient.dio.options.validateStatus;

      expect(validateStatus(null), isFalse);
    });
  });
}
