// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/error_logger.dart';
import '../../../core/storage/storage_keys.dart';
import '../../../core/storage/storage_providers.dart';

part 'radar_pin_provider.g.dart';

/// "Always pin when the fuel-station radar starts" preference (#2785).
///
/// Mirrors the trip-recording [RecordingProfile.autoPin]: when on, the search
/// screen pins itself (wake lock + immersive bars) the moment the radar
/// activates, so the closest-station readout stays visible on a dashboard
/// mount without a manual tap each time.
///
/// **Defaults to true** — the dashboard-mount use case is the common one. The
/// read is defensive: a missing key (fresh install) or briefly-unavailable
/// storage (before init / in tests) degrades to the `true` default rather than
/// crashing the search screen. A stored explicit `false` (a deliberate opt-out
/// via the pin-help toggle) is honoured.
@Riverpod(keepAlive: true)
class RadarAutoPin extends _$RadarAutoPin {
  @override
  bool build() {
    try {
      final raw = ref
          .watch(storageRepositoryProvider)
          .getSetting(StorageKeys.radarAutoPin);
      // Absent key → the true default; a stored bool wins.
      return raw is bool ? raw : true;
    } catch (_) {
      return true;
    }
  }

  /// Persist and publish the preference. Best-effort write — a storage
  /// failure still updates the in-memory state so the toggle reflects the
  /// user's choice for the session.
  Future<void> set(bool value) async {
    state = value;
    try {
      await ref
          .read(storageRepositoryProvider)
          .putSetting(StorageKeys.radarAutoPin, value);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st,
          context: const {'where': 'RadarAutoPin: write failed'}));
    }
  }
}
