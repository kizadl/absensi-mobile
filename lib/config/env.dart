/// Application-wide environment configuration.
///
/// Dev setup reaches the Laravel API on the host PC via USB:
///   adb reverse tcp:8000 tcp:8000
/// which maps the device's localhost:8000 to the PC's localhost:8000.
/// (For the Android emulator without adb reverse, use http://10.0.2.2:8000/api.)
class Env {
  Env._();

  /// Base URL for the Laravel API (Sanctum). Includes the `/api` prefix.
  static const String baseUrl = 'http://127.0.0.1:8000/api';
}
