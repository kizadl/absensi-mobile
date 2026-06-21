import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/setting_model.dart';
import '../models/user_model.dart';
import '../services/api_client.dart';
import '../services/secure_storage_service.dart';

/// Holds authentication state: the current [UserModel] and Sanctum token,
/// plus the campus [SettingModel] consumed by the Home geofence flow.
class AuthProvider extends ChangeNotifier {
  AuthProvider({required ApiClient apiClient, SecureStorageService? storage})
      : _storage = storage ?? SecureStorageService(),
        _api = apiClient;

  final ApiClient _api;
  final SecureStorageService _storage;

  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;
  SettingModel? _location;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  SettingModel? get location => _location;

  /// Attempts login against POST /api/login.
  /// Returns true on success; sets [error] on failure.
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.dio.post('/login', data: {
        'username': username,
        'password': password,
      });

      if (res.statusCode == 200 && res.data is Map) {
        final data = res.data as Map<String, dynamic>;
        final token = data['token'] as String;
        final user = UserModel.fromJson(
          (data['user'] as Map).cast<String, dynamic>(),
        );
        await _storage.saveToken(token);
        _token = token;
        _user = user;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = _messageFrom(res.data) ?? 'Username atau password salah.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _error = _messageFrom(e.response?.data) ??
          'Gagal terhubung ke server. Coba lagi.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Calls POST /api/logout (best-effort), then clears local state + token.
  Future<void> logout() async {
    try {
      await _api.dio.post('/logout');
    } on DioException {
      // Ignore network errors on logout; we still clear local state.
    }
    await _storage.deleteToken();
    _token = null;
    _user = null;
    notifyListeners();
  }

  /// Restores a session from stored token by fetching GET /api/profile.
  /// Clears the token if it is no longer valid.
  Future<void> tryAutoLogin() async {
    final stored = await _storage.readToken();
    if (stored == null || stored.isEmpty) return;

    _token = stored;
    try {
      final res = await _api.dio.get('/profile');
      if (res.statusCode == 200 && res.data is Map) {
        final data = res.data as Map<String, dynamic>;
        _user = UserModel.fromJson(
          (data['user'] as Map).cast<String, dynamic>(),
        );
        notifyListeners();
        return;
      }
    } on DioException {
      // fall through to clearing the stale token
    }

    // Token invalid/expired: clear it.
    await _storage.deleteToken();
    _token = null;
    _user = null;
    notifyListeners();
  }

  /// Loads the campus geofence settings from GET /api/settings/location.
  /// The endpoint returns the FLAT settings object (not wrapped).
  Future<void> loadLocation() async {
    final res = await _api.dio.get('/settings/location');
    _location = SettingModel.fromJson((res.data as Map).cast<String, dynamic>());
    notifyListeners();
  }

  /// Updates the profile via multipart POST /api/profile (Laravel reads
  /// `_method=PUT`). On success replaces [user] with the returned model.
  Future<void> updateProfile({
    required String name,
    required String email,
    String? phone,
    String? photoPath,
  }) async {
    final form = FormData.fromMap({
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone, // ignore: use_null_aware_elements
      '_method': 'PUT',
      if (photoPath != null) 'photo': await MultipartFile.fromFile(photoPath),
    });
    final res = await _api.dio.post('/profile', data: form);
    _user = UserModel.fromJson(
      (res.data['user'] as Map).cast<String, dynamic>(),
    );
    notifyListeners();
  }

  String? _messageFrom(dynamic data) {
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return null;
  }
}
