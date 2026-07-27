// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/country/country_provider.dart';
import '../../../core/services/radar/highway_mode.dart';
import '../../../core/services/radar/highway_mode_provider.dart';
import '../../../core/utils/geo_utils.dart' as geo;

/// #3631 — the highway ahead-filter arguments for the shared ranking:
/// active verdict + the freshest sanitized course + the active country's
/// driving side. Falls back to inactive on any read fault (shell safety
/// — ranking must never fail because a provider isn't up). Extracted
/// from `radar_search_provider.dart` for the 400-line guard (#3634).
({bool active, double? heading, bool leftHand}) highwayRankArgs(
  Ref ref,
  Position? lastFix,
) {
  try {
    final active = ref.read(highwayModeProvider);
    final heading = geo.sanitizedHeading(lastFix?.heading);
    final leftHand = kLeftHandTrafficCountries
        .contains(ref.read(activeCountryProvider).code.toUpperCase());
    return (active: active, heading: heading, leftHand: leftHand);
  } catch (_) {
    // ignore: silent_catch — shell safety: rank args degrade to mode-off
    return (active: false, heading: null, leftHand: false);
  }
}
