import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:epresensi/models/setting_model.dart';
import 'package:epresensi/models/user_model.dart';
import 'package:epresensi/providers/attendance_provider.dart';
import 'package:epresensi/providers/auth_provider.dart';
import 'package:epresensi/screens/home_screen.dart';
import 'package:epresensi/services/api_client.dart';

/// AuthProvider stub: user tetap + loadLocation/no-op (tanpa HTTP).
class FakeAuthProvider extends AuthProvider {
  FakeAuthProvider({UserModel? user, SettingModel? location})
      : _fakeUser = user,
        _fakeLocation = location,
        super(apiClient: ApiClient());

  final UserModel? _fakeUser;
  final SettingModel? _fakeLocation;

  @override
  UserModel? get user => _fakeUser;

  @override
  SettingModel? get location => _fakeLocation;

  @override
  Future<void> loadLocation() async {} // no-op: lokasi sudah di-set
}

/// AttendanceProvider stub: state tombol bisa diatur; loadToday no-op.
class FakeAttendanceProvider extends AttendanceProvider {
  FakeAttendanceProvider({
    this.fakeHasCheckIn = false,
    this.fakeHasCheckOut = false,
  }) : super(ApiClient());

  final bool fakeHasCheckIn;
  final bool fakeHasCheckOut;

  @override
  bool get hasCheckIn => fakeHasCheckIn;
  @override
  bool get hasCheckOut => fakeHasCheckOut;
  @override
  bool get isLoading => false;
  @override
  String? get error => null;
  // buttonState menggunakan private field _hasCheckIn/_hasCheckOut, bukan getter,
  // jadi override langsung di sini agar stub bekerja benar.
  @override
  AttendanceButtonState get buttonState => deriveButtonState(
        hasCheckIn: fakeHasCheckIn,
        hasCheckOut: fakeHasCheckOut,
      );
  @override
  Future<void> loadToday() async {} // no-op: tanpa HTTP
}

Widget _wrap({
  required FakeAuthProvider auth,
  required FakeAttendanceProvider attendance,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider<AttendanceProvider>.value(value: attendance),
    ],
    child: const MaterialApp(home: HomeScreen()),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  const user = UserModel(
    id: 7,
    role: 'mahasiswa',
    name: 'Adit Saputra',
    username: 'adit',
    email: 'adit@example.com',
  );

  const setting = SettingModel(
    campusName: 'Kampus A',
    campusLat: -6.2,
    campusLng: 106.8,
    radiusMeters: 100,
    checkInStart: '07:00',
    lateAfter: '08:00',
    checkOutStart: '15:00',
    timezone: 'Asia/Jakarta',
  );

  testWidgets('menampilkan nama sapaan & label "Catat Masuk" saat canCheckIn',
      (tester) async {
    await tester.pumpWidget(_wrap(
      auth: FakeAuthProvider(user: user, location: setting),
      attendance: FakeAttendanceProvider(
        fakeHasCheckIn: false,
        fakeHasCheckOut: false,
      ),
    ));
    await tester.pump(); // selesaikan post-frame callback

    expect(find.text('Adit Saputra'), findsOneWidget);
    expect(find.text('Catat Masuk'), findsOneWidget);
  });

  testWidgets('label "Catat Pulang" saat sudah check-in', (tester) async {
    await tester.pumpWidget(_wrap(
      auth: FakeAuthProvider(user: user, location: setting),
      attendance: FakeAttendanceProvider(
        fakeHasCheckIn: true,
        fakeHasCheckOut: false,
      ),
    ));
    await tester.pump();

    expect(find.text('Catat Pulang'), findsOneWidget);
  });
}
