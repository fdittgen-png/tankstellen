// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../cache/cache_manager.dart';
import 'motorway_exits.dart';
import 'motorway_exits_service.dart';

part 'motorway_exits_provider.g.dart';

/// The one [MotorwayExitsService] (#3633). keepAlive — it owns the
/// per-country in-memory datasets and their freshness clocks.
@Riverpod(keepAlive: true)
MotorwayExitsService motorwayExitsService(Ref ref) =>
    MotorwayExitsService(cache: ref.watch(cacheManagerProvider));

/// The active-country motorway exits currently in memory (#3633).
///
/// Synchronous by design: the radar ranking runs synchronously per GPS
/// poll, so it reads whatever is loaded NOW. [ensureLoaded] kicks the
/// async fetch/rehydrate (called by the radar when highway mode is
/// active); until it lands the state is empty and highway mode behaves
/// exactly like exit-less v1.
@Riverpod(keepAlive: true)
class MotorwayExits extends _$MotorwayExits {
  String? _loadedFor;
  bool _loading = false;

  @override
  List<MotorwayExit> build() => const [];

  /// Fire-and-forget load of [countryCode]'s exits. Idempotent per
  /// country; a country switch reloads. Never throws (the service's
  /// contract) — a failed load leaves the empty v1 state.
  void ensureLoaded(String countryCode) {
    final cc = countryCode.toUpperCase();
    if (_loading || _loadedFor == cc) return;
    _loading = true;
    unawaited(() async {
      try {
        final exits = await ref.read(motorwayExitsServiceProvider).exitsFor(cc);
        // The provider is keepAlive, but a torn-down test container (or
        // a future lifecycle change) must not take a post-dispose write.
        if (!ref.mounted) return;
        _loadedFor = cc;
        state = exits;
      } finally {
        _loading = false;
      }
    }());
  }
}

/// Per-station exit annotations for the CURRENT radar list (#3633),
/// written by the radar search provider after each ranked poll and
/// consumed by the station card ("via exit {ref} · +{km} km") — the
/// same map-shaped side-channel pattern as `roadDistancesProvider`
/// (#3634), so the card wiring stays identical.
@Riverpod(keepAlive: true)
class HighwayExitInfoMap extends _$HighwayExitInfoMap {
  @override
  Map<String, HighwayExitInfo> build() => const {};

  void publish(Map<String, HighwayExitInfo> info) => state = info;

  void clear() {
    if (state.isNotEmpty) state = const {};
  }
}
