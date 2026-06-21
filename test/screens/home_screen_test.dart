import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epresensi/providers/attendance_provider.dart';
import 'package:epresensi/screens/home_screen.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('SmartActionButton label per state', () {
    testWidgets('canCheckIn → "Catat Masuk" dan aktif', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(SmartActionButton(
        state: AttendanceButtonState.canCheckIn,
        loading: false,
        onPressed: () => tapped = true,
      )));

      expect(find.text('Catat Masuk'), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, isTrue);
    });

    testWidgets('canCheckOut → "Catat Pulang"', (tester) async {
      await tester.pumpWidget(_wrap(const SmartActionButton(
        state: AttendanceButtonState.canCheckOut,
        loading: false,
        onPressed: null,
      )));
      expect(find.text('Catat Pulang'), findsOneWidget);
    });

    testWidgets('done → "Presensi hari ini selesai" dan tombol disabled',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(SmartActionButton(
        state: AttendanceButtonState.done,
        loading: false,
        onPressed: () => tapped = true,
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
      )));
      final btn =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(btn.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
