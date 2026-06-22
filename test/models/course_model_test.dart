import 'package:flutter_test/flutter_test.dart';

import 'package:epresensi/models/course_model.dart';

void main() {
  const courseJson = {
    'id': 7,
    'name': 'Pemrograman Web',
    'code': 'IF301',
    'lecturer': 'Dr. Budi',
    'check_in_start': '07:00',
    'late_after': '07:15',
    'check_out_start': '15:00',
  };

  group('CourseModel.fromJson', () {
    test('parses the course fields', () {
      final c = CourseModel.fromJson(courseJson);
      expect(c.id, 7);
      expect(c.name, 'Pemrograman Web');
      expect(c.code, 'IF301');
      expect(c.lecturer, 'Dr. Budi');
      expect(c.checkInStart, '07:00');
      expect(c.lateAfter, '07:15');
      expect(c.checkOutStart, '15:00');
    });

    test('today is null when absent', () {
      expect(CourseModel.fromJson(courseJson).today, isNull);
    });

    test('parses nested today + attendance', () {
      final c = CourseModel.fromJson({
        ...courseJson,
        'today': {
          'has_check_in': true,
          'has_check_out': false,
          'can_check_in': false,
          'can_check_out': true,
          'attendance': {
            'id': 1,
            'date': '2026-06-22',
            'check_in_at': '2026-06-22 07:05:00',
            'check_in_status': 'tepat_waktu',
          },
        },
      });
      expect(c.today, isNotNull);
      expect(c.today!.hasCheckIn, isTrue);
      expect(c.today!.canCheckOut, isTrue);
      expect(c.today!.attendance, isNotNull);
      expect(c.today!.attendance!.checkInStatus, 'tepat_waktu');
    });
  });

  group('statusLabel', () {
    CourseModel withToday(Map<String, dynamic> today) =>
        CourseModel.fromJson({...courseJson, 'today': today});

    test('no today → "Belum absen"', () {
      expect(CourseModel.fromJson(courseJson).statusLabel, 'Belum absen');
    });

    test('not checked in → "Belum absen"', () {
      final c = withToday({
        'has_check_in': false,
        'has_check_out': false,
        'can_check_in': true,
        'can_check_out': false,
        'attendance': null,
      });
      expect(c.statusLabel, 'Belum absen');
    });

    test('checked in tepat_waktu, not out → "Hadir"', () {
      final c = withToday({
        'has_check_in': true,
        'has_check_out': false,
        'can_check_in': false,
        'can_check_out': true,
        'attendance': {
          'id': 1,
          'date': '2026-06-22',
          'check_in_at': '2026-06-22 07:05:00',
          'check_in_status': 'tepat_waktu',
        },
      });
      expect(c.statusLabel, 'Hadir');
    });

    test('checked in terlambat → "Terlambat"', () {
      final c = withToday({
        'has_check_in': true,
        'has_check_out': false,
        'can_check_in': false,
        'can_check_out': true,
        'attendance': {
          'id': 1,
          'date': '2026-06-22',
          'check_in_at': '2026-06-22 07:20:00',
          'check_in_status': 'terlambat',
        },
      });
      expect(c.statusLabel, 'Terlambat');
    });

    test('checked in & out → "Selesai"', () {
      final c = withToday({
        'has_check_in': true,
        'has_check_out': true,
        'can_check_in': false,
        'can_check_out': false,
        'attendance': {
          'id': 1,
          'date': '2026-06-22',
          'check_in_at': '2026-06-22 07:05:00',
          'check_in_status': 'tepat_waktu',
          'check_out_at': '2026-06-22 15:30:00',
        },
      });
      expect(c.statusLabel, 'Selesai');
    });
  });
}
