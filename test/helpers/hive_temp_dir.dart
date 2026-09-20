// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// #4398 — the ONE teardown for a test that ran Hive against a temp
/// directory.
///
/// **The race it removes.** `Hive.close()` does more than drop references:
/// for every open box `StorageBackendVm._closeInternal` closes the two
/// `RandomAccessFile`s and then *deletes that box's `.lock` file*. A
/// teardown that removes the temp directory while any part of that is
/// still in flight makes Hive's own delete fail with
///
/// ```
/// PathNotFoundException: Cannot delete file,
///   path = '…/isolate_error_spool.lock'
///     StorageBackendVm._closeInternal … HiveImpl.close … <test>:97
/// ```
///
/// which fails the test that was merely tidying up. It fired on three CI
/// shards (`service_reminder_evaluator_test` twice,
/// `opportunity_stores_test` once) against diffs that touched no storage
/// code, and passed standalone every time — the signature of a teardown
/// ordering race rather than a test bug.
///
/// **The contract.**
/// 1. `Hive.close()` is awaited *to completion* before anything is
///    removed, so every box has released its files and unlinked its lock.
/// 2. If the close does not complete within [closeTimeout] the directory
///    is deliberately **left in place**: deleting under a close that is
///    still running is precisely the race above, and a leaked directory
///    under `Directory.systemTemp` costs nothing. A widget test can leave
///    a Hive write pending on a fake clock, so the bound also keeps a
///    hung close from hanging the whole suite.
/// 3. A `FileSystemException` out of `Hive.close()` itself is absorbed:
///    if something else already took the directory away, the boxes are
///    still closed and there is nothing left for the test to assert
///    about. `PathNotFoundException` is a `FileSystemException`, so one
///    `on` clause covers both. Nothing broader is caught — a `StateError`
///    or a corrupt-box failure out of Hive must still fail the test.
/// 4. The directory delete tolerates an already-gone path for the same
///    reason, and only for that reason.
///
/// Every absorbed failure is reported with its stack trace, so a teardown
/// that silently skipped its cleanup is still readable in the log.
///
/// Pass the directory the test created with
/// `Directory.systemTemp.createTemp*`. Safe to call when Hive was never
/// initialised, safe after `Hive.deleteFromDisk()`, and safe to call
/// twice.
///
/// Enforced by `test/lint/no_hand_rolled_hive_teardown_test.dart`: a test
/// file that mentions Hive may not remove a directory recursively from
/// its own `tearDown`/`tearDownAll`.
Future<void> closeHiveAndDeleteTemp(
  Directory dir, {
  Duration closeTimeout = const Duration(seconds: 10),
}) async {
  try {
    await Hive.close().timeout(closeTimeout);
  } on TimeoutException catch (e, st) {
    // Rule 2: a close still in flight owns the directory. Leave it.
    debugPrint('closeHiveAndDeleteTemp: Hive.close() did not finish within '
        '$closeTimeout — leaving ${dir.path} for the OS to reclaim: $e\n$st');
    return;
  } on FileSystemException catch (e, st) {
    // Hive unlinking a `.lock` under a directory somebody else already
    // removed. The boxes are closed either way; see rule 3.
    debugPrint('closeHiveAndDeleteTemp: Hive.close() raced a delete of '
        '${dir.path}: $e\n$st');
  }
  try {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  } on FileSystemException catch (e, st) {
    // Already gone (a parallel teardown, or `Hive.deleteFromDisk()` taking
    // the directory with it). Nothing to clean up is the desired end
    // state.
    debugPrint('closeHiveAndDeleteTemp: temp dir ${dir.path} was already '
        'gone: $e\n$st');
  }
}
