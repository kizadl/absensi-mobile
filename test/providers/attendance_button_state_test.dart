import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:epresensi/providers/attendance_provider.dart';
import 'package:epresensi/services/api_client.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

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

/// Wraps a today fixture inside the flat course+today shape returned by
/// GET /courses/{id}/today.
Map<String, dynamic> _wrapToday(Map<String, dynamic> today) => {
      'id': 5,
      'name': 'Pemrograman Web',
      'code': 'IF301',
      'lecturer': 'Dr. Budi',
      'check_in_start': '07:00',
      'late_after': '07:15',
      'check_out_start': '15:00',
      'today': today,
    };

/// Today fixture — belum check-in sama sekali.
const Map<String, dynamic> _todayCanCheckIn = {
  'has_check_in': false,
  'has_check_out': false,
  'can_check_in': true,
  'can_check_out': false,
  'attendance': null,
};

/// Today fixture — sudah check-in, belum check-out.
const Map<String, dynamic> _todayCanCheckOut = {
  'has_check_in': true,
  'has_check_out': false,
  'can_check_in': false,
  'can_check_out': true,
  'attendance': {
    'id': 1,
    'date': '2026-06-22',
    'check_in_at': '2026-06-22 08:00:00',
    'check_in_lat': -6.2,
    'check_in_lng': 106.816666,
    'check_in_address': 'Kampus A',
    'check_in_status': 'tepat_waktu',
    'check_out_at': null,
    'check_out_lat': null,
    'check_out_lng': null,
    'check_out_address': null,
  },
};

/// Today fixture — sudah check-in & check-out.
const Map<String, dynamic> _todayDone = {
  'has_check_in': true,
  'has_check_out': true,
  'can_check_in': false,
  'can_check_out': false,
  'attendance': {
    'id': 1,
    'date': '2026-06-22',
    'check_in_at': '2026-06-22 08:00:00',
    'check_in_lat': -6.2,
    'check_in_lng': 106.816666,
    'check_in_address': 'Kampus A',
    'check_in_status': 'tepat_waktu',
    'check_out_at': '2026-06-22 16:00:00',
    'check_out_lat': -6.2,
    'check_out_lng': 106.816666,
    'check_out_address': 'Kampus A',
  },
};

/// History fixture.
const Map<String, dynamic> _historyResponse = {
  'data': [
    {
      'id': 1,
      'date': '2026-06-01',
      'check_in_at': '2026-06-01 08:00:00',
      'check_in_lat': -6.2,
      'check_in_lng': 106.816666,
      'check_in_address': 'Kampus A',
      'check_in_status': 'tepat_waktu',
      'check_out_at': '2026-06-01 16:00:00',
      'check_out_lat': -6.2,
      'check_out_lng': 106.816666,
      'check_out_address': 'Kampus A',
    },
  ],
};

/// Attendance POST response fixture (check-in / check-out).
Map<String, dynamic> _punchResponse({bool withCheckOut = false}) => {
      'attendance': {
        'id': 2,
        'date': '2026-06-22',
        'check_in_at': '2026-06-22 08:05:00',
        'check_in_lat': -6.2,
        'check_in_lng': 106.816666,
        'check_in_address': 'Jl. Raya',
        'check_in_status': 'tepat_waktu',
        'check_out_at': withCheckOut ? '2026-06-22 16:05:00' : null,
        'check_out_lat': withCheckOut ? -6.2 : null,
        'check_out_lng': withCheckOut ? 106.816666 : null,
        'check_out_address': withCheckOut ? 'Jl. Raya' : null,
      },
    };

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
    registerFallbackValue(Options());
  });

  // =========================================================================
  // GROUP 1 – Pure deriveButtonState function
  // =========================================================================

  group('deriveButtonState', () {
    test('belum check-in → canCheckIn', () {
      expect(
        deriveButtonState(hasCheckIn: false, hasCheckOut: false),
        AttendanceButtonState.canCheckIn,
      );
    });

    test('sudah check-in, belum check-out → canCheckOut', () {
      expect(
        deriveButtonState(hasCheckIn: true, hasCheckOut: false),
        AttendanceButtonState.canCheckOut,
      );
    });

    test('sudah check-in & check-out → done', () {
      expect(
        deriveButtonState(hasCheckIn: true, hasCheckOut: true),
        AttendanceButtonState.done,
      );
    });

    test('kondisi mustahil (checkOut tanpa checkIn) dianggap done (aman)', () {
      expect(
        deriveButtonState(hasCheckIn: false, hasCheckOut: true),
        AttendanceButtonState.done,
      );
    });
  });

  // =========================================================================
  // GROUP 2 – AttendanceProvider methods
  // =========================================================================

  group('AttendanceProvider', () {
    late MockApiClient mockApiClient;
    late MockDio mockDio;
    late AttendanceProvider provider;

    setUp(() {
      mockApiClient = MockApiClient();
      mockDio = MockDio();
      when(() => mockApiClient.dio).thenReturn(mockDio);
      provider = AttendanceProvider(mockApiClient);
    });

    // -----------------------------------------------------------------------
    // Initial state
    // -----------------------------------------------------------------------

    group('initial state', () {
      test('isLoading is false', () => expect(provider.isLoading, isFalse));
      test('error is null', () => expect(provider.error, isNull));
      test('today is null', () => expect(provider.today, isNull));
      test('history is empty', () => expect(provider.history, isEmpty));
      test('hasCheckIn is false', () => expect(provider.hasCheckIn, isFalse));
      test('hasCheckOut is false', () => expect(provider.hasCheckOut, isFalse));
      test('canCheckIn is false', () => expect(provider.canCheckIn, isFalse));
      test('canCheckOut is false', () => expect(provider.canCheckOut, isFalse));
      test('buttonState is canCheckIn (default)', () {
        expect(provider.buttonState, AttendanceButtonState.canCheckIn);
      });
    });

    // -----------------------------------------------------------------------
    // loadToday
    // -----------------------------------------------------------------------

    group('loadToday', () {
      test('belum check-in: sets hasCheckIn=false, buttonState=canCheckIn', () async {
        when(() => mockDio.get('/courses/5/today'))
            .thenAnswer((_) async => _fakeResponse(data: _wrapToday(_todayCanCheckIn)));

        await provider.loadToday(5);

        expect(provider.hasCheckIn, isFalse);
        expect(provider.hasCheckOut, isFalse);
        expect(provider.canCheckIn, isTrue);
        expect(provider.canCheckOut, isFalse);
        expect(provider.today, isNull);
        expect(provider.buttonState, AttendanceButtonState.canCheckIn);
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
      });

      test('sudah check-in: sets buttonState=canCheckOut, today non-null', () async {
        when(() => mockDio.get('/courses/5/today'))
            .thenAnswer((_) async => _fakeResponse(data: _wrapToday(_todayCanCheckOut)));

        await provider.loadToday(5);

        expect(provider.hasCheckIn, isTrue);
        expect(provider.hasCheckOut, isFalse);
        expect(provider.buttonState, AttendanceButtonState.canCheckOut);
        expect(provider.today, isNotNull);
        expect(provider.today?.checkInAt, isNotNull);
        expect(provider.isLoading, isFalse);
      });

      test('sudah check-in & out: sets buttonState=done', () async {
        when(() => mockDio.get('/courses/5/today'))
            .thenAnswer((_) async => _fakeResponse(data: _wrapToday(_todayDone)));

        await provider.loadToday(5);

        expect(provider.hasCheckIn, isTrue);
        expect(provider.hasCheckOut, isTrue);
        expect(provider.buttonState, AttendanceButtonState.done);
        expect(provider.today?.checkOutAt, isNotNull);
        expect(provider.isLoading, isFalse);
      });

      test('DioException: sets error, clears loading', () async {
        when(() => mockDio.get('/courses/5/today')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/courses/5/today'),
            response: _fakeResponse(
              data: {'message': 'Unauthenticated.'},
              statusCode: 401,
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        await provider.loadToday(5);

        expect(provider.error, isNotNull);
        expect(provider.isLoading, isFalse);
      });

      test('sets isLoading=true during request then false after', () async {
        var loadingDuringCall = false;
        when(() => mockDio.get('/courses/5/today')).thenAnswer((_) async {
          loadingDuringCall = provider.isLoading;
          return _fakeResponse(data: _wrapToday(_todayCanCheckIn));
        });

        await provider.loadToday(5);

        expect(loadingDuringCall, isTrue);
        expect(provider.isLoading, isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // checkIn
    // -----------------------------------------------------------------------

    group('checkIn', () {
      setUp(() {
        // After checkIn, the provider calls loadToday internally.
        when(() => mockDio.get('/courses/5/today'))
            .thenAnswer((_) async => _fakeResponse(data: _wrapToday(_todayCanCheckOut)));
      });

      test('posts to /courses/5/check-in with lat, lng, address', () async {
        when(
          () => mockDio.post(
            '/courses/5/check-in',
            data: any(named: 'data'),
          ),
        ).thenAnswer((_) async => _fakeResponse(data: _punchResponse()));

        await provider.checkIn(courseId: 5, lat: -6.2, lng: 106.816666, address: 'Jl. Raya');

        final captured = verify(
          () => mockDio.post(
            '/courses/5/check-in',
            data: captureAny(named: 'data'),
          ),
        ).captured;

        final body = captured.first as Map<String, dynamic>;
        expect(body['lat'], closeTo(-6.2, 0.0001));
        expect(body['lng'], closeTo(106.816666, 0.0001));
        expect(body['address'], equals('Jl. Raya'));
      });

      test('returns AttendanceModel on success', () async {
        when(
          () => mockDio.post(
            '/courses/5/check-in',
            data: any(named: 'data'),
          ),
        ).thenAnswer((_) async => _fakeResponse(data: _punchResponse()));

        final model = await provider.checkIn(courseId: 5, lat: -6.2, lng: 106.816666);

        expect(model, isNotNull);
        expect(model.checkInAt, isNotNull);
      });

      test('includes null address in body', () async {
        when(
          () => mockDio.post(
            '/courses/5/check-in',
            data: any(named: 'data'),
          ),
        ).thenAnswer((_) async => _fakeResponse(data: _punchResponse()));

        await provider.checkIn(courseId: 5, lat: -6.2, lng: 106.816666, address: null);

        final captured = verify(
          () => mockDio.post(
            '/courses/5/check-in',
            data: captureAny(named: 'data'),
          ),
        ).captured;
        final body = captured.first as Map<String, dynamic>;
        expect(body.containsKey('address'), isTrue);
        expect(body['address'], isNull);
      });

      test('throws AttendanceApiException on DioException', () async {
        when(
          () => mockDio.post(
            '/courses/5/check-in',
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/courses/5/check-in'),
            response: _fakeResponse(
              data: {'message': 'Di luar radius kampus.'},
              statusCode: 422,
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        await expectLater(
          () => provider.checkIn(courseId: 5, lat: -6.2, lng: 106.816666),
          throwsA(isA<AttendanceApiException>()),
        );
        expect(provider.error, isNotNull);
        expect(provider.isLoading, isFalse);
      });

      test('shows the server message when 422 is RETURNED (not thrown) — e.g. di luar area kampus', () async {
        when(
          () => mockDio.post(
            '/courses/5/check-in',
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => _fakeResponse(
            data: {'message': 'Anda di luar area kampus (250 m).'},
            statusCode: 422,
          ),
        );

        await expectLater(
          () => provider.checkIn(courseId: 5, lat: -6.2, lng: 106.816666),
          throwsA(
            isA<AttendanceApiException>().having(
              (e) => e.message,
              'message',
              'Anda di luar area kampus (250 m).',
            ),
          ),
        );
        expect(provider.error, 'Anda di luar area kampus (250 m).');
        expect(provider.isLoading, isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // checkOut
    // -----------------------------------------------------------------------

    group('checkOut', () {
      setUp(() {
        when(() => mockDio.get('/courses/5/today'))
            .thenAnswer((_) async => _fakeResponse(data: _wrapToday(_todayDone)));
      });

      test('posts to /courses/5/check-out with lat, lng, address', () async {
        when(
          () => mockDio.post(
            '/courses/5/check-out',
            data: any(named: 'data'),
          ),
        ).thenAnswer((_) async => _fakeResponse(data: _punchResponse(withCheckOut: true)));

        await provider.checkOut(courseId: 5, lat: -6.2, lng: 106.816666, address: 'Kantor');

        final captured = verify(
          () => mockDio.post(
            '/courses/5/check-out',
            data: captureAny(named: 'data'),
          ),
        ).captured;

        final body = captured.first as Map<String, dynamic>;
        expect(body['lat'], closeTo(-6.2, 0.0001));
        expect(body['lng'], closeTo(106.816666, 0.0001));
        expect(body['address'], equals('Kantor'));
      });

      test('returns AttendanceModel with checkOutAt on success', () async {
        when(
          () => mockDio.post(
            '/courses/5/check-out',
            data: any(named: 'data'),
          ),
        ).thenAnswer((_) async => _fakeResponse(data: _punchResponse(withCheckOut: true)));

        final model = await provider.checkOut(courseId: 5, lat: -6.2, lng: 106.816666);

        expect(model.checkOutAt, isNotNull);
      });

      test('throws AttendanceApiException on DioException', () async {
        when(
          () => mockDio.post(
            '/courses/5/check-out',
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/courses/5/check-out'),
            response: _fakeResponse(
              data: {'message': 'Belum check-in.'},
              statusCode: 422,
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        await expectLater(
          () => provider.checkOut(courseId: 5, lat: -6.2, lng: 106.816666),
          throwsA(isA<AttendanceApiException>()),
        );
      });

      test('shows the server message when 422 is RETURNED (not thrown) — e.g. belum waktunya pulang', () async {
        // validateStatus < 500 means Dio RETURNS the 422 response instead of
        // throwing. The provider must surface the friendly `message`, not crash
        // casting the (absent) `attendance` field.
        when(
          () => mockDio.post(
            '/courses/5/check-out',
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => _fakeResponse(
            data: {'message': 'Belum waktunya absen pulang.'},
            statusCode: 422,
          ),
        );

        await expectLater(
          () => provider.checkOut(courseId: 5, lat: -6.2, lng: 106.816666),
          throwsA(
            isA<AttendanceApiException>().having(
              (e) => e.message,
              'message',
              'Belum waktunya absen pulang.',
            ),
          ),
        );
        expect(provider.error, 'Belum waktunya absen pulang.');
        expect(provider.isLoading, isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // loadHistory
    // -----------------------------------------------------------------------

    group('loadHistory', () {
      test('calls GET /attendance/history with queryParameters month', () async {
        when(
          () => mockDio.get(
            '/attendance/history',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => _fakeResponse(data: _historyResponse));

        await provider.loadHistory('2026-06');

        final captured = verify(
          () => mockDio.get(
            '/attendance/history',
            queryParameters: captureAny(named: 'queryParameters'),
          ),
        ).captured;

        final params = captured.first as Map<String, dynamic>;
        expect(params['month'], equals('2026-06'));
      });

      test('parses history list and sets provider.history', () async {
        when(
          () => mockDio.get(
            '/attendance/history',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => _fakeResponse(data: _historyResponse));

        await provider.loadHistory('2026-06');

        expect(provider.history, hasLength(1));
        expect(provider.history.first.date, equals(DateTime(2026, 6, 1)));
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
      });

      test('empty data list results in empty history', () async {
        when(
          () => mockDio.get(
            '/attendance/history',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => _fakeResponse(data: {'data': <dynamic>[]}));

        await provider.loadHistory('2026-06');

        expect(provider.history, isEmpty);
      });

      test('DioException: sets error, history stays empty', () async {
        when(
          () => mockDio.get(
            '/attendance/history',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/attendance/history'),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        await provider.loadHistory('2026-06');

        expect(provider.error, isNotNull);
        expect(provider.history, isEmpty);
        expect(provider.isLoading, isFalse);
      });

      test('passes course_id when courseId provided', () async {
        when(
          () => mockDio.get(
            '/attendance/history',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => _fakeResponse(data: _historyResponse));

        await provider.loadHistory('2026-06', courseId: 3);

        final captured = verify(
          () => mockDio.get(
            '/attendance/history',
            queryParameters: captureAny(named: 'queryParameters'),
          ),
        ).captured;
        final params = captured.first as Map<String, dynamic>;
        expect(params['month'], '2026-06');
        expect(params['course_id'], 3);
      });
    });
  });
}
