// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../logging/error_logger.dart';

/// Minimal key-value seam over [FlutterSecureStorage] so tests can fake
/// (and fault-inject) the platform keychain/keystore without a method
/// channel (#3740).
abstract class SecureKeyValueStore {
  /// Reads the value for [key], or `null` when absent.
  Future<String?> read(String key);

  /// Writes [value] under [key].
  Future<void> write(String key, String value);

  /// Deletes [key] (no-op when absent).
  Future<void> delete(String key);
}

/// Production implementation backed by [FlutterSecureStorage] — the same
/// keychain/keystore that already holds the Hive encryption key (see
/// `HiveCipherLoader`).
class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  const FlutterSecureKeyValueStore();

  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Supabase auth [LocalStorage] that keeps the session (incl. the live
/// refresh token) in the platform keychain/keystore instead of plaintext
/// SharedPreferences (#3740).
///
/// ## Why
/// The SDK default (`SharedPreferencesLocalStorage`) persists the whole
/// session JSON — refresh token included — in
/// `FlutterSharedPreferences.xml`, which Google Auto-Backup and
/// device-to-device migration happily ship off-device. This store moves
/// the token behind the OS keystore; the backup rules added alongside it
/// exclude the legacy prefs file for defence in depth.
///
/// ## One-time legacy migration
/// [initialize] looks for a session under the SAME [persistSessionKey]
/// in SharedPreferences (the slot the default storage used:
/// `sb-<host-first-label>-auth-token`). When found, it is imported into
/// the secure store (unless a secure-store session already exists — the
/// newer one wins) and the plaintext copy is wiped. The wipe only runs
/// after the import succeeded, so a transiently broken keystore never
/// destroys the only copy of the session.
///
/// ## Never-throws contract
/// Every method degrades instead of crashing the auth bootstrap: a broken
/// keychain/keystore must result in a fresh sign-in, not a startup
/// crash-loop. Faults are logged via [errorLogger] and the method never
/// throws — reads report "no session", writes/deletes become best-effort
/// (the in-memory session for the current run is unaffected).
class SecureSessionLocalStorage extends LocalStorage {
  SecureSessionLocalStorage({
    required this.persistSessionKey,
    SecureKeyValueStore? secureStore,
    Future<SharedPreferences> Function()? legacyPrefsLoader,
  })  : _secureStore = secureStore ?? const FlutterSecureKeyValueStore(),
        _legacyPrefsLoader = legacyPrefsLoader ?? SharedPreferences.getInstance;

  /// Storage key for the persisted session JSON. Uses the SAME
  /// `sb-<host-first-label>-auth-token` shape as the SDK default so the
  /// legacy SharedPreferences slot can be located for migration.
  final String persistSessionKey;

  final SecureKeyValueStore _secureStore;
  final Future<SharedPreferences> Function() _legacyPrefsLoader;

  @override
  Future<void> initialize() async {
    await _migrateLegacyPrefsSession();
  }

  /// Imports a plaintext SharedPreferences session left behind by the
  /// pre-#3740 default storage, then wipes the plaintext copy. Never
  /// throws — on any fault the migration is simply retried on the next
  /// app start (the legacy key is only removed after a successful
  /// import).
  Future<void> _migrateLegacyPrefsSession() async {
    try {
      final prefs = await _legacyPrefsLoader();
      final legacy = prefs.getString(persistSessionKey);
      if (legacy == null) return;
      final existing = await _secureStore.read(persistSessionKey);
      if (existing == null) {
        // No secure-store session yet — import the legacy one so the
        // user stays signed in across the upgrade.
        await _secureStore.write(persistSessionKey, legacy);
      }
      // Wipe the plaintext copy only once the secure store holds a
      // session (imported or already newer).
      await prefs.remove(persistSessionKey);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: const {
        'where': 'SecureSessionLocalStorage: legacy prefs session migration '
            'failed — will retry next start'
      }));
    }
  }

  @override
  Future<bool> hasAccessToken() async => (await accessToken()) != null;

  @override
  Future<String?> accessToken() async {
    try {
      return await _secureStore.read(persistSessionKey);
    } catch (e, st) {
      // Degrade to "no persisted session" → the auth flow falls back to
      // a fresh sign-in instead of crash-looping on a broken keystore.
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: const {
        'where': 'SecureSessionLocalStorage: secure-store read failed — '
            'degrading to fresh sign-in'
      }));
      return null;
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    try {
      await _secureStore.write(persistSessionKey, persistSessionString);
    } catch (e, st) {
      // Best-effort: the in-memory session keeps working for this run;
      // the next start falls back to a fresh sign-in.
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: const {
        'where': 'SecureSessionLocalStorage: secure-store write failed — '
            'session not persisted'
      }));
    }
  }

  @override
  Future<void> removePersistedSession() async {
    try {
      await _secureStore.delete(persistSessionKey);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: const {
        'where': 'SecureSessionLocalStorage: secure-store delete failed'
      }));
    }
  }
}
