// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_log.dart';
import '../../core/logging/error_logger.dart';
import '../../core/storage/hive_boxes.dart';
import '../../core/storage/hive_cipher_loader.dart';
import '../../core/telemetry/storage/startup_failure_store.dart';
import '../widgets/storage_recovery_screen.dart';

/// Runs the storage phase and, if it fails, turns the fault into the
/// right recovery screen (#2294 / #3149 / #4116 / #4118).
///
/// Returns `true` when storage came up and startup may continue, and
/// `false` when a recovery screen has been mounted in its place.
///
/// Extracted from `AppInitializer.run` (#4118) once there were three
/// causes to distinguish. What the screen is ALLOWED to claim is a
/// decision with real stakes — #4116 shipped a build that advised every
/// storage fault to clear its storage, including a recursion bug a
/// one-line patch fixed — and that decision deserves to be readable in
/// one place rather than inline in the launch sequence.
///
/// Every fault here escaped uncaught before #2294/#3149: no Zone handler
/// exists this early (they install in `_launch`), so the user froze on
/// the splash with no message and, because `debugPrint` is silenced in
/// release, no telemetry either. Each branch therefore both persists the
/// cause through [StartupFailureStore] — a plain file, because Hive is
/// the thing that is down — and logs it.
Future<bool> runStoragePhaseGuarded(Future<void> Function() initStorage) async {
  try {
    await initStorage();
    return true;
  } on HiveCorruptionException catch (e, st) {
    // #4116 — damage is the ONLY cause that may advise data loss on the
    // grounds that the files are unrecoverable.
    await _report(e, st, 'corruptBox');
    _mount(StorageRecoveryCause.corruptBox);
    return false;
  } on StorageKeyLostException catch (e, st) {
    // #4118 — a restore, not damage: intact boxes whose KeyStore-bound
    // key could not follow them. Clearing storage is right here too, and
    // this is the one branch that can also say TankSync kept a copy of
    // whatever was synced.
    await _report(e, st, 'keyLost');
    _mount(StorageRecoveryCause.keyLost);
    return false;
  } catch (e, st) {
    // Any OTHER storage-phase fault — secure-storage cipher,
    // TraceStorage, loadApiKey, or a bug of ours. Cause not established,
    // so the screen says so and tells the user NOT to clear storage.
    await _report(e, st, 'unknown');
    _mount(StorageRecoveryCause.unknown);
    return false;
  }
}

Future<void> _report(Object e, StackTrace st, String cause) async {
  await StartupFailureStore.persist(e, st);
  log.error(e, st,
      layer: ErrorLayer.storage,
      context: {'where': 'initStorage', 'cause': cause});
}

void _mount(StorageRecoveryCause cause) =>
    runApp(ProviderScope(child: StorageRecoveryHost(cause: cause)));
