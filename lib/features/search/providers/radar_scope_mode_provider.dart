// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'radar_scope_mode_provider.g.dart';

/// Whether the active Fuel Station Radar renders its stations as the PPI
/// radar-scope view (#3342) instead of the distance-sorted list.
///
/// A pure UI toggle scoped to the search results panel — flipping it never
/// re-runs the scan, it only swaps the visualization of the same station set.
/// Defaults to the list (familiar, accessible default); the scope is the
/// opt-in second view.
@riverpod
class RadarScopeMode extends _$RadarScopeMode {
  @override
  bool build() => false;

  /// Flip between the list and the radar-scope view.
  void toggle() => state = !state;
}
