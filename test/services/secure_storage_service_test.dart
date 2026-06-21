import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:epresensi/services/secure_storage_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  const tokenKey = 'auth_token';
  late MockFlutterSecureStorage storage;
  late SecureStorageService service;

  setUp(() {
    storage = MockFlutterSecureStorage();
    service = SecureStorageService(storage: storage);
  });

  test('saveToken writes the token under the auth_token key', () async {
    when(
      () => storage.write(key: any(named: 'key'), value: any(named: 'value')),
    ).thenAnswer((_) async {});

    await service.saveToken('abc123');

    verify(() => storage.write(key: tokenKey, value: 'abc123')).called(1);
  });

  test('readToken returns the stored token', () async {
    when(() => storage.read(key: tokenKey)).thenAnswer((_) async => 'abc123');

    final result = await service.readToken();

    expect(result, 'abc123');
    verify(() => storage.read(key: tokenKey)).called(1);
  });

  test('readToken returns null when nothing stored', () async {
    when(() => storage.read(key: tokenKey)).thenAnswer((_) async => null);

    final result = await service.readToken();

    expect(result, isNull);
  });

  test('deleteToken removes the token key', () async {
    when(
      () => storage.delete(key: any(named: 'key')),
    ).thenAnswer((_) async {});

    await service.deleteToken();

    verify(() => storage.delete(key: tokenKey)).called(1);
  });
}
