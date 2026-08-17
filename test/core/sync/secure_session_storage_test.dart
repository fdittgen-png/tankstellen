// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tankstellen/core/sync/secure_session_storage.dart';

/// In-memory fake of the keychain/keystore seam (#3740).
class FakeSecureStore implements SecureKeyValueStore {
  final Map<String, String> data = {};

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    data.remove(key);
  }
}

/// Fault-injection fake: every operation throws, simulating a broken
/// keychain/keystore (the #3149 class of PlatformException).
class BrokenSecureStore implements SecureKeyValueStore {
  @override
  Future<String?> read(String key) async =>
      throw Exception('keystore broken (read)');

  @override
  Future<void> write(String key, String value) async =>
      throw Exception('keystore broken (write)');

  @override
  Future<void> delete(String key) async =>
      throw Exception('keystore broken (delete)');
}

/// Reads succeed (empty store) but writes fail — drives the migration
/// wipe-guard: the plaintext copy must survive a failed import.
class WriteFailingSecureStore extends FakeSecureStore {
  @override
  Future<void> write(String key, String value) async =>
      throw Exception('keystore broken (write)');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const key = 'sb-myproject-auth-token';
  const legacySession = '{"access_token":"legacy","refresh_token":"r1"}';
  const newerSession = '{"access_token":"newer","refresh_token":"r2"}';

  group('SecureSessionLocalStorage round-trip', () {
    test('persist → has → access → remove against the secure store', () async {
      SharedPreferences.setMockInitialValues({});
      final store = FakeSecureStore();
      final storage = SecureSessionLocalStorage(
        persistSessionKey: key,
        secureStore: store,
      );
      await storage.initialize();

      expect(await storage.hasAccessToken(), isFalse);
      await storage.persistSession(legacySession);
      expect(store.data[key], legacySession);
      expect(await storage.hasAccessToken(), isTrue);
      expect(await storage.accessToken(), legacySession);
      await storage.removePersistedSession();
      expect(await storage.hasAccessToken(), isFalse);
      expect(store.data, isEmpty);
    });
  });

  group('one-time legacy SharedPreferences migration (#3740)', () {
    test('imports the plaintext prefs session and wipes the legacy slot',
        () async {
      SharedPreferences.setMockInitialValues({key: legacySession});
      final store = FakeSecureStore();
      final storage = SecureSessionLocalStorage(
        persistSessionKey: key,
        secureStore: store,
      );

      await storage.initialize();

      // Imported into the secure store…
      expect(store.data[key], legacySession);
      expect(await storage.accessToken(), legacySession);
      // …and the plaintext copy is gone.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(key), isNull);
    });

    test('keeps an existing secure-store session (newer wins) but still '
        'wipes the plaintext copy', () async {
      SharedPreferences.setMockInitialValues({key: legacySession});
      final store = FakeSecureStore()..data[key] = newerSession;
      final storage = SecureSessionLocalStorage(
        persistSessionKey: key,
        secureStore: store,
      );

      await storage.initialize();

      expect(store.data[key], newerSession);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(key), isNull);
    });

    test('no legacy session → migration is a no-op', () async {
      SharedPreferences.setMockInitialValues({});
      final store = FakeSecureStore();
      final storage = SecureSessionLocalStorage(
        persistSessionKey: key,
        secureStore: store,
      );

      await storage.initialize();

      expect(store.data, isEmpty);
    });

    test('a failed secure-store import keeps the legacy copy for the next '
        'start (wipe only after successful import)', () async {
      SharedPreferences.setMockInitialValues({key: legacySession});
      final storage = SecureSessionLocalStorage(
        persistSessionKey: key,
        secureStore: WriteFailingSecureStore(),
      );

      // Never-throws: the fault is swallowed…
      await expectLater(storage.initialize(), completes);

      // …and the ONLY copy of the session was not destroyed.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(key), legacySession);
    });

    test('a broken prefs loader cannot crash initialize', () async {
      final storage = SecureSessionLocalStorage(
        persistSessionKey: key,
        secureStore: FakeSecureStore(),
        legacyPrefsLoader: () async => throw Exception('prefs broken'),
      );

      await expectLater(storage.initialize(), completes);
    });
  });

  group('never-throws degradation on a broken keystore (#3740)', () {
    late SecureSessionLocalStorage storage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = SecureSessionLocalStorage(
        persistSessionKey: key,
        secureStore: BrokenSecureStore(),
      );
    });

    test('initialize completes (degrades to fresh sign-in)', () async {
      // Note: with a legacy session present the read fault is caught too.
      SharedPreferences.setMockInitialValues({key: legacySession});
      await expectLater(storage.initialize(), completes);
    });

    test('accessToken degrades to null instead of throwing', () async {
      expect(() => storage.accessToken(), returnsNormally);
      expect(await storage.accessToken(), isNull);
    });

    test('hasAccessToken degrades to false instead of throwing', () async {
      expect(await storage.hasAccessToken(), isFalse);
    });

    test('persistSession is best-effort — completes without throwing',
        () async {
      await expectLater(storage.persistSession(legacySession), completes);
    });

    test('removePersistedSession completes without throwing', () async {
      await expectLater(storage.removePersistedSession(), completes);
    });
  });
}
