import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:epresensi/providers/auth_provider.dart';
import 'package:epresensi/services/api_client.dart';
import 'package:epresensi/services/secure_storage_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockDio extends Mock implements Dio {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a minimal fake [Response] with the given [data] and [statusCode].
Response<dynamic> _fakeResponse({
  required dynamic data,
  int statusCode = 200,
}) {
  return Response(
    requestOptions: RequestOptions(path: ''),
    data: data,
    statusCode: statusCode,
  );
}

/// User JSON fixture used across several tests.
const Map<String, dynamic> _userJson = {
  'id': 1,
  'role': 'mahasiswa',
  'name': 'Budi',
  'username': 'budi01',
  'email': 'budi@example.com',
  'nim': '12345678',
  'phone': null,
  'photo': null,
};

/// Location / settings JSON fixture (flat object).
const Map<String, dynamic> _locationJson = {
  'campus_name': 'Kampus A',
  'campus_lat': -6.200000,
  'campus_lng': 106.816666,
  'radius_meters': 200,
  'timezone': 'Asia/Jakarta',
};

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

void main() {
  // Register fallback values for types used with any() matchers.
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
    registerFallbackValue(Options());
  });

  late MockApiClient mockApiClient;
  late MockSecureStorageService mockStorage;
  late MockDio mockDio;
  late AuthProvider auth;

  setUp(() {
    mockApiClient = MockApiClient();
    mockStorage = MockSecureStorageService();
    mockDio = MockDio();

    // Wire apiClient.dio → mockDio so we can stub HTTP calls.
    when(() => mockApiClient.dio).thenReturn(mockDio);

    auth = AuthProvider(apiClient: mockApiClient, storage: mockStorage);
  });

  // -------------------------------------------------------------------------
  // Initial state
  // -------------------------------------------------------------------------

  group('initial state', () {
    test('user is null', () => expect(auth.user, isNull));
    test('token is null', () => expect(auth.token, isNull));
    test('isAuthenticated is false', () => expect(auth.isAuthenticated, isFalse));
    test('isLoading is false', () => expect(auth.isLoading, isFalse));
    test('error is null', () => expect(auth.error, isNull));
    test('location is null', () => expect(auth.location, isNull));
  });

  // -------------------------------------------------------------------------
  // login
  // -------------------------------------------------------------------------

  group('login', () {
    test('success: sets user, stores token, returns true, isAuthenticated', () async {
      when(
        () => mockDio.post('/login', data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _fakeResponse(data: {'token': 'tok123', 'user': _userJson}),
      );
      when(() => mockStorage.saveToken(any())).thenAnswer((_) async {});

      final result = await auth.login('budi01', 'secret');

      expect(result, isTrue);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.user?.name, equals('Budi'));
      expect(auth.token, equals('tok123'));
      expect(auth.error, isNull);
      expect(auth.isLoading, isFalse);
      verify(() => mockStorage.saveToken('tok123')).called(1);
    });

    test('DioException: sets error, isAuthenticated remains false', () async {
      when(
        () => mockDio.post('/login', data: any(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/login'),
          response: _fakeResponse(data: {'message': 'Invalid credentials'}, statusCode: 401),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await auth.login('budi01', 'wrong');

      expect(result, isFalse);
      expect(auth.isAuthenticated, isFalse);
      expect(auth.error, isNotNull);
      expect(auth.isLoading, isFalse);
    });

    test('non-200 response: sets error, does not store token', () async {
      when(
        () => mockDio.post('/login', data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _fakeResponse(
          data: {'message': 'Username atau password salah.'},
          statusCode: 422,
        ),
      );

      final result = await auth.login('budi01', 'wrong');

      expect(result, isFalse);
      expect(auth.isAuthenticated, isFalse);
      expect(auth.error, isNotNull);
      verifyNever(() => mockStorage.saveToken(any()));
    });

    test('sets isLoading=true during request then false after', () async {
      var loadingDuringCall = false;
      when(
        () => mockDio.post('/login', data: any(named: 'data')),
      ).thenAnswer((_) async {
        loadingDuringCall = auth.isLoading;
        return _fakeResponse(data: {'token': 'tok', 'user': _userJson});
      });
      when(() => mockStorage.saveToken(any())).thenAnswer((_) async {});

      await auth.login('budi01', 'secret');

      expect(loadingDuringCall, isTrue);
      expect(auth.isLoading, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // logout
  // -------------------------------------------------------------------------

  group('logout', () {
    setUp(() async {
      // Put the provider into an authenticated state.
      when(
        () => mockDio.post('/login', data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _fakeResponse(data: {'token': 'tok123', 'user': _userJson}),
      );
      when(() => mockStorage.saveToken(any())).thenAnswer((_) async {});
      await auth.login('budi01', 'secret');
    });

    test('clears user, token, isAuthenticated after logout', () async {
      when(() => mockDio.post('/logout')).thenAnswer(
        (_) async => _fakeResponse(data: {'message': 'ok'}),
      );
      when(() => mockStorage.deleteToken()).thenAnswer((_) async {});

      await auth.logout();

      expect(auth.user, isNull);
      expect(auth.token, isNull);
      expect(auth.isAuthenticated, isFalse);
      verify(() => mockStorage.deleteToken()).called(1);
    });

    test('clears state even when POST /logout throws DioException', () async {
      when(() => mockDio.post('/logout')).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/logout')),
      );
      when(() => mockStorage.deleteToken()).thenAnswer((_) async {});

      await auth.logout();

      expect(auth.isAuthenticated, isFalse);
      expect(auth.user, isNull);
      verify(() => mockStorage.deleteToken()).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // tryAutoLogin
  // -------------------------------------------------------------------------

  group('tryAutoLogin', () {
    test('with stored token: fetches profile and sets user', () async {
      when(() => mockStorage.readToken()).thenAnswer((_) async => 'stored_tok');
      when(() => mockDio.get('/profile')).thenAnswer(
        (_) async => _fakeResponse(data: {'user': _userJson}),
      );

      await auth.tryAutoLogin();

      expect(auth.isAuthenticated, isTrue);
      expect(auth.user?.username, equals('budi01'));
      expect(auth.token, equals('stored_tok'));
    });

    test('with no stored token: does nothing, stays unauthenticated', () async {
      when(() => mockStorage.readToken()).thenAnswer((_) async => null);

      await auth.tryAutoLogin();

      expect(auth.isAuthenticated, isFalse);
      verifyNever(() => mockDio.get(any()));
    });

    test('with empty stored token: does nothing', () async {
      when(() => mockStorage.readToken()).thenAnswer((_) async => '');

      await auth.tryAutoLogin();

      expect(auth.isAuthenticated, isFalse);
      verifyNever(() => mockDio.get(any()));
    });

    test('profile fetch throws: clears token and stays unauthenticated', () async {
      when(() => mockStorage.readToken()).thenAnswer((_) async => 'bad_tok');
      when(() => mockDio.get('/profile')).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/profile')),
      );
      when(() => mockStorage.deleteToken()).thenAnswer((_) async {});

      await auth.tryAutoLogin();

      expect(auth.isAuthenticated, isFalse);
      expect(auth.user, isNull);
      verify(() => mockStorage.deleteToken()).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // loadLocation
  // -------------------------------------------------------------------------

  group('loadLocation', () {
    test('parses flat location object and sets location getter', () async {
      when(() => mockDio.get('/settings/location')).thenAnswer(
        (_) async => _fakeResponse(data: _locationJson),
      );

      await auth.loadLocation();

      expect(auth.location, isNotNull);
      expect(auth.location?.campusName, equals('Kampus A'));
      expect(auth.location?.campusLat, closeTo(-6.2, 0.0001));
      expect(auth.location?.campusLng, closeTo(106.816666, 0.0001));
      expect(auth.location?.radiusMeters, equals(200));
      expect(auth.location?.timezone, equals('Asia/Jakarta'));
    });
  });

  // -------------------------------------------------------------------------
  // updateProfile
  // -------------------------------------------------------------------------

  group('updateProfile', () {
    test('posts multipart with _method=PUT and updates user', () async {
      // Capture the FormData passed to post()
      FormData? capturedForm;
      when(
        () => mockDio.post('/profile', data: any(named: 'data')),
      ).thenAnswer((invocation) async {
        capturedForm = invocation.namedArguments[#data] as FormData;
        return _fakeResponse(data: {
          'user': {
            ..._userJson,
            'name': 'Budi Updated',
            'email': 'budi_new@example.com',
          },
        });
      });

      await auth.updateProfile(
        name: 'Budi Updated',
        email: 'budi_new@example.com',
        phone: '08123456789',
      );

      expect(auth.user?.name, equals('Budi Updated'));
      expect(auth.user?.email, equals('budi_new@example.com'));

      // Verify _method=PUT is present in the form fields.
      expect(
        capturedForm?.fields.any((f) => f.key == '_method' && f.value == 'PUT'),
        isTrue,
      );
      expect(
        capturedForm?.fields.any((f) => f.key == 'name' && f.value == 'Budi Updated'),
        isTrue,
      );
      expect(
        capturedForm?.fields.any((f) => f.key == 'email' && f.value == 'budi_new@example.com'),
        isTrue,
      );
      expect(
        capturedForm?.fields.any((f) => f.key == 'phone' && f.value == '08123456789'),
        isTrue,
      );
    });

    test('omits phone field when phone is null', () async {
      FormData? capturedForm;
      when(
        () => mockDio.post('/profile', data: any(named: 'data')),
      ).thenAnswer((invocation) async {
        capturedForm = invocation.namedArguments[#data] as FormData;
        return _fakeResponse(data: {'user': _userJson});
      });

      await auth.updateProfile(
        name: 'Budi',
        email: 'budi@example.com',
      );

      expect(
        capturedForm?.fields.any((f) => f.key == 'phone'),
        isFalse,
      );
    });
  });
}
