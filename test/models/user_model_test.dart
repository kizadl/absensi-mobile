import 'package:flutter_test/flutter_test.dart';
import 'package:epresensi/models/attendance_model.dart';
import 'package:epresensi/models/user_model.dart';

void main() {
  group('UserModel.fromJson', () {
    test('parses a full mahasiswa payload', () {
      final json = {
        'id': 7,
        'role': 'mahasiswa',
        'name': 'Adit Saputra',
        'nim': '2021001',
        'username': 'adit',
        'email': 'adit@example.com',
        'phone': '0812345678',
        'photo': 'photos/adit.jpg',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 7);
      expect(user.role, 'mahasiswa');
      expect(user.name, 'Adit Saputra');
      expect(user.nim, '2021001');
      expect(user.username, 'adit');
      expect(user.email, 'adit@example.com');
      expect(user.phone, '0812345678');
      expect(user.photo, 'photos/adit.jpg');
    });

    test('handles null nim/phone/photo', () {
      final json = {
        'id': 1,
        'role': 'admin',
        'name': 'Admin',
        'nim': null,
        'username': 'admin',
        'email': 'admin@example.com',
        'phone': null,
        'photo': null,
      };

      final user = UserModel.fromJson(json);

      expect(user.nim, isNull);
      expect(user.phone, isNull);
      expect(user.photo, isNull);
      expect(user.role, 'admin');
    });
  });

  group('AttendanceModel.fromJson', () {
    test('parses date/check_in_at/check_out_at into DateTime', () {
      final json = {
        'id': 12,
        'date': '2026-06-20',
        'check_in_at': '2026-06-20 07:45:00',
        'check_in_lat': -6.2,
        'check_in_lng': 106.816666,
        'check_in_address': 'Kampus A',
        'check_in_status': 'tepat_waktu',
        'check_out_at': '2026-06-20 16:05:00',
        'check_out_lat': '-6.2',
        'check_out_lng': '106.816666',
        'check_out_address': 'Kampus A',
      };

      final att = AttendanceModel.fromJson(json);

      expect(att.id, 12);
      expect(att.date, DateTime(2026, 6, 20));
      expect(att.checkInAt, DateTime(2026, 6, 20, 7, 45, 0));
      expect(att.checkInLat, closeTo(-6.2, 1e-9));
      expect(att.checkInLng, closeTo(106.816666, 1e-9));
      expect(att.checkInStatus, 'tepat_waktu');
      expect(att.checkOutAt, DateTime(2026, 6, 20, 16, 5, 0));
      // lat/lng accepted as String too (parsed via _toDouble).
      expect(att.checkOutLat, closeTo(-6.2, 1e-9));
      expect(att.checkOutLng, closeTo(106.816666, 1e-9));
    });

    test('null check_out_at/lat/lng stay null', () {
      final json = {
        'id': 13,
        'date': '2026-06-21',
        'check_in_at': '2026-06-21 08:10:00',
        'check_in_lat': -6.2,
        'check_in_lng': 106.8,
        'check_in_address': 'Kampus A',
        'check_in_status': 'terlambat',
        'check_out_at': null,
        'check_out_lat': null,
        'check_out_lng': null,
        'check_out_address': null,
      };

      final att = AttendanceModel.fromJson(json);

      expect(att.date, DateTime(2026, 6, 21));
      expect(att.checkInAt, DateTime(2026, 6, 21, 8, 10, 0));
      expect(att.checkOutAt, isNull);
      expect(att.checkOutLat, isNull);
      expect(att.checkOutLng, isNull);
      expect(att.checkInStatus, 'terlambat');
    });
  });
}
