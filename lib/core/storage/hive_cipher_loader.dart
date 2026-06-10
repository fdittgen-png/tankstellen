// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Thrown when storage initialisation fails BEFORE the Hive boxes can
/// even be opened — e.g. a `PlatformException` out of the
/// FlutterSecureStorage encryption-key read (#3149). Sibling of
/// `HiveCorruptionException`: both are routed by `AppInitializer.run` to
/// the same `StorageRecoveryHost` instead of leaving the user frozen on
/// the splash. Kept distinct because the recovery *advice* differs — the
/// box files are fine; it is the keychain/keystore path that failed.
class StorageInitException implements Exception {
  /// Human-readable detail of what failed.
  final String message;

  /// The underlying fault (e.g. the secure-storage `PlatformException`).
  final Object? cause;

  const StorageInitException(this.message, [this.cause]);

  @override
  String toString() => 'StorageInitException: $message'
      '${cause == null ? '' : ' (cause: $cause)'}';
}

/// Loads (or first-run generates) the AES cipher that encrypts the
/// PII-bearing Hive boxes. Extracted from `HiveBoxes` (#3149) so the
/// secure-storage round-trip has one owner and one guarded entry point.
class HiveCipherLoader {
  HiveCipherLoader._();

  static const _hiveEncryptionKeyName = 'hive_encryption_key';

  static Future<HiveAesCipher> _loadCipher() async {
    const secureStorage = FlutterSecureStorage();
    final existing = await secureStorage.read(key: _hiveEncryptionKeyName);
    if (existing != null) {
      final keyBytes = base64Url.decode(existing);
      return HiveAesCipher(keyBytes);
    }
    final key = Hive.generateSecureKey();
    await secureStorage.write(
      key: _hiveEncryptionKeyName,
      value: base64UrlEncode(key),
    );
    return HiveAesCipher(key);
  }

  /// Test seam (#3149): the raw cipher load, injectable so a secure-
  /// storage fault (`PlatformException` from the keychain/keystore) can
  /// be driven without a platform channel.
  @visibleForTesting
  static Future<HiveAesCipher> Function() cipherLoader = _loadCipher;

  /// Reset the [cipherLoader] seam. Call from `tearDown`.
  @visibleForTesting
  static void resetCipherLoaderForTest() {
    cipherLoader = _loadCipher;
  }

  /// #3149 — the FlutterSecureStorage read in [_loadCipher] used to sit
  /// OUTSIDE the `on HiveError` re-tag in `HiveBoxes.init`, so a
  /// keychain/keystore `PlatformException` escaped as an untyped error
  /// the startup path had no catch for: the user froze on the splash
  /// with no recovery screen and no telemetry. Re-tag it as a typed
  /// [StorageInitException] (preserving the original stack) so
  /// `AppInitializer.run` routes it to the same `StorageRecoveryHost`
  /// as a corrupted box.
  static Future<HiveAesCipher> loadGuarded() async {
    try {
      return await cipherLoader();
    } catch (e, st) {
      Error.throwWithStackTrace(
        StorageInitException(
            'the secure-storage encryption key could not be loaded', e),
        st,
      );
    }
  }
}
