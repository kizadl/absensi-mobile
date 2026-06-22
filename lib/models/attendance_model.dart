/// Minimal course reference embedded in a history attendance row:
/// {id, name, code}.
class AttendanceCourse {
  const AttendanceCourse({
    required this.id,
    required this.name,
    required this.code,
  });

  final int id;
  final String name;
  final String code;

  factory AttendanceCourse.fromJson(Map<String, dynamic> json) {
    return AttendanceCourse(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
    );
  }
}

/// Mirrors the Attendance JSON resource contract:
/// {id, date, check_in_at, check_in_lat, check_in_lng, check_in_address,
///  check_in_status, check_out_at, check_out_lat, check_out_lng,
///  check_out_address, course_id, course}
class AttendanceModel {
  const AttendanceModel({
    required this.id,
    required this.date,
    this.checkInAt,
    this.checkInLat,
    this.checkInLng,
    this.checkInAddress,
    this.checkInStatus,
    this.checkOutAt,
    this.checkOutLat,
    this.checkOutLng,
    this.checkOutAddress,
    this.courseId,
    this.course,
  });

  final int id;
  final DateTime date;
  final DateTime? checkInAt;
  final double? checkInLat;
  final double? checkInLng;
  final String? checkInAddress;
  final String? checkInStatus; // 'tepat_waktu' | 'terlambat'
  final DateTime? checkOutAt;
  final double? checkOutLat;
  final double? checkOutLng;
  final String? checkOutAddress;
  final int? courseId;
  final AttendanceCourse? course;

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as int,
      // Backend emits date as 'YYYY-MM-DD' and *_at as
      // 'YYYY-MM-DD HH:MM:SS' — both accepted by DateTime.parse.
      date: DateTime.parse(json['date'] as String),
      checkInAt: json['check_in_at'] == null
          ? null
          : DateTime.parse(json['check_in_at'] as String),
      checkInLat: _toDouble(json['check_in_lat']),
      checkInLng: _toDouble(json['check_in_lng']),
      checkInAddress: json['check_in_address'] as String?,
      checkInStatus: json['check_in_status'] as String?,
      checkOutAt: json['check_out_at'] == null
          ? null
          : DateTime.parse(json['check_out_at'] as String),
      checkOutLat: _toDouble(json['check_out_lat']),
      checkOutLng: _toDouble(json['check_out_lng']),
      checkOutAddress: json['check_out_address'] as String?,
      courseId: json['course_id'] as int?,
      course: json['course'] == null
          ? null
          : AttendanceCourse.fromJson(
              (json['course'] as Map).cast<String, dynamic>()),
    );
  }
}
