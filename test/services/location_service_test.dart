import 'package:flutter_test/flutter_test.dart';
import 'package:epresensi/services/location_service.dart';

void main() {
  group('LocationService.distanceMeters (haversine)', () {
    final service = LocationService();

    test('jarak titik yang sama adalah 0', () {
      expect(service.distanceMeters(-6.200000, 106.816666, -6.200000, 106.816666),
          closeTo(0, 0.001));
    });

    test('jarak Monas → Bundaran HI ~ 2010 m (toleransi 50 m)', () {
      // Monas: -6.175392, 106.827153 ; Bundaran HI: -6.193125, 106.823418
      final d = service.distanceMeters(
          -6.175392, 106.827153, -6.193125, 106.823418);
      expect(d, closeTo(2010, 50));
    });

    test('jarak 1 derajat lintang di ekuator ~ 111.19 km', () {
      final d = service.distanceMeters(0.0, 0.0, 1.0, 0.0);
      expect(d, closeTo(111195, 200));
    });

    test('simetris: d(A,B) == d(B,A)', () {
      final ab = service.distanceMeters(-6.1, 106.8, -6.2, 106.9);
      final ba = service.distanceMeters(-6.2, 106.9, -6.1, 106.8);
      expect(ab, closeTo(ba, 0.0001));
    });
  });
}
