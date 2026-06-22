import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:epresensi/models/course_model.dart';
import 'package:epresensi/models/setting_model.dart';
import 'package:epresensi/providers/attendance_provider.dart';
import 'package:epresensi/providers/auth_provider.dart';
import 'package:epresensi/screens/course_presensi_screen.dart';

class MockAttendanceProvider extends Mock implements AttendanceProvider {}

class MockAuthProvider extends Mock implements AuthProvider {}

const _course = CourseModel(
  id: 5,
  name: 'Pemrograman Web',
  code: 'IF301',
  lecturer: 'Dr. Budi',
  checkInStart: '07:00',
  lateAfter: '07:15',
  checkOutStart: '15:00',
);

const _setting = SettingModel(
  campusName: 'Kampus A',
  campusLat: -6.2,
  campusLng: 106.816666,
  radiusMeters: 100,
  timezone: 'Asia/Jakarta',
);

Widget _wrap(
  MockAttendanceProvider att,
  MockAuthProvider auth,
) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AttendanceProvider>.value(value: att),
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
    ],
    child: const MaterialApp(home: CoursePresensiScreen(course: _course)),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  late MockAttendanceProvider att;
  late MockAuthProvider auth;

  setUp(() {
    att = MockAttendanceProvider();
    auth = MockAuthProvider();
    when(() => att.isLoading).thenReturn(false);
    when(() => att.error).thenReturn(null);
    when(() => att.hasCheckIn).thenReturn(false);
    when(() => att.hasCheckOut).thenReturn(false);
    when(() => att.canCheckIn).thenReturn(true);
    when(() => att.canCheckOut).thenReturn(false);
    when(() => att.buttonState).thenReturn(AttendanceButtonState.canCheckIn);
    when(() => att.loadToday(any())).thenAnswer((_) async {});
    when(() => att.addListener(any())).thenReturn(null);
    when(() => att.removeListener(any())).thenReturn(null);
    when(() => auth.location).thenReturn(_setting);
    when(() => auth.addListener(any())).thenReturn(null);
    when(() => auth.removeListener(any())).thenReturn(null);
  });

  testWidgets('renders course name + "Catat Masuk" when window allowed',
      (tester) async {
    await tester.pumpWidget(_wrap(att, auth));
    await tester.pump();

    expect(find.text('Pemrograman Web'), findsWidgets);
    expect(find.text('Catat Masuk'), findsOneWidget);
  });

  testWidgets('canCheckIn but window not allowed → "Masuk mulai 07:00"',
      (tester) async {
    when(() => att.canCheckIn).thenReturn(false);
    await tester.pumpWidget(_wrap(att, auth));
    await tester.pump();

    expect(find.text('Masuk mulai 07:00'), findsOneWidget);
  });

  testWidgets('canCheckOut + window allowed → "Catat Pulang"', (tester) async {
    when(() => att.buttonState).thenReturn(AttendanceButtonState.canCheckOut);
    when(() => att.hasCheckIn).thenReturn(true);
    when(() => att.canCheckIn).thenReturn(false);
    when(() => att.canCheckOut).thenReturn(true);
    await tester.pumpWidget(_wrap(att, auth));
    await tester.pump();

    expect(find.text('Catat Pulang'), findsOneWidget);
  });

  testWidgets('done → "Presensi hari ini selesai" disabled', (tester) async {
    when(() => att.buttonState).thenReturn(AttendanceButtonState.done);
    when(() => att.hasCheckIn).thenReturn(true);
    when(() => att.hasCheckOut).thenReturn(true);
    when(() => att.canCheckIn).thenReturn(false);
    when(() => att.canCheckOut).thenReturn(false);
    await tester.pumpWidget(_wrap(att, auth));
    await tester.pump();

    expect(find.text('Presensi hari ini selesai'), findsOneWidget);
    final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(btn.onPressed, isNull);
  });

  testWidgets('calls loadToday(course.id) on init', (tester) async {
    await tester.pumpWidget(_wrap(att, auth));
    await tester.pump();
    verify(() => att.loadToday(5)).called(1);
  });
}
