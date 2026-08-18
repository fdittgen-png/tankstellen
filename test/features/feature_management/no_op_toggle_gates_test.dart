// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/feature_management/domain/build_channel.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/feature_management/domain/feature_manifest.dart';

/// Pins the three formerly-no-op toggles that the 2026-08-17 review
/// (dead-code finding 6) found gating NOTHING, now wired to real
/// surfaces:
///
///  - `Feature.priceAlerts` — the station-detail create-alert action +
///    the `/alerts` route guard.
///  - `Feature.priceHistory` — the station-detail price-history
///    sections + the `/station/:id/history` route guard.
///  - `Feature.evCharging` — the EV chip in the fuel-type selector +
///    the `/ev-station` route guards.
///
/// All three shipped default-on for years, so the manifest MUST keep
/// them default-on — flipping a default would silently remove live
/// surfaces from every existing user.
void main() {
  const manifest = FeatureManifest.defaultManifest;

  for (final feature in [
    Feature.priceAlerts,
    Feature.priceHistory,
    Feature.evCharging,
  ]) {
    group('Feature.${feature.name} manifest entry', () {
      test('the default manifest declares an entry', () {
        final entry = manifest.entries[feature];
        expect(entry, isNotNull);
        expect(entry!.feature, feature);
      });

      test('is default-enabled — the newly-wired gates must not remove '
          'surfaces from existing users', () {
        expect(
          manifest.entries[feature]!.defaultEnabledIn(BuildChannel.production),
          isTrue,
        );
        expect(manifest.defaultEnabledSet(), contains(feature));
      });

      test('has no prerequisites — it depends on nothing', () {
        expect(manifest.entries[feature]!.requires, isEmpty);
      });
    });
  }
}
