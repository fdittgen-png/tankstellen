// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The Android options EVERY `FlutterSecureStorage` in the app is built
/// with (#4373) — enforced by `test/lint/secure_storage_options_test.dart`.
///
/// `flutter_secure_storage` 11 defaults `resetOnError` to `true`: a
/// failed read, readAll or write (a KeyStore hiccup right after unlock, a
/// daemon restart, an OEM bug) makes the plugin DELETE stored data and
/// carry on — the entry it could not read (a `read` then answers null, as
/// if the key had never existed), every entry for a `readAll`, and
/// everything, via `deleteAll()`, for any other fault in the call. The
/// Hive encryption key is one of those entries. A transient error thereby
/// became permanent loss: without the key, every encrypted box is
/// unreadable forever (#4341 reports it; it cannot undo it).
///
/// With `resetOnError: false` the fault reaches Dart as a
/// `PlatformException`, and each caller decides: the Hive key load
/// surfaces a retryable `StorageInitException` and the next launch reads
/// the key again.
///
/// Every instance shares ONE preferences file and one KeyStore alias, so a
/// single call site still on the default could wipe every other secret.
/// That is why this is one constant and every construction must use it.
const AndroidOptions kSecureStorageAndroidOptions =
    AndroidOptions(resetOnError: false);

/// The iOS/iPadOS keychain options EVERY `FlutterSecureStorage` in the
/// app is built with (#4357) — enforced by the same lint test.
///
/// **This is a security decision, not a default.** The plugin's iOS
/// default is `kSecAttrAccessibleWhenUnlocked`: the item is readable
/// only while the screen is unlocked. That is stricter than what a
/// background recorder can live with.
///
/// The Hive AES key for every PII box comes out of this keychain, and
/// the active-trip box — the WAL meta row a running recording writes —
/// is one of them. On a locked device (screen off during a drive, or a
/// Core Bluetooth state-restoration relaunch into the background) the
/// `whenUnlocked` item cannot be read at all, so the trip that is being
/// recorded loses its storage key: no snapshot, no meta row, and a
/// launch that reaches `HiveCipherLoader` with nothing to decrypt with.
///
/// `first_unlock_this_device` (`kSecAttrAccessibleAfterFirstUnlock`
/// **ThisDeviceOnly**) trades exactly one window for that: between a
/// cold boot and the user's first unlock the item is sealed; from the
/// first unlock until the next reboot it is readable whether or not the
/// screen is locked. Approved by the maintainer for this reason
/// (`docs/decisions/0026-ios-recording-lifecycle.md`).
///
/// The `this_device` half is not decoration. It sets
/// `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`, which keeps the
/// item out of encrypted iCloud/iTunes backups and out of a
/// device-to-device transfer — so the key can never arrive on a second
/// device alongside box files it was not written for. That is the
/// property #4118 (`hive_wrong_key_truncates`) is about: a key that
/// travels with a backup is how box files and keys get mismatched, and
/// a mismatched key TRUNCATES the box instead of failing.
const IOSOptions kSecureStorageIosOptions =
    IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device);
