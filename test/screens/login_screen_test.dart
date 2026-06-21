import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:epresensi/config/app_theme.dart';
import 'package:epresensi/providers/auth_provider.dart';
import 'package:epresensi/services/api_client.dart';
import 'package:epresensi/screens/login_screen.dart';

/// Fake provider so the widget test never hits the network.
/// AuthProvider now requires an ApiClient; we pass a real (unused) one —
/// the overridden [login] never touches it.
class FakeAuthProvider extends AuthProvider {
  FakeAuthProvider({this.succeed = true})
      : super(apiClient: ApiClient());

  final bool succeed;
  String? lastUsername;
  String? lastPassword;
  String? _fakeError;

  @override
  String? get error => _fakeError;

  @override
  Future<bool> login(String username, String password) async {
    lastUsername = username;
    lastPassword = password;
    if (!succeed) {
      _fakeError = 'Username atau password salah.';
      notifyListeners();
      return false;
    }
    return true;
  }
}

Widget _wrap(AuthProvider provider) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: provider,
    child: MaterialApp(
      theme: AppTheme.light,
      home: const LoginScreen(),
    ),
  );
}

void main() {
  testWidgets('renders username, password fields and login button',
      (tester) async {
    await tester.pumpWidget(_wrap(FakeAuthProvider()));

    expect(find.byKey(const Key('login_username')), findsOneWidget);
    expect(find.byKey(const Key('login_password')), findsOneWidget);
    expect(find.byKey(const Key('login_submit')), findsOneWidget);
    expect(find.text('Masuk'), findsWidgets);
  });

  testWidgets('shows validation errors when fields are empty',
      (tester) async {
    await tester.pumpWidget(_wrap(FakeAuthProvider()));

    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();

    expect(find.text('Username wajib diisi'), findsOneWidget);
    expect(find.text('Password wajib diisi'), findsOneWidget);
  });

  testWidgets('calls AuthProvider.login with entered credentials',
      (tester) async {
    final provider = FakeAuthProvider();
    await tester.pumpWidget(_wrap(provider));

    await tester.enterText(
        find.byKey(const Key('login_username')), 'adit');
    await tester.enterText(
        find.byKey(const Key('login_password')), 'secret123');
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();

    expect(provider.lastUsername, 'adit');
    expect(provider.lastPassword, 'secret123');
  });

  testWidgets('displays the provider error message on failed login',
      (tester) async {
    final provider = FakeAuthProvider(succeed: false);
    await tester.pumpWidget(_wrap(provider));

    await tester.enterText(
        find.byKey(const Key('login_username')), 'adit');
    await tester.enterText(
        find.byKey(const Key('login_password')), 'wrong');
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();

    expect(find.text('Username atau password salah.'), findsOneWidget);
  });
}
