/// Application-wide environment configuration.
///
/// Production (default): aplikasi terhubung ke backend yang di-hosting.
///   https://e-presensi.dzakinetic.site/api
///
/// Untuk development lokal, ganti `baseUrl` sesuai cara perangkat terhubung:
///   - Emulator Android        : http://10.0.2.2:8000/api
///   - HP fisik via USB        : http://127.0.0.1:8000/api  (jalankan: adb reverse tcp:8000 tcp:8000)
///   - HP fisik se-WiFi dgn PC : http://<IP-LAN-PC>:8000/api (server: php artisan serve --host=0.0.0.0)
class Env {
  Env._();

  /// Base URL for the Laravel API (Sanctum). Includes the `/api` prefix.
  static const String baseUrl = 'https://e-presensi.dzakinetic.site/api';
}
