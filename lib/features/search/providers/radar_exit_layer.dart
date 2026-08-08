// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/country/country_provider.dart';
import '../../../core/domain/station.dart';
import '../../../core/services/radar/motorway_exits.dart';
import '../../../core/services/radar/motorway_exits_provider.dart';
import '../../../core/services/radar/radar_ranking.dart';
import '../../../core/domain/fuel_type.dart';

/// #3633 v2 — exit-aware layer over the ranked list: when highway mode
/// is active and the active country's motorway exits are loaded,
/// re-sort by along-track distance and publish per-station "via exit"
/// annotations to [highwayExitInfoMapProvider] (the #3634-style
/// side-channel the station card watches). Off-highway (or before the
/// exits asset lands) this is v1 behaviour verbatim: ranked order
/// unchanged, annotation map empty. Shell-safe.
List<Station> applyHighwayExitLayer(
  Ref ref,
  List<Station> ranked,
  double lat,
  double lng,
  ({bool active, double? heading, bool leftHand}) hw,
) {
  try {
    final heading = hw.heading;
    if (!hw.active || heading == null) {
      ref.read(highwayExitInfoMapProvider.notifier).clear();
      return ranked;
    }
    // Lazy per-country load — a no-op once loaded; until it lands the
    // exits list is empty and the annotation degrades to v1.
    ref
        .read(motorwayExitsProvider.notifier)
        .ensureLoaded(ref.read(activeCountryProvider).code);
    final annotated = annotateStationsViaExits(
      stations: ranked,
      exits: ref.read(motorwayExitsProvider),
      lat: lat,
      lng: lng,
      headingDegrees: heading,
    );
    ref
        .read(highwayExitInfoMapProvider.notifier)
        .publish(annotated.infoByStationId);
    return annotated.stations;
  } catch (_) {
    // ignore: silent_catch — shell safety: an unwired graph keeps v1 order
    return ranked;
  }
}

/// #3633 — the radar's shared "rank, then exit-layer" step: the #3267
/// [RadarRanking] authority followed by [applyHighwayExitLayer], so
/// both radar publish paths (poll + republish) stay one call.
List<Station> rankWithExitLayer(
  Ref ref,
  Iterable<Station> raw, {
  required double lat,
  required double lng,
  required FuelType fuel,
  required ({bool active, double? heading, bool leftHand}) hw,
}) =>
    applyHighwayExitLayer(
      ref,
      RadarRanking.rank(raw,
          lat: lat,
          lng: lng,
          fuel: fuel,
          headingDegrees: hw.heading,
          highwayAheadOnly: hw.active,
          leftHandTraffic: hw.leftHand),
      lat,
      lng,
      hw,
    );

