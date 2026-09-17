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
