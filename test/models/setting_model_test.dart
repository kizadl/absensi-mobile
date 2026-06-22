import 'package:flutter_test/flutter_test.dart';
import 'package:epresensi/models/setting_model.dart';

void main() {
  group('SettingModel.fromJson', () {
    test('parses all 5 fields from a normal JSON map', () {
      final json = <String, dynamic>{
        'campus_name': 'Kampus Utama',
        'campus_lat': -6.200000,
        'campus_lng': 106.816666,
        'radius_meters': 150,
        'timezone': 'Asia/Jakarta',
      };

      final model = SettingModel.fromJson(json);

      expect(model.campusName, 'Kampus Utama');
      expect(model.campusLat, closeTo(-6.2, 1e-9));
      expect(model.campusLng, closeTo(106.816666, 1e-9));
      expect(model.radiusMeters, 150);
      expect(model.timezone, 'Asia/Jakarta');
    });

    test('parses campus_lat/campus_lng/radius_meters from numeric-string inputs', () {
      final json = <String, dynamic>{
        'campus_name': 'Kampus B',
        'campus_lat': '-6.300000',
        'campus_lng': '106.900000',
        'radius_meters': '200',
        'timezone': 'Asia/Makassar',
      };

      final model = SettingModel.fromJson(json);

      expect(model.campusLat, isA<double>());
      expect(model.campusLat, closeTo(-6.3, 1e-9));
      expect(model.campusLng, isA<double>());
      expect(model.campusLng, closeTo(106.9, 1e-9));
      expect(model.radiusMeters, isA<int>());
      expect(model.radiusMeters, 200);
    });

    test('parses radius_meters from a double (backend quirk)', () {
      final json = <String, dynamic>{
        'campus_name': 'Kampus C',
        'campus_lat': -7.0,
        'campus_lng': 110.0,
        'radius_meters': 100.0,
        'timezone': 'Asia/Jakarta',
      };

      final model = SettingModel.fromJson(json);

      expect(model.radiusMeters, isA<int>());
      expect(model.radiusMeters, 100);
    });

    test('throws when a required field is missing', () {
      final json = <String, dynamic>{
        'campus_name': 'Kampus D',
        // campus_lat intentionally missing
        'campus_lng': 106.816666,
        'radius_meters': 150,
        'timezone': 'Asia/Jakarta',
      };

      expect(() => SettingModel.fromJson(json), throwsA(anything));
    });
  });
}
