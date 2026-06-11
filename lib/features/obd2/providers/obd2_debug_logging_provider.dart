// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/storage_keys.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/obd2_debug_session.dart';

part 'obd2_debug_logging_provider.g.dart';

/// Opt-in OBD2 debug-session logging flag (#1925).
///
/// When on, every OBD2 connection is recorded — init handshake, data
/// gaps, drops and reconnects — as an exportable XML session log (see
/// [Obd2DebugSessionRecorder]). Off by default; the user opts in via a
/// checkbox in the Trips (OBD2) settings sub-section.
///
/// `build()` mirrors the persisted flag onto
/// [Obd2DebugSessionRecorder.enabled], so reading this provider once at
/// app start (`AppInitializer` warm-up) is enough to arm the recorder
/// for the whole session — the recorder is a plain static and is not
/// itself provider-aware.
@riverpod
class Obd2DebugSessionLogging extends _$Obd2DebugSessionLogging {
  @override
  bool build() {
    final storage = ref.watch(storageRepositoryProvider);
    final enabled = storage.getSetting(
            StorageKeys.obd2DebugSessionLoggingEnabled) as bool? ??
        false;
    Obd2DebugSessionRecorder.enabled = enabled;
    return enabled;
  }

  /// Persist [value], arm/disarm the recorder, and update the state.
  Future<void> set(bool value) async {
    final storage = ref.read(storageRepositoryProvider);
    await storage.putSetting(
        StorageKeys.obd2DebugSessionLoggingEnabled, value);
    Obd2DebugSessionRecorder.enabled = value;
    state = value;
  }

  /// Flip the current value.
  Future<void> toggle() => set(!state);
}
