import 'dart:math' as math;

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Exception yang dilempar saat akses lokasi gagal.
class LocationException implements Exception {
  final String message;
  const LocationException(this.message);

  @override
  String toString() => message;
}

/// Layanan GPS: izin, posisi, jarak haversine, reverse-geocode.
class LocationService {
  /// Radius bumi rata-rata dalam meter (identik dengan konstanta backend).
  static const double _earthRadiusM = 6371000.0;

  /// Haversine formula — pure function, aman diunit-test tanpa plugin.
  ///
  /// Mengembalikan jarak dalam meter antara dua koordinat geografis.
  double distanceMeters(
      double lat1, double lng1, double lat2, double lng2) {
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusM * c;
  }

  double _toRad(double deg) => deg * (math.pi / 180.0);

  /// Minta izin lokasi & ambil posisi sekarang.
  ///
  /// Melempar [LocationException] bila:
  /// - Layanan GPS tidak aktif.
  /// - Izin lokasi ditolak atau ditolak permanen.
  /// - Timeout saat mengambil posisi.
  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
          'Layanan lokasi (GPS) tidak aktif. Aktifkan dulu.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException('Izin lokasi ditolak.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
          'Izin lokasi ditolak permanen. Aktifkan dari Pengaturan aplikasi.');
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      throw LocationException('Gagal mengambil lokasi: $e');
    }
  }

  /// Reverse-geocode koordinat ke string alamat.
  ///
  /// Mengembalikan `'-'` bila tidak ada placemark atau terjadi error (non-fatal).
  Future<String> addressFromLatLng(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return '-';
      final p = placemarks.first;
      final parts = <String?>[
        p.street,
        p.subLocality,
        p.locality,
        p.subAdministrativeArea,
        p.administrativeArea,
      ]
          .where((s) => s != null && s.trim().isNotEmpty)
          .cast<String>()
          .toList();
      return parts.isEmpty ? '-' : parts.join(', ');
    } catch (_) {
      return '-';
    }
  }
}
