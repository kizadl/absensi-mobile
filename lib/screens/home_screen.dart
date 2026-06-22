import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course_model.dart';
import '../providers/attendance_provider.dart';
import '../providers/course_provider.dart';
import '../services/api_client.dart';
import 'course_presensi_screen.dart';

/// Tombol pintar terisolasi — label & enable bergantung pada [state],
/// [windowAllowed] (flag server), dan [windowStartTime] (jam mulai dari setting).
/// Dipisah agar bisa diuji tanpa provider.
class SmartActionButton extends StatelessWidget {
  const SmartActionButton({
    super.key,
    required this.state,
    required this.loading,
    required this.onPressed,
    required this.windowAllowed,
    this.windowStartTime,
  });

  final AttendanceButtonState state;
  final bool loading;
  final VoidCallback? onPressed;

  /// true = server mengizinkan aksi sekarang (can_check_in / can_check_out).
  final bool windowAllowed;

  /// Jam mulai window ("HH:MM") dari SettingModel; null jika lokasi belum dimuat.
  final String? windowStartTime;

  String _label() {
    switch (state) {
      case AttendanceButtonState.canCheckIn:
        if (windowAllowed) return 'Catat Masuk';
        return windowStartTime != null
            ? 'Masuk mulai $windowStartTime'
            : 'Belum waktunya masuk';
      case AttendanceButtonState.canCheckOut:
        if (windowAllowed) return 'Catat Pulang';
        return windowStartTime != null
            ? 'Pulang mulai $windowStartTime'
            : 'Belum waktunya pulang';
      case AttendanceButtonState.done:
        return 'Presensi hari ini selesai';
    }
  }

  IconData _icon() {
    switch (state) {
      case AttendanceButtonState.canCheckIn:
        return Icons.login;
      case AttendanceButtonState.canCheckOut:
        return Icons.logout;
      case AttendanceButtonState.done:
        return Icons.check_circle;
    }
  }

  /// Tombol aktif hanya jika: bukan done, bukan loading, dan server mengizinkan.
  bool get _isEnabled =>
      state != AttendanceButtonState.done && !loading && windowAllowed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isEnabled ? onPressed : null,
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
              Icon(_icon()),
            const SizedBox(width: 8),
            Text(_label()),
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadCourses();
    });
  }

  Future<void> _refresh() => context.read<CourseProvider>().loadCourses();

  void _openCourse(CourseModel course) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (ctx) => AttendanceProvider(ctx.read<ApiClient>()),
          child: CoursePresensiScreen(course: course),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        title: const Text('Mata Kuliah'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Builder(
          builder: (context) {
            if (provider.isLoading && provider.courses.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.error != null && provider.courses.isEmpty) {
              return _CenterMessage(
                text: provider.error!,
                onRetry: _refresh,
              );
            }
            if (provider.courses.isEmpty) {
              return const _CenterMessage(text: 'Belum ada mata kuliah.');
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.courses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final c = provider.courses[i];
                return _CourseCard(
                  course: c,
                  onTap: () => _openCourse(c),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course, required this.onTap});

  final CourseModel course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      course.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _CourseStatusBadge(label: course.statusLabel),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                course.code,
                style: const TextStyle(
                    color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                course.lecturer,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge untuk home card: Belum absen / Hadir / Terlambat / Selesai.
class _CourseStatusBadge extends StatelessWidget {
  const _CourseStatusBadge({required this.label});

  final String label;

  Color get _color {
    switch (label) {
      case 'Hadir':
        return const Color(0xFF16A34A);
      case 'Terlambat':
        return const Color(0xFFDC2626);
      case 'Selesai':
        return const Color(0xFF2563EB);
      default: // Belum absen
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CenterMessage extends StatelessWidget {
  const _CenterMessage({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 140),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: onRetry,
                    child: const Text('Coba lagi'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
