// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Hive-INDEPENDENT persistence for a fatal startup failure (#3149).
///
/// When the storage phase bricks (corrupted box, secure-storage cipher
/// failure, trace-box open fault), every normal observability channel is
/// dead: Hive is down, so the trace store AND the isolate error spool
/// can't write, and `debugPrint` is no-opped in release. The recovery
/// screen tells the *user* something, but the *maintainer* learned
/// nothing — the cause evaporated with the process.
///
/// This store writes a tiny `startup_failure.json` into the app
/// documents directory with plain `dart:io` file I/O — no Hive, no
/// Riverpod, no platform plugins beyond path_provider — so the NEXT
/// successful launch can [drain] it into the trace pipeline.
///
/// Best-effort on both sides: a [persist] or [drain] fault is swallowed
/// (with a `debugPrint` for dev runs) — observability must never make a
/// bricked startup worse, and a corrupt record must never brick the
/// healthy launch reading it.
class StartupFailureStore {
  StartupFailureStore._();

  /// File name inside the app documents directory.
  static const String fileName = 'startup_failure.json';

  /// Test seam: where the record lives. Defaults to the app documents
  /// directory; tests point it at a temp dir (and can throw to drive
  /// the fault path).
  @visibleForTesting
  static Future<Directory> Function() directoryProvider =
      getApplicationDocumentsDirectory;

  /// Reset the test seam. Call from `tearDown`.
  @visibleForTesting
  static void resetForTest() {
    directoryProvider = getApplicationDocumentsDirectory;
  }

  /// Persist the startup-bricking [error] + [stack]. Overwrites any
  /// previous record — the most recent failed launch is the one worth
  /// triaging. Swallows its own failures (see class doc).
  static Future<void> persist(Object error, StackTrace stack) async {
    try {
      final dir = await directoryProvider();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(jsonEncode(<String, String>{
        'at': DateTime.now().toIso8601String(),
        'errorType': error.runtimeType.toString(),
        'error': error.toString(),
        'stack': stack.toString(),
      }));
    } catch (e, st) {
      // Hive is already down when persist runs; there is no deeper
      // fallback channel left. Dev-visible only, by construction.
      debugPrint('StartupFailureStore: persist failed: $e\n$st');
    }
  }

  /// Read-and-delete the pending record from a previous bricked launch,
  /// or `null` when there is none (the overwhelmingly common case — one
  /// `File.exists` stat). Deleting before returning guarantees a
  /// poisoned record is reported at most once.
  static Future<Map<String, dynamic>?> drain() async {
    try {
      final dir = await directoryProvider();
      final file = File('${dir.path}/$fileName');
      if (!file.existsSync()) return null;
      final raw = await file.readAsString();
      await file.delete();
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e, st) {
      debugPrint('StartupFailureStore: drain failed: $e\n$st');
      return null;
    }
  }
}
