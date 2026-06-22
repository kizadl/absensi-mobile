import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:epresensi/models/course_model.dart';
import 'package:epresensi/providers/course_provider.dart';
import 'package:epresensi/screens/home_screen.dart';

class MockCourseProvider extends Mock implements CourseProvider {}

CourseModel _course({
  required int id,
  required String name,
  required String code,
  required String lecturer,
  Map<String, dynamic>? today,
}) =>
    CourseModel.fromJson({
      'id': id,
      'name': name,
      'code': code,
      'lecturer': lecturer,
      'check_in_start': '07:00',
      'late_after': '07:15',
      'check_out_start': '15:00',
      'today': ?today,
    });

Widget _wrap(MockCourseProvider provider) =>
    ChangeNotifierProvider<CourseProvider>.value(
      value: provider,
      child: const MaterialApp(home: HomeScreen()),
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  late MockCourseProvider provider;

  setUp(() {
    provider = MockCourseProvider();
    when(() => provider.isLoading).thenReturn(false);
    when(() => provider.error).thenReturn(null);
    when(() => provider.courses).thenReturn(const []);
    when(() => provider.loadCourses()).thenAnswer((_) async {});
    when(() => provider.addListener(any())).thenReturn(null);
    when(() => provider.removeListener(any())).thenReturn(null);
  });

  testWidgets('renders a card per course with name, code, lecturer',
      (tester) async {
    when(() => provider.courses).thenReturn([
      _course(id: 1, name: 'Pemrograman Web', code: 'IF301', lecturer: 'Dr. Budi'),
      _course(id: 2, name: 'Basis Data', code: 'IF302', lecturer: 'Dr. Sari'),
    ]);

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.text('Pemrograman Web'), findsOneWidget);
    expect(find.text('Basis Data'), findsOneWidget);
    expect(find.text('IF301'), findsOneWidget);
    expect(find.text('Dr. Sari'), findsOneWidget);
  });

  testWidgets('renders the today status badge per card', (tester) async {
    when(() => provider.courses).thenReturn([
      _course(
        id: 1,
        name: 'Pemrograman Web',
        code: 'IF301',
        lecturer: 'Dr. Budi',
        today: const {
          'has_check_in': true,
          'has_check_out': false,
          'can_check_in': false,
          'can_check_out': true,
          'attendance': {
            'id': 1,
            'date': '2026-06-22',
            'check_in_at': '2026-06-22 07:20:00',
            'check_in_status': 'terlambat',
          },
        },
      ),
      _course(id: 2, name: 'Basis Data', code: 'IF302', lecturer: 'Dr. Sari'),
    ]);

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.text('Terlambat'), findsOneWidget);
    expect(find.text('Belum absen'), findsOneWidget);
  });

  testWidgets('empty courses shows empty message', (tester) async {
    await tester.pumpWidget(_wrap(provider));
    await tester.pump();
    expect(find.text('Belum ada mata kuliah.'), findsOneWidget);
  });

  testWidgets('error shows message + retry', (tester) async {
    when(() => provider.error).thenReturn('Gagal memuat daftar mata kuliah.');
    await tester.pumpWidget(_wrap(provider));
    await tester.pump();
    expect(find.text('Gagal memuat daftar mata kuliah.'), findsOneWidget);
  });

  testWidgets('calls loadCourses on init', (tester) async {
    await tester.pumpWidget(_wrap(provider));
    await tester.pump();
    verify(() => provider.loadCourses()).called(1);
  });
}
