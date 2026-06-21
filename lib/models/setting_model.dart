/// Mirrors GET /api/settings/location:
/// {campus_name, campus_lat, campus_lng, radius_meters, check_in_start,
///  late_after, check_out_start, timezone}
class SettingModel {
  const SettingModel({
    required this.campusName,
    required this.campusLat,
    required this.campusLng,
    required this.radiusMeters,
    required this.checkInStart,
    required this.lateAfter,
    required this.checkOutStart,
    required this.timezone,
  });

  final String campusName;
  final double campusLat;
  final double campusLng;
  final int radiusMeters;
  final String checkInStart;
  final String lateAfter;
  final String checkOutStart;
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
      checkInStart: json['check_in_start'] as String,
      lateAfter: json['late_after'] as String,
      checkOutStart: json['check_out_start'] as String,
      timezone: json['timezone'] as String,
    );
  }
}
