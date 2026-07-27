// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'highway_mode.dart';

part 'highway_mode_provider.g.dart';

/// App-wide highway-mode verdict (#3631).
///
/// Fed by whichever surface currently owns a live GPS stream (the radar
/// search provider on the search screen) — one detector, one truth, so
/// the ahead-filter and the UI chip always agree. `keepAlive` because
/// the sustained-speed history must survive screen churn: driving 10
/// minutes on the motorway then opening the search screen should land
/// directly in highway mode.
@Riverpod(keepAlive: true)
class HighwayMode extends _$HighwayMode {
  final HighwayModeDetector _detector = HighwayModeDetector();

  @override
  bool build() => false;

  /// Fold one GPS fix ([speedMps] as geolocator reports it).
  void onFix(double speedMps) {
    final speedKmh =
        speedMps.isFinite && speedMps > 0 ? speedMps * 3.6 : 0.0;
    _detector.onFix(speedKmh: speedKmh, at: DateTime.now());
    if (_detector.active != state) state = _detector.active;
  }

  /// Forget the speed history (used by tests and a country/session reset).
  void reset() {
    _detector.reset();
    if (state) state = false;
  }
}
