// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/feature_management/domain/build_channel.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/feature_management/domain/feature_manifest.dart';

/// Feature-manifest completeness invariants (epic #1613, child #1639).
///
/// Adding a value to the `Feature` enum without a matching
/// `FeatureManifestEntry` would let the feature exist with no
/// default-enabled state, display name or dependency edges — a silent
/// gap. This test makes that gap a CI failure, and pins the #1613 gates
/// (`fuelCalculator`, `carbonDashboard`) and their dependency edges.
void main() {
  const manifest = FeatureManifest.defaultManifest;

  test('every Feature enum value has a default-manifest entry', () {
    final missing = Feature.values
        .where((f) => manifest.entries[f] == null)
        .toList();
    expect(missing, isEmpty,
        reason: 'every Feature must have a FeatureManifestEntry — add one '
            'to FeatureManifest.defaultManifest for: $missing');
  });

  test('every manifest entry is keyed by its own feature', () {
    for (final entry in manifest.entries.entries) {
      expect(entry.value.feature, entry.key,
          reason: 'manifest map key ${entry.key} must match entry.feature');
    }
  });

  test('every requires-edge points at a feature that exists in the manifest',
      () {
    for (final entry in manifest.entries.values) {
      for (final dep in entry.requires) {
        expect(manifest.entries[dep], isNotNull,
            reason: '${entry.feature} requires $dep, which has no manifest '
                'entry');
      }
    }
  });

  group('#1613 gates', () {
    test('fuelCalculator and carbonDashboard are present and default-on', () {
      for (final f in [Feature.fuelCalculator, Feature.carbonDashboard]) {
        final entry = manifest.entries[f];
        expect(entry, isNotNull, reason: '$f must be in the manifest');
        expect(entry!.defaultEnabledIn(BuildChannel.production), isTrue,
            reason: '$f ships default-on so the surface stays reachable');
        expect(entry.requires, isEmpty,
            reason: '$f has no prerequisites');
      }
    });
  });

  group('#1981 — GPS trip path default-on', () {
    test('gpsTripPath ships default-on so trip consumption uses the '
        'accurate GPS-track distance', () {
      final entry = manifest.entries[Feature.gpsTripPath];
      expect(entry, isNotNull);
      expect(entry!.defaultEnabledIn(BuildChannel.production), isTrue,
          reason: 'a GPS track gives true road distance (#1979/#1981); '
              'without it the speed-sensor virtual odometer over-reads');
      expect(entry.requires, contains(Feature.obd2TripRecording),
          reason: 'GPS trip path only matters once trips are recorded');
    });
  });
}
