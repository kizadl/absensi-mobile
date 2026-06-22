import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'providers/attendance_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/course_provider.dart';
import 'services/api_client.dart';
import 'screens/login_screen.dart';
import 'screens/main_scaffold.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const EPresensiApp());
}

class EPresensiApp extends StatelessWidget {
  const EPresensiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Shared ApiClient (single Dio + Bearer interceptor). Providers below
        // read it via ctx.read<ApiClient>() so there is exactly one instance.
        Provider<ApiClient>(create: (_) => ApiClient()),
        ChangeNotifierProvider(
          create: (ctx) => AuthProvider(apiClient: ctx.read<ApiClient>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => AttendanceProvider(ctx.read<ApiClient>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => CourseProvider(ctx.read<ApiClient>()),
        ),
      ],
      child: MaterialApp(
        title: 'E-Presensi',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _AuthGate(),
      ),
    );
  }
}

/// Runs tryAutoLogin once, shows a splash while resolving, then routes
/// to MainScaffold (authenticated) or LoginScreen.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late final Future<void> _bootstrap;

  @override
  void initState() {
    super.initState();
    _bootstrap = context.read<AuthProvider>().tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrap,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final auth = context.watch<AuthProvider>();
        return auth.isAuthenticated
            ? const MainScaffold()
            : const LoginScreen();
      },
    );
  }
}
