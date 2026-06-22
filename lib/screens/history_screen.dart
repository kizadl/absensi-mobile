import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/attendance_model.dart';
import '../providers/attendance_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  String get _monthParam => DateFormat('yyyy-MM').format(_month);

  Future<void> _reload() =>
      context.read<AttendanceProvider>().loadHistory(_monthParam);

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2024, 1),
      lastDate: DateTime(DateTime.now().year + 1, 12),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Pilih bulan',
    );
    if (picked != null) {
      setState(() => _month = DateTime(picked.year, picked.month));
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final monthLabel = DateFormat('MMMM yyyy', 'id_ID').format(_month);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        title: const Text('Histori Presensi'),
        actions: [
          TextButton.icon(
            onPressed: _pickMonth,
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            label: Text(
              monthLabel,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: Builder(
          builder: (context) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.error != null) {
              return _CenterMessage(text: provider.error!);
            }
            if (provider.history.isEmpty) {
              return const _CenterMessage(
                text: 'Belum ada presensi di bulan ini.',
              );
            }
            final items = [...provider.history]
              ..sort((a, b) => b.date.compareTo(a.date));
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _HistoryCard(item: items[i]),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _HistoryCard
// ---------------------------------------------------------------------------

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});

  final AttendanceModel item;

  @override
  Widget build(BuildContext context) {
    final tanggal =
        DateFormat('EEEE, d MMM yyyy', 'id_ID').format(item.date);
    final masuk = item.checkInAt != null
        ? DateFormat('HH:mm').format(item.checkInAt!)
        : '--:--';
    final pulang = item.checkOutAt != null
        ? DateFormat('HH:mm').format(item.checkOutAt!)
        : '--:--';

    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.course != null) ...[
              Text(
                item.course!.name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
              ),
              const SizedBox(height: 4),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    tanggal,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                _StatusBadge(status: item.checkInStatus),
              ],
            ),
            const Divider(height: 18),
            Row(
              children: [
                Expanded(child: _TimeBox(label: 'Masuk', value: masuk)),
                Expanded(child: _TimeBox(label: 'Pulang', value: pulang)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _TimeBox
// ---------------------------------------------------------------------------

class _TimeBox extends StatelessWidget {
  const _TimeBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _StatusBadge
// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  /// 'tepat_waktu' | 'terlambat' | null
  final String? status;

  @override
  Widget build(BuildContext context) {
    final isLate = status == 'terlambat';
    final hasStatus = status != null;
    final text = !hasStatus
        ? 'Belum Absen'
        : (isLate ? 'Terlambat' : 'Tepat Waktu');
    final color = !hasStatus
        ? Colors.grey
        : (isLate ? const Color(0xFFDC2626) : const Color(0xFF16A34A));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CenterMessage
// ---------------------------------------------------------------------------

class _CenterMessage extends StatelessWidget {
  const _CenterMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
      ],
    );
  }
}
