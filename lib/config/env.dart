/// Application-wide environment configuration.
///
/// For the Android emulator, the host machine is reachable at 10.0.2.2.
/// When testing on a physical device, replace with the host LAN IP.
class Env {
  Env._();

  /// Base URL for the Laravel API (Sanctum). Includes the `/api` prefix.
  static const String baseUrl = 'http://10.0.2.2:8000/api';
}
