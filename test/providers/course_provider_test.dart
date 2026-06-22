import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:epresensi/providers/course_provider.dart';
import 'package:epresensi/services/api_client.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

Response<dynamic> _res(dynamic data, {int statusCode = 200}) => Response(
      requestOptions: RequestOptions(path: ''),
      data: data,
      statusCode: statusCode,
    );

const _coursesResponse = {
  'data': [
    {
      'id': 1,
      'name': 'Pemrograman Web',
      'code': 'IF301',
      'lecturer': 'Dr. Budi',
      'check_in_start': '07:00',
      'late_after': '07:15',
      'check_out_start': '15:00',
      'today': {
        'has_check_in': false,
        'has_check_out': false,
        'can_check_in': true,
        'can_check_out': false,
        'attendance': null,
      },
    },
    {
      'id': 2,
      'name': 'Basis Data',
      'code': 'IF302',
      'lecturer': 'Dr. Sari',
      'check_in_start': '09:00',
      'late_after': '09:15',
      'check_out_start': '11:00',
      'today': {
        'has_check_in': true,
        'has_check_out': false,
        'can_check_in': false,
        'can_check_out': true,
        'attendance': {
          'id': 9,
          'date': '2026-06-22',
          'check_in_at': '2026-06-22 09:05:00',
          'check_in_status': 'tepat_waktu',
        },
      },
    },
  ],
};

void main() {
  late MockApiClient api;
  late MockDio dio;
  late CourseProvider provider;

  setUp(() {
    api = MockApiClient();
    dio = MockDio();
    when(() => api.dio).thenReturn(dio);
    provider = CourseProvider(api);
  });

  group('initial state', () {
    test('isLoading false, error null, courses empty', () {
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
      expect(provider.courses, isEmpty);
    });
  });

  group('loadCourses', () {
    test('parses data into CourseModel list with today', () async {
      when(() => dio.get('/courses'))
          .thenAnswer((_) async => _res(_coursesResponse));

      await provider.loadCourses();

      expect(provider.courses, hasLength(2));
      expect(provider.courses.first.code, 'IF301');
      expect(provider.courses.first.statusLabel, 'Belum absen');
      expect(provider.courses[1].statusLabel, 'Hadir');
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('sets isLoading true during request, false after', () async {
      var during = false;
      when(() => dio.get('/courses')).thenAnswer((_) async {
        during = provider.isLoading;
        return _res(_coursesResponse);
      });

      await provider.loadCourses();

      expect(during, isTrue);
      expect(provider.isLoading, isFalse);
    });

    test('DioException sets error, leaves courses empty', () async {
      when(() => dio.get('/courses')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/courses'),
          response: _res({'message': 'Unauthenticated.'}, statusCode: 401),
          type: DioExceptionType.badResponse,
        ),
      );

      await provider.loadCourses();

      expect(provider.error, isNotNull);
      expect(provider.courses, isEmpty);
      expect(provider.isLoading, isFalse);
    });
  });
}
