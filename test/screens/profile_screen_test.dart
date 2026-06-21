import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:epresensi/config/app_theme.dart';
import 'package:epresensi/models/user_model.dart';
import 'package:epresensi/providers/auth_provider.dart';
import 'package:epresensi/screens/profile_screen.dart';

// ── Mocktail mock ──────────────────────────────────────────────────────────────
class MockAuthProvider extends Mock implements AuthProvider {}

// ── Helpers ────────────────────────────────────────────────────────────────────
const _testUser = UserModel(
  id: 1,
  role: 'mahasiswa',
  name: 'Budi Santoso',
  username: 'budi',
  email: 'budi@kampus.ac.id',
  phone: '081234567890',
);

Widget _wrap(MockAuthProvider provider) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: provider,
    child: MaterialApp(
      theme: AppTheme.light,
      home: const ProfileScreen(),
    ),
  );
}

void main() {
  late MockAuthProvider auth;

  setUp(() {
    auth = MockAuthProvider();

    // Default stubs
    when(() => auth.user).thenReturn(_testUser);
    when(() => auth.updateProfile(
          name: any(named: 'name'),
          email: any(named: 'email'),
          phone: any(named: 'phone'),
          photoPath: any(named: 'photoPath'),
        )).thenAnswer((_) async {});
    when(() => auth.logout()).thenAnswer((_) async {});
  });

  // ── 1. Pre-fill fields ───────────────────────────────────────────────────────
  testWidgets('fields are pre-filled from AuthProvider.user', (tester) async {
    await tester.pumpWidget(_wrap(auth));
    await tester.pump();

    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('budi@kampus.ac.id'), findsOneWidget);
    expect(find.text('081234567890'), findsOneWidget);
  });

  // ── 2. Simpan button calls updateProfile ────────────────────────────────────
  testWidgets('tapping Simpan Perubahan calls updateProfile with field values',
      (tester) async {
    await tester.pumpWidget(_wrap(auth));
    await tester.pump();

    // Change the name
    final nameField = find.widgetWithText(TextFormField, 'Nama Lengkap');
    await tester.ensureVisible(nameField);
    await tester.tap(nameField);
    await tester.pump();
    await tester.enterText(nameField, 'Budi Diubah');

    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pump();

    verify(() => auth.updateProfile(
          name: 'Budi Diubah',
          email: 'budi@kampus.ac.id',
          phone: '081234567890',
          photoPath: null,
        )).called(1);
  });

  // ── 3. Logout button calls logout ───────────────────────────────────────────
  testWidgets('tapping Keluar shows dialog then calls logout on confirm',
      (tester) async {
    await tester.pumpWidget(_wrap(auth));
    await tester.pump();

    // Scroll to make the Keluar button visible then tap it
    final keluarButton = find.widgetWithText(OutlinedButton, 'Keluar');
    await tester.ensureVisible(keluarButton);
    await tester.tap(keluarButton);
    await tester.pumpAndSettle();

    // Confirm dialog appears
    expect(find.text('Yakin ingin keluar dari akun?'), findsOneWidget);

    // Tap the confirm button in the dialog
    await tester.tap(find.widgetWithText(TextButton, 'Keluar').last);
    await tester.pumpAndSettle();

    verify(() => auth.logout()).called(1);
  });
}
