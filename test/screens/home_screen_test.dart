import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epresensi/providers/attendance_provider.dart';
import 'package:epresensi/screens/home_screen.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('SmartActionButton label per state', () {
    testWidgets('canCheckIn + windowAllowed → "Catat Masuk" dan aktif',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(SmartActionButton(
        state: AttendanceButtonState.canCheckIn,
        loading: false,
        onPressed: () => tapped = true,
        windowAllowed: true,
        windowStartTime: '07:00',
      )));

      expect(find.text('Catat Masuk'), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, isTrue);
    });

    testWidgets(
        'canCheckIn + windowAllowed==false → "Masuk mulai 07:00" dan disabled',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(SmartActionButton(
        state: AttendanceButtonState.canCheckIn,
        loading: false,
        onPressed: () => tapped = true,
        windowAllowed: false,
        windowStartTime: '07:00',
      )));

      expect(find.text('Masuk mulai 07:00'), findsOneWidget);
      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(btn.onPressed, isNull);
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      expect(tapped, isFalse);
    });

    testWidgets(
        'canCheckIn + windowAllowed==false + windowStartTime null → '
        '"Belum waktunya masuk" dan disabled',
        (tester) async {
      await tester.pumpWidget(_wrap(const SmartActionButton(
        state: AttendanceButtonState.canCheckIn,
        loading: false,
        onPressed: null,
        windowAllowed: false,
        windowStartTime: null,
      )));

      expect(find.text('Belum waktunya masuk'), findsOneWidget);
      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(btn.onPressed, isNull);
    });

    testWidgets('canCheckOut + windowAllowed → "Catat Pulang" dan aktif',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(SmartActionButton(
        state: AttendanceButtonState.canCheckOut,
        loading: false,
        onPressed: () => tapped = true,
        windowAllowed: true,
        windowStartTime: '15:00',
      )));

      expect(find.text('Catat Pulang'), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, isTrue);
    });

    testWidgets(
        'canCheckOut + windowAllowed==false → "Pulang mulai 15:00" dan disabled',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(SmartActionButton(
        state: AttendanceButtonState.canCheckOut,
        loading: false,
        onPressed: () => tapped = true,
        windowAllowed: false,
        windowStartTime: '15:00',
      )));

      expect(find.text('Pulang mulai 15:00'), findsOneWidget);
      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(btn.onPressed, isNull);
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      expect(tapped, isFalse);
    });

    testWidgets(
        'canCheckOut + windowAllowed==false + windowStartTime null → '
        '"Belum waktunya pulang" dan disabled',
        (tester) async {
      await tester.pumpWidget(_wrap(const SmartActionButton(
        state: AttendanceButtonState.canCheckOut,
        loading: false,
        onPressed: null,
        windowAllowed: false,
        windowStartTime: null,
      )));

      expect(find.text('Belum waktunya pulang'), findsOneWidget);
      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(btn.onPressed, isNull);
    });

    testWidgets('done → "Presensi hari ini selesai" dan tombol disabled',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(SmartActionButton(
        state: AttendanceButtonState.done,
        loading: false,
        onPressed: () => tapped = true,
        windowAllowed: true, // done selalu disabled meski windowAllowed true
        windowStartTime: null,
      )));

      expect(find.text('Presensi hari ini selesai'), findsOneWidget);
      final btn =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(btn.onPressed, isNull); // disabled
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      expect(tapped, isFalse);
    });

    testWidgets('loading → tombol non-aktif walau bisa check-in',
        (tester) async {
      await tester.pumpWidget(_wrap(SmartActionButton(
        state: AttendanceButtonState.canCheckIn,
        loading: true,
        onPressed: () {},
        windowAllowed: true,
        windowStartTime: '07:00',
      )));
      final btn =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(btn.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
