import 'attendance_model.dart';

/// Status presensi hari ini untuk satu matkul (user login).
/// Mirrors the `today` JSON: {has_check_in, has_check_out, can_check_in,
/// can_check_out, attendance|null}.
class CourseToday {
  const CourseToday({
    required this.hasCheckIn,
    required this.hasCheckOut,
    required this.canCheckIn,
    required this.canCheckOut,
    this.attendance,
  });

  final bool hasCheckIn;
  final bool hasCheckOut;
  final bool canCheckIn;
  final bool canCheckOut;
  final AttendanceModel? attendance;

  factory CourseToday.fromJson(Map<String, dynamic> json) {
    final att = json['attendance'];
    return CourseToday(
      hasCheckIn: json['has_check_in'] == true,
      hasCheckOut: json['has_check_out'] == true,
      canCheckIn: json['can_check_in'] == true,
      canCheckOut: json['can_check_out'] == true,
      attendance: att == null
          ? null
          : AttendanceModel.fromJson((att as Map).cast<String, dynamic>()),
    );
  }
}

/// Mirrors the `course` JSON contract:
/// {id, name, code, lecturer, check_in_start, late_after, check_out_start}
/// plus an optional nested [today] status used by the home cards.
class CourseModel {
  const CourseModel({
    required this.id,
    required this.name,
    required this.code,
    required this.lecturer,
    required this.checkInStart,
    required this.lateAfter,
    required this.checkOutStart,
    this.today,
  });

  final int id;
  final String name;
  final String code;
  final String lecturer;
  final String checkInStart; // "HH:MM"
  final String lateAfter; // "HH:MM"
  final String checkOutStart; // "HH:MM"
  final CourseToday? today;

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    final today = json['today'];
    return CourseModel(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
      lecturer: json['lecturer'] as String,
      checkInStart: json['check_in_start'] as String,
      lateAfter: json['late_after'] as String,
      checkOutStart: json['check_out_start'] as String,
      today: today == null
          ? null
          : CourseToday.fromJson((today as Map).cast<String, dynamic>()),
    );
  }

  /// Badge text for the home card derived from [today].
  /// Belum absen / Hadir / Terlambat / Selesai.
  String get statusLabel {
    final t = today;
    if (t == null || !t.hasCheckIn) return 'Belum absen';
    if (t.hasCheckOut) return 'Selesai';
    if (t.attendance?.checkInStatus == 'terlambat') return 'Terlambat';
    return 'Hadir';
  }
}
