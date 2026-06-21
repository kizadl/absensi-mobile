import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/setting_model.dart';
import '../providers/attendance_provider.dart';
import '../providers/auth_provider.dart';
import '../services/location_service.dart';

/// Tombol pintar terisolasi — label & enable bergantung pada [state].
/// Dipisah agar bisa diuji tanpa provider.
class SmartActionButton extends StatelessWidget {
  const SmartActionButton({
    super.key,
    required this.state,
    required this.loading,
    required this.onPressed,
  });

  final AttendanceButtonState state;
  final bool loading;
  final VoidCallback? onPressed;

  static String labelFor(AttendanceButtonState s) {
    switch (s) {
      case AttendanceButtonState.canCheckIn:
        return 'Catat Masuk';
      case AttendanceButtonState.canCheckOut:
        return 'Catat Pulang';
      case AttendanceButtonState.done:
        return 'Presensi hari ini selesai';
    }
  }

  static IconData iconFor(AttendanceButtonState s) {
    switch (s) {
      case AttendanceButtonState.canCheckIn:
        return Icons.login;
      case AttendanceButtonState.canCheckOut:
        return Icons.logout;
      case AttendanceButtonState.done:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone = state == AttendanceButtonState.done;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (isDone || loading) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade400,
          disabledForegroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            else
              Icon(iconFor(state)),
            const SizedBox(width: 8),
            Text(labelFor(state)),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _location = LocationService();
  late final Stream<DateTime> _clock;

  @override
  void initState() {
    super.initState();
    _clock = Stream<DateTime>.periodic(
        const Duration(seconds: 1), (_) => DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<AttendanceProvider>().loadToday();
      auth.loadLocation();
    });
  }

  Future<void> _runPunchFlow() async {
    final messenger = ScaffoldMessenger.of(context);
    final attendance = context.read<AttendanceProvider>();
    final auth = context.read<AuthProvider>();
    final SettingModel? setting = auth.location;

    if (setting == null) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Data lokasi kampus belum dimuat. Coba lagi.')));
      return;
    }

    try {
      final pos = await _location.getCurrentPosition();
      final distance = _location.distanceMeters(
        pos.latitude,
        pos.longitude,
        setting.campusLat,
        setting.campusLng,
      );

      if (distance > setting.radiusMeters) {
        messenger.showSnackBar(SnackBar(
          backgroundColor: Colors.red.shade600,
          content: Text('Anda di luar area kampus (${distance.round()} m)'),
        ));
        return;
      }

      // Dalam radius → reverse-geocode alamat untuk dikirim ke server
      // (disimpan sebagai check_in_address / check_out_address).
      final address =
          await _location.addressFromLatLng(pos.latitude, pos.longitude);

      final state = attendance.buttonState;
      if (state == AttendanceButtonState.canCheckIn) {
        await attendance.checkIn(
            lat: pos.latitude, lng: pos.longitude, address: address);
        messenger.showSnackBar(const SnackBar(
            backgroundColor: Color(0xFF16A34A),
            content: Text('Presensi masuk tercatat.')));
      } else if (state == AttendanceButtonState.canCheckOut) {
        await attendance.checkOut(
            lat: pos.latitude, lng: pos.longitude, address: address);
        messenger.showSnackBar(const SnackBar(
            backgroundColor: Color(0xFF16A34A),
            content: Text('Presensi pulang tercatat.')));
      }
    } on LocationException catch (e) {
      messenger.showSnackBar(SnackBar(
          backgroundColor: Colors.red.shade600, content: Text(e.message)));
    } on AttendanceApiException catch (e) {
      messenger.showSnackBar(SnackBar(
          backgroundColor: Colors.red.shade600, content: Text(e.message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          backgroundColor: Colors.red.shade600,
          content: Text('Gagal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final attendance = context.watch<AttendanceProvider>();
    final name = auth.user?.name ?? 'Mahasiswa';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BlueHeader(name: name, clock: _clock),
            const SizedBox(height: 24),
            // Affordance "coba lagi" saat setting lokasi gagal dimuat atau
            // status presensi hari ini gagal di-load.
            if (auth.location == null || attendance.error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: _InlineError(
                  message: attendance.error ??
                      'Data lokasi kampus belum dimuat.',
                  onRetry: () {
                    if (auth.location == null) auth.loadLocation();
                    if (attendance.error != null) attendance.loadToday();
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Presensi Hari Ini',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(
                        _statusText(attendance),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 18),
                      SmartActionButton(
                        state: attendance.buttonState,
                        loading: attendance.isLoading,
                        onPressed: _runPunchFlow,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusText(AttendanceProvider a) {
    switch (a.buttonState) {
      case AttendanceButtonState.canCheckIn:
        return 'Anda belum melakukan presensi masuk.';
      case AttendanceButtonState.canCheckOut:
        return 'Sudah masuk. Jangan lupa catat pulang.';
      case AttendanceButtonState.done:
        return 'Presensi masuk & pulang sudah tercatat.';
    }
  }
}

class _BlueHeader extends StatelessWidget {
  const _BlueHeader({required this.name, required this.clock});

  final String name;
  final Stream<DateTime> clock;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: const BoxDecoration(
        color: Color(0xFF2563EB),
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Selamat datang,',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          StreamBuilder<DateTime>(
            stream: clock,
            builder: (context, snapshot) {
              final now = snapshot.data ?? DateTime.now();
              final jam = DateFormat('HH:mm:ss', 'id_ID').format(now);
              final tanggal =
                  DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(jam,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2)),
                  const SizedBox(height: 4),
                  Text(tanggal,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Bagian error inline dengan tombol "Coba lagi" — tampil saat setting lokasi
/// gagal dimuat atau status presensi hari ini gagal di-load.
class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB91C1C), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: Color(0xFFB91C1C))),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Coba lagi',
                style: TextStyle(
                    color: Color(0xFFB91C1C), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
