import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/attendance_model.dart';
import '../services/api_client.dart';

/// Enum tombol pintar presensi.
/// canCheckIn  : belum masuk.
/// canCheckOut : sudah masuk, belum pulang.
/// done        : sudah dua-duanya (atau kondisi mustahil → aman dikunci).
enum AttendanceButtonState { canCheckIn, canCheckOut, done }

/// Pure: derivasi state tombol pintar dari status presensi hari ini.
AttendanceButtonState deriveButtonState({
  required bool hasCheckIn,
  required bool hasCheckOut,
}) {
  if (!hasCheckIn && !hasCheckOut) return AttendanceButtonState.canCheckIn;
  if (hasCheckIn && !hasCheckOut) return AttendanceButtonState.canCheckOut;
  // hasCheckIn && hasCheckOut  → done
  // !hasCheckIn && hasCheckOut → kondisi mustahil, dikunci sebagai done
  return AttendanceButtonState.done;
}

class AttendanceProvider extends ChangeNotifier {
  AttendanceProvider(this._api);

  final ApiClient _api;

  bool _isLoading = false;
  String? _error;
  AttendanceModel? _today;
  bool _hasCheckIn = false;
  bool _hasCheckOut = false;
  bool _canCheckIn = false;
  bool _canCheckOut = false;
  List<AttendanceModel> _history = const [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  AttendanceModel? get today => _today;
  bool get hasCheckIn => _hasCheckIn;
  bool get hasCheckOut => _hasCheckOut;
  bool get canCheckIn => _canCheckIn;
  bool get canCheckOut => _canCheckOut;
  List<AttendanceModel> get history => _history;

  AttendanceButtonState get buttonState =>
      deriveButtonState(hasCheckIn: _hasCheckIn, hasCheckOut: _hasCheckOut);

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // loadToday — GET /courses/{courseId}/today
  // ---------------------------------------------------------------------------

  Future<void> loadToday(int courseId) async {
    _setLoading(true);
    _error = null;
    try {
      final res = await _api.dio.get('/courses/$courseId/today');
      // Response is the flat course+today shape: {...course, today:{...}}.
      final body = res.data as Map<String, dynamic>;
      final data = (body['today'] as Map).cast<String, dynamic>();
      _hasCheckIn = data['has_check_in'] == true;
      _hasCheckOut = data['has_check_out'] == true;
      _canCheckIn = data['can_check_in'] == true;
      _canCheckOut = data['can_check_out'] == true;
      final att = data['attendance'];
      _today = att == null
          ? null
          : AttendanceModel.fromJson(att as Map<String, dynamic>);
    } on DioException catch (e) {
      _error = _messageOf(e);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // checkIn — POST /courses/{courseId}/check-in
  // ---------------------------------------------------------------------------

  Future<AttendanceModel> checkIn({
    required int courseId,
    required double lat,
    required double lng,
    String? address,
  }) {
    return _doPunch(
      '/courses/$courseId/check-in',
      courseId: courseId,
      lat: lat,
      lng: lng,
      address: address,
    );
  }

  // ---------------------------------------------------------------------------
  // checkOut — POST /courses/{courseId}/check-out
  // ---------------------------------------------------------------------------

  Future<AttendanceModel> checkOut({
    required int courseId,
    required double lat,
    required double lng,
    String? address,
  }) {
    return _doPunch(
      '/courses/$courseId/check-out',
      courseId: courseId,
      lat: lat,
      lng: lng,
      address: address,
    );
  }

  Future<AttendanceModel> _doPunch(
    String path, {
    required int courseId,
    required double lat,
    required double lng,
    String? address,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final res = await _api.dio.post(
        path,
        data: {'lat': lat, 'lng': lng, 'address': address},
      );
      // ApiClient.validateStatus accepts status < 500, so 422 (di luar radius /
      // belum waktunya) and 409 (duplikat) arrive here as a normal response —
      // Dio does NOT throw. Surface the server's friendly `message` instead of
      // crashing on the absent `attendance` field.
      final status = res.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw AttendanceApiException(_messageFromBody(res.data));
      }
      final map = (res.data as Map<String, dynamic>)['attendance']
          as Map<String, dynamic>;
      final model = AttendanceModel.fromJson(map);
      await loadToday(courseId); // refresh status matkul (loadToday clears loading itself)
      return model;
    } on AttendanceApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      rethrow;
    } on DioException catch (e) {
      final msg = _messageOf(e);
      _error = msg;
      _setLoading(false);
      throw AttendanceApiException(msg);
    } catch (_) {
      // Unexpected (parsing, dll.) — tetap pesan ramah, jangan tampilkan error mentah.
      const msg = 'Presensi gagal. Coba lagi.';
      _error = msg;
      _setLoading(false);
      throw const AttendanceApiException(msg);
    }
  }

  // ---------------------------------------------------------------------------
  // loadHistory — GET /attendance/history?month=YYYY-MM[&course_id=N]
  // ---------------------------------------------------------------------------

  Future<void> loadHistory(String month, {int? courseId}) async {
    _setLoading(true);
    _error = null;
    try {
      final res = await _api.dio.get(
        '/attendance/history',
        queryParameters: {
          'month': month,
          'course_id': courseId,
        }..removeWhere((_, v) => v == null),
      );
      final list = (res.data as Map<String, dynamic>)['data'] as List<dynamic>;
      _history = list
          .map((e) => AttendanceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _error = _messageOf(e);
      _history = const [];
    } catch (e) {
      _error = e.toString();
      _history = const [];
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Ambil pesan dari body API ({message}) bila ada, jika tidak pakai pesan Dio.
  String _messageOf(DioException e) => _messageFromBody(e.response?.data);

  /// Ekstrak `{message}` dari body response (mis. 422/409 yang di-return Dio).
  String _messageFromBody(dynamic data) {
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return 'Terjadi kesalahan jaringan.';
  }
}

/// Exception dilempar ketika check-in / check-out gagal di API.
class AttendanceApiException implements Exception {
  const AttendanceApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
