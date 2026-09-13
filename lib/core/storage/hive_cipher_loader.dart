// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'impl/hive_directory_resolver.dart';

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

/// Thrown when the encrypted boxes are on disk but the key that reads
/// them is gone (#4118).
///
/// The one way to reach this state is a restore: Android Auto-Backup and
/// device-to-device transfer copy the app's files, but the KeyStore
/// master key behind `FlutterSecureStorage` is hardware-bound and never
/// travels. The boxes come back as ciphertext nothing on the new install
/// can decrypt.
///
/// It is a sibling of `HiveCorruptionException` and deliberately NOT the
/// same type: the files are not damaged, and the difference matters to
/// the user. Corruption is a fault with an unknown cause; this has a
/// known cause, a known consequence (the restored history is
/// unrecoverable — AES-256 with a lost key is not a repair problem) and
/// a known exit that the corruption copy does not mention: whatever was
/// synced comes back from TankSync.
///
/// #4118 also excluded both halves from the backup set, so a fresh
/// restore can no longer produce this. This stays for the installs that
/// were already restored before that shipped — and because a state that
/// is knowable should be named rather than reported as corruption.
class StorageKeyLostException implements Exception {
  const StorageKeyLostException(this.message);

  final String message;

  @override
  String toString() => 'StorageKeyLostException: $message';
}

/// Loads (or first-run generates) the AES cipher that encrypts the
/// PII-bearing Hive boxes. Extracted from `HiveBoxes` (#3149) so the
/// secure-storage round-trip has one owner and one guarded entry point.
class HiveCipherLoader {
  HiveCipherLoader._();

  static const _hiveEncryptionKeyName = 'hive_encryption_key';

  /// Whether THIS launch generated a brand-new encryption key (#4118).
  ///
  /// True on a genuine first run — and on a restored install, where the
  /// old key stayed on the old phone. Those two are indistinguishable
  /// here, but they are not indistinguishable one step later: a first
  /// run has no box files, so nothing fails to open. A box that fails to
  /// open while this is true is therefore the restore case, not
  /// corruption — which is exactly the discrimination
  /// `HiveFirstFrameBoxes` makes with it.
  static bool get keyGeneratedThisLaunch => _keyGeneratedThisLaunch;
  static bool _keyGeneratedThisLaunch = false;

  /// Set the launch-scoped flag directly. Reset it in `tearDown`; pass
  /// `true` to stand in for the generate branch when the cipher itself
  /// is stubbed through [cipherLoader].
  @visibleForTesting
  static void setKeyGeneratedForTest({required bool value}) {
    _keyGeneratedThisLaunch = value;
  }

  static Future<HiveAesCipher> _loadCipher() async {
    const secureStorage = FlutterSecureStorage();
    final existing = await secureStorage.read(key: _hiveEncryptionKeyName);
    if (existing != null) {
      final keyBytes = base64Url.decode(existing);
      return HiveAesCipher(keyBytes);
    }
    _keyGeneratedThisLaunch = true;
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
  /// Refuse to open boxes this install cannot read (#4118).
  ///
  /// A new key plus box files that predate it has exactly one cause: a
  /// backup or device-transfer restore brought the encrypted files back
  /// while their KeyStore-bound master key stayed on the old phone.
  ///
  /// It must run BEFORE the first `openBox`, because the open does not
  /// fail. Hive's crash recovery reads the undecryptable frames, decides
  /// the box is corrupt and TRUNCATES the file to zero bytes — measured
  /// at 93 bytes in, 0 bytes out, with no error and no telemetry. The
  /// app then starts looking perfectly healthy and completely empty,
  /// having destroyed the only copy of the restored data. A genuine
  /// first run reaches this too and passes: it has no box files.
  static void assertKeyMatchesExistingBoxes() {
    if (!keyGeneratedThisLaunch) return;
    if (!HiveDirectoryResolver.hasExistingBoxFiles) return;
    throw const StorageKeyLostException(
        'box files exist but this install generated a new encryption key '
        '— a restore without its KeyStore key');
  }

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
