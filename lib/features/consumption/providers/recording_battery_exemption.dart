// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/recording_location_settings.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/permissions/battery_optimization_permissions.dart';
import '../../../core/storage/storage_keys.dart';
import '../../../core/storage/storage_providers.dart';

/// Prompts the user — once — to exempt the app from battery optimization
/// when a recording foreground service is about to run, so a long drive
/// survives Doze and aggressive OEM task-killers (#3313).
///
/// Deliberately conservative:
///   * gated on [kGpsRecordingForegroundServiceEnabled] — default builds
///     have no recording FGS, so there is nothing to keep alive and the
///     `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission isn't even shipped;
///   * one-time — the asked flag is persisted BEFORE the prompt, so a
///     declined (or crashed) dialog never re-nags;
///   * skipped when already exempt;
///   * fired only from MANUAL recording starts (the app is foreground, so
///     the system Activity dialog can actually show);
///   * never throws — it is a best-effort side effect of starting a trip.
class RecordingBatteryExemption {
  final BatteryOptimizationPermissions _permissions;
  final bool Function() _alreadyAsked;
  final Future<void> Function() _markAsked;

  /// Build gate, injectable for tests. Defaults to the production flag.
  final bool fgsEnabled;

  RecordingBatteryExemption({
    required BatteryOptimizationPermissions permissions,
    required bool Function() alreadyAsked,
    required Future<void> Function() markAsked,
    this.fgsEnabled = kGpsRecordingForegroundServiceEnabled,
  })  : _permissions = permissions,
        _alreadyAsked = alreadyAsked,
        _markAsked = markAsked;

  /// Best-effort one-time prompt. Safe to fire-and-forget from a manual
  /// recording start; never throws into the recording path.
  Future<void> maybePrompt() async {
    if (!fgsEnabled) return; // no recording FGS in this build → nothing to do
    if (_alreadyAsked()) return;
    try {
      // Mark first: a declined dialog or a crash mid-prompt must not re-nag.
      await _markAsked();
      if (await _permissions.isExempt()) return; // already whitelisted
      await _permissions.requestExemption();
    } catch (e, st) {
      // A failed prompt must never break recording — log and move on.
      unawaited(errorLogger.log(ErrorLayer.other, e, st,
          context: const {'where': 'RecordingBatteryExemption.maybePrompt'}));
    }
  }
}

/// Production wiring: the real plugin permission + the persisted one-time
/// flag in the settings box.
final recordingBatteryExemptionProvider =
    Provider<RecordingBatteryExemption>((ref) {
  // The settings read is LAZY (inside the closures, not the factory) so the
  // gated path — `fgsEnabled == false`, the default/every-test build — never
  // touches the Hive settings box. Only a real FGS-approved manual start
  // (which has passed the gate) ever reads/writes the asked flag.
  return RecordingBatteryExemption(
    permissions: const PluginBatteryOptimizationPermissions(),
    alreadyAsked: () =>
        ref.read(settingsStorageProvider).getSetting(
              StorageKeys.batteryOptExemptionAsked,
            ) ==
        true,
    markAsked: () => ref.read(settingsStorageProvider).putSetting(
          StorageKeys.batteryOptExemptionAsked,
          true,
        ),
  );
});
