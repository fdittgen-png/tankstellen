// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../domain/trajet_data_quality.dart';

/// Resolves the left-edge stripe colour for a trajet card (#2108
/// refinement of #2059).
///
/// The original #2059 bound the stripe to `Theme.colorScheme.primary`
/// (OBD2) vs `Theme.colorScheme.tertiary` (GPS-only). After the
/// forest-green Eco theme landed in #1757, both tokens collapsed
/// onto similar olive/brownish hues — making the two trip kinds
/// visually indistinguishable on the trajets list.
///
/// This module decouples the stripe colour from the generic theme
/// tokens. The semantic role is "trajet kind", not "tertiary
/// content"; other `tertiary` consumers can move independently.
///
/// The two colours are tuned to:
/// - read as visibly distinct at 4 dp width on both light and dark
///   surfaces;
/// - harmonise with the Eco theme's primary forest green (OBD2 uses
///   a slightly brighter shade so it lifts off the surface);
/// - keep the GPS-only/hybrid family on a calm muted blue that
///   contrasts cleanly against the green without screaming.
///
/// Pinned by `test/features/consumption/presentation/widgets/trajet_stripe_colors_test.dart`
/// — any future theme rework that touches these tokens must update
/// that test too so the visual-distinction guarantee survives.
class TrajetStripeColors {
  TrajetStripeColors._();

  /// OBD2-instrumented trajet — `TripKind.gpsPlusObd2`. Forest green
  /// that lifts off both light and dark surfaces.
  static const Color obd2Light = Color(0xFF2E7D32); // Material green 800
  static const Color obd2Dark = Color(0xFF66BB6A); // Material green 400

  /// GPS-only / hybrid trajet — `TripKind.gpsOnly` (and any kind that
  /// isn't fully OBD2-instrumented). Muted slate blue.
  static const Color gpsOnlyLight = Color(0xFF3A6EA5);
  static const Color gpsOnlyDark = Color(0xFF7BAEDF);

  /// OBD2 was attempted and did NOT deliver (#3835) — the adapter was
  /// there and the engine data is not. Red, because unlike the other two
  /// this state means something went wrong; it previously wore the same
  /// green as a clean recording.
  static const Color degradedLight = Color(0xFFC62828); // Material red 800
  static const Color degradedDark = Color(0xFFEF5350); // Material red 400

  /// Pick the stripe colour for a trajet's DELIVERED data quality at the
  /// current theme brightness.
  ///
  /// Keyed on [TrajetDataQuality] rather than `TripKind` (#3835): the kind
  /// records what was chosen at start, so a trip that began on the adapter
  /// and degraded to GPS kept the green stripe of a healthy recording.
  static Color forQuality(TrajetDataQuality quality, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    switch (quality) {
      case TrajetDataQuality.gpsOnly:
        return dark ? gpsOnlyDark : gpsOnlyLight;
      case TrajetDataQuality.obd2Healthy:
        return dark ? obd2Dark : obd2Light;
      case TrajetDataQuality.obd2Degraded:
        return dark ? degradedDark : degradedLight;
    }
  }
}
