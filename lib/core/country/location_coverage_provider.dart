// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'country_config.dart';
import 'country_detection_provider.dart';
import 'country_provider.dart';

part 'location_coverage_provider.g.dart';

/// #3361 — how the user's GPS-detected location relates to the app's data
/// coverage + their configuration. Two DISTINCT problems get two distinct
/// messages (and a third "nothing to say" pair):
enum LocationCoverageStatus {
  /// No country detected yet (no fix / permission denied) — say nothing, so
  /// the notice never flashes on a cold start.
  unknown,

  /// Detected country is supported AND the user's country is configured —
  /// everything is fine.
  ok,

  /// Detected country has NO fuel-price provider — technically out of
  /// coverage. The honest "not available in your region" message.
  unsupported,

  /// Detected country IS supported but the user never configured their
  /// country (no profile country, no saved setting) — so the app silently
  /// fell back to locale/Germany and shows the wrong country's prices. Prompt
  /// them to set their country instead of claiming "not available".
  needsProfile,
}

/// Classify the user's location coverage (#3361).
///
/// Splits the prior single "outside coverage" bool so a supported-but-
/// unconfigured user is told to set up their country, while only a truly
/// unsupported country gets the "not available" message.
@riverpod
LocationCoverageStatus locationCoverage(Ref ref) {
  final code = ref.watch(detectedCountryProvider);
  if (code == null || code.isEmpty) return LocationCoverageStatus.unknown;

  // Technically unsupported: no configured provider for this country.
  if (Countries.byCode(code) == null) return LocationCoverageStatus.unsupported;

  // Supported — but did the user actually configure their country, or did the
  // app fall back to locale/Germany? (The country↔profile read lives in
  // country_provider, so this classifier stays free of cross-feature imports.)
  return ref.watch(countryExplicitlyConfiguredProvider)
      ? LocationCoverageStatus.ok
      : LocationCoverageStatus.needsProfile;
}
