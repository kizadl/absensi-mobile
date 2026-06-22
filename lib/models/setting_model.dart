/// Mirrors GET /api/settings/location (global geofence only — jam presensi
/// now lives per-course): {campus_name, campus_lat, campus_lng,
/// radius_meters, timezone}.
class SettingModel {
  const SettingModel({
    required this.campusName,
    required this.campusLat,
    required this.campusLng,
    required this.radiusMeters,
    required this.timezone,
  });

  final String campusName;
  final double campusLat;
  final double campusLng;
  final int radiusMeters;
  final String timezone;

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.parse(v.toString());
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.parse(v.toString());
  }

  factory SettingModel.fromJson(Map<String, dynamic> json) {
    return SettingModel(
      campusName: json['campus_name'] as String,
      campusLat: _toDouble(json['campus_lat']),
      campusLng: _toDouble(json['campus_lng']),
      radiusMeters: _toInt(json['radius_meters']),
      timezone: json['timezone'] as String,
    );
  }
}
