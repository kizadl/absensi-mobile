import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:epresensi/models/attendance_model.dart';
import 'package:epresensi/providers/attendance_provider.dart';
import 'package:epresensi/screens/history_screen.dart';

// ---------------------------------------------------------------------------
// Mock
// ---------------------------------------------------------------------------

class MockAttendanceProvider extends Mock implements AttendanceProvider {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _wrap(AttendanceProvider provider) {
  return ChangeNotifierProvider<AttendanceProvider>.value(
    value: provider,
    child: const MaterialApp(home: HistoryScreen()),
  );
}

AttendanceModel _makeRecord({
  int id = 1,
  required DateTime date,
  DateTime? checkInAt,
  String? checkInStatus,
  DateTime? checkOutAt,
  AttendanceCourse? course,
}) {
  return AttendanceModel(
    id: id,
    date: date,
    checkInAt: checkInAt,
    checkInStatus: checkInStatus,
    checkOutAt: checkOutAt,
    course: course,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  late MockAttendanceProvider mockProvider;

  setUp(() {
    mockProvider = MockAttendanceProvider();
    // Default stubs
    when(() => mockProvider.isLoading).thenReturn(false);
    when(() => mockProvider.error).thenReturn(null);
    when(() => mockProvider.history).thenReturn(const []);
    when(() => mockProvider.loadHistory(any())).thenAnswer((_) async {});
    // addListener / removeListener wajib untuk ChangeNotifierProvider.value
    when(() => mockProvider.addListener(any())).thenReturn(null);
    when(() => mockProvider.removeListener(any())).thenReturn(null);
  });

  group('HistoryScreen — empty state', () {
    testWidgets('menampilkan pesan kosong saat history empty', (tester) async {
      await tester.pumpWidget(_wrap(mockProvider));
      await tester.pump(); // post-frame callback

      expect(
        find.text('Belum ada presensi di bulan ini.'),
        findsOneWidget,
      );
    });
  });

  group('HistoryScreen — loading state', () {
    testWidgets('menampilkan CircularProgressIndicator saat isLoading',
        (tester) async {
      when(() => mockProvider.isLoading).thenReturn(true);

      await tester.pumpWidget(_wrap(mockProvider));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('HistoryScreen — error state', () {
    testWidgets('menampilkan pesan error saat provider.error != null',
        (tester) async {
      when(() => mockProvider.error).thenReturn('Gagal memuat data');

      await tester.pumpWidget(_wrap(mockProvider));
      await tester.pump();

      expect(find.text('Gagal memuat data'), findsOneWidget);
    });
  });

  group('HistoryScreen — daftar presensi', () {
    testWidgets('merender tanggal dan badge Terlambat', (tester) async {
      final records = [
        _makeRecord(
          id: 1,
          date: DateTime(2025, 6, 10),
          checkInAt: DateTime(2025, 6, 10, 8, 30),
          checkInStatus: 'terlambat',
          checkOutAt: DateTime(2025, 6, 10, 17, 0),
        ),
      ];
      when(() => mockProvider.history).thenReturn(records);

      await tester.pumpWidget(_wrap(mockProvider));
      await tester.pump();

      // Badge status terlambat harus muncul
      expect(find.text('Terlambat'), findsOneWidget);
      // Waktu masuk dalam format HH:mm
      expect(find.text('08:30'), findsOneWidget);
    });

    testWidgets('merender badge Tepat Waktu', (tester) async {
      final records = [
        _makeRecord(
          id: 2,
          date: DateTime(2025, 6, 9),
          checkInAt: DateTime(2025, 6, 9, 7, 45),
          checkInStatus: 'tepat_waktu',
        ),
      ];
      when(() => mockProvider.history).thenReturn(records);

      await tester.pumpWidget(_wrap(mockProvider));
      await tester.pump();

      expect(find.text('Tepat Waktu'), findsOneWidget);
      expect(find.text('07:45'), findsOneWidget);
    });

    testWidgets('null checkOut merender "--:--" untuk pulang', (tester) async {
      final records = [
        _makeRecord(
          id: 3,
          date: DateTime(2025, 6, 8),
          checkInAt: DateTime(2025, 6, 8, 8, 0),
          checkInStatus: 'tepat_waktu',
          checkOutAt: null, // belum pulang
        ),
      ];
      when(() => mockProvider.history).thenReturn(records);

      await tester.pumpWidget(_wrap(mockProvider));
      await tester.pump();

      expect(find.text('--:--'), findsOneWidget);
    });

    testWidgets('memanggil loadHistory saat init', (tester) async {
      await tester.pumpWidget(_wrap(mockProvider));
      await tester.pump();

      verify(() => mockProvider.loadHistory(any())).called(1);
    });

    testWidgets('merender nama matkul per baris', (tester) async {
      final records = [
        _makeRecord(
          id: 1,
          date: DateTime(2025, 6, 10),
          checkInAt: DateTime(2025, 6, 10, 8, 30),
          checkInStatus: 'tepat_waktu',
          course: const AttendanceCourse(
              id: 3, name: 'Basis Data', code: 'IF302'),
        ),
      ];
      when(() => mockProvider.history).thenReturn(records);

      await tester.pumpWidget(_wrap(mockProvider));
      await tester.pump();

      expect(find.text('Basis Data'), findsOneWidget);
    });
  });
}
