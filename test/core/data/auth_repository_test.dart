import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/auth_repository.dart';

void main() {
  group('AuthRepository interface', () {
    test('can be implemented by a mock', () {
      final mock = _MockAuthRepository();
      expect(mock, isA<AuthRepository>());
      expect(mock.isConnected, isFalse);
      expect(mock.currentEmail, isNull);
      expect(mock.hasEmailAccount, isFalse);
    });

    test('signInAnonymously returns userId', () async {
      final mock = _MockAuthRepository();
      final id = await mock.signInAnonymously();
      expect(id, 'mock-anon-user');
    });

    test('signUpWithEmail returns userId', () async {
      final mock = _MockAuthRepository();
      final id = await mock.signUpWithEmail('test@test.com', 'pass123');
      expect(id, 'mock-email-user');
    });

    test('signInWithEmail returns userId', () async {
      final mock = _MockAuthRepository();
      final id = await mock.signInWithEmail('test@test.com', 'pass123');
      expect(id, 'mock-email-user');
    });

    test('signOut completes without error', () async {
      final mock = _MockAuthRepository();
      expect(() => mock.signOut(), returnsNormally);
    });
  });
}

class _MockAuthRepository implements AuthRepository {
  @override Future<void> init({required String url, required String anonKey}) async {}
  @override bool get isConnected => false;
  @override Future<String?> signInAnonymously() async => 'mock-anon-user';
  @override Future<String?> signUpWithEmail(String e, String p) async => 'mock-email-user';
  @override Future<String?> signInWithEmail(String e, String p) async => 'mock-email-user';
  @override Future<void> signOut() async {}
  @override String? get currentEmail => null;
  @override bool get hasEmailAccount => false;
}
