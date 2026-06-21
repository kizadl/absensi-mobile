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
  // loadToday — GET /attendance/today
  // ---------------------------------------------------------------------------

  Future<void> loadToday() async {
    _setLoading(true);
    _error = null;
    try {
      final res = await _api.dio.get('/attendance/today');
      final data = res.data as Map<String, dynamic>;
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
  // checkIn — POST /attendance/check-in
  // ---------------------------------------------------------------------------

  Future<AttendanceModel> checkIn({
    required double lat,
    required double lng,
    String? address,
  }) {
    return _doPunch('/attendance/check-in', lat: lat, lng: lng, address: address);
  }

  // ---------------------------------------------------------------------------
  // checkOut — POST /attendance/check-out
  // ---------------------------------------------------------------------------

  Future<AttendanceModel> checkOut({
    required double lat,
    required double lng,
    String? address,
  }) {
    return _doPunch('/attendance/check-out', lat: lat, lng: lng, address: address);
  }

  Future<AttendanceModel> _doPunch(
    String path, {
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
      final map = (res.data as Map<String, dynamic>)['attendance']
          as Map<String, dynamic>;
      final model = AttendanceModel.fromJson(map);
      await loadToday(); // refresh status hari ini (loadToday clears loading itself)
      return model;
    } on DioException catch (e) {
      final msg = _messageOf(e);
      _error = msg;
      _setLoading(false);
      throw AttendanceApiException(msg);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // loadHistory — GET /attendance/history?month=YYYY-MM
  // ---------------------------------------------------------------------------

  Future<void> loadHistory(String month) async {
    _setLoading(true);
    _error = null;
    try {
      final res = await _api.dio.get(
        '/attendance/history',
        queryParameters: {'month': month},
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
  String _messageOf(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return e.message ?? 'Terjadi kesalahan jaringan.';
  }
}

/// Exception dilempar ketika check-in / check-out gagal di API.
class AttendanceApiException implements Exception {
  const AttendanceApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
