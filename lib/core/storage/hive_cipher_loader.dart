// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'hive_box_key_probe.dart';
import 'impl/hive_directory_resolver.dart';
import 'secure_storage_options.dart';

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

  /// Refuse a key the box files on disk were not written with — decided
  /// BEFORE a replacement key is persisted and before any `openBox`
  /// (#4118, #4341).
  ///
  /// Both halves of "before" are load-bearing:
  ///
  /// * **Before the open**, because the open does not fail. Hive's crash
  ///   recovery reads the undecryptable frames, decides the box is
  ///   corrupt and TRUNCATES the file to zero bytes — measured at 93
  ///   bytes in, 0 bytes out, with no error and no telemetry.
  /// * **Before the key write** (#4341), because #4118 decided after it.
  ///   The stopped launch had already stored a new key, so the next
  ///   process read that key back, found nothing launch-local telling it
  ///   the key was new, and truncated the restored boxes anyway. A key
  ///   that is never written leaves the next launch in exactly the state
  ///   this one saw, so the verdict repeats until the user resolves it.
  ///
  /// The verdict reads the files' own frame checksums
  /// ([HiveBoxKeyProbe]), not the mere presence of files: a plaintext box
  /// (the #1686 legacy migration, the spool, the schema stamps) is no
  /// evidence of a lost key. It also runs when a key IS stored, which is
  /// what rescues an install #4118 already stopped once — its
  /// replacement key is on disk, and no box was ever written with it.
  ///
  /// With no key and a directory that cannot be inspected, no key is
  /// minted either: that is a retryable [StorageInitException], never a
  /// guess that might authorise the truncating open.
  static Future<HiveAesCipher> _loadCipher() async {
    const secureStorage =
        FlutterSecureStorage(aOptions: kSecureStorageAndroidOptions);
    final existing = await secureStorage.read(key: _hiveEncryptionKeyName);
    final stored =
        existing == null ? null : HiveAesCipher(base64Url.decode(existing));
    final verdict =
        HiveBoxKeyProbe.inspect(HiveDirectoryResolver.hivePath, stored);
    if (verdict == BoxKeyVerdict.keyLost) {
      throw StorageKeyLostException(stored == null
          ? 'box files exist but this install has no encryption key — a '
              'restore without its KeyStore key'
          : 'box files were written under a different key than the stored '
              'one — a restore whose replacement key was already written');
    }
    if (stored != null) return stored;
    if (verdict == BoxKeyVerdict.unknown) {
      throw const StorageInitException(
          'the Hive directory could not be inspected, so no encryption key '
          'was created');
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
  ///
  /// The two verdicts [_loadCipher] reaches itself pass through untouched:
  /// a [StorageKeyLostException] must reach the key-loss screen, not the
  /// cause-unknown one.
  static Future<HiveAesCipher> loadGuarded() async {
    try {
      return await cipherLoader();
    } on StorageKeyLostException {
      rethrow;
    } on StorageInitException {
      rethrow;
    } catch (e, st) {
      Error.throwWithStackTrace(
        StorageInitException(
            'the secure-storage encryption key could not be loaded', e),
        st,
      );
    }
  }
}
