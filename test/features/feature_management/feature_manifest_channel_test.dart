// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/feature_management/domain/build_channel.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/feature_management/domain/feature_manifest.dart';

/// Build-channel availability + per-channel defaults on
/// `FeatureManifestEntry` (#1670 / #1673).
void main() {
  group('FeatureManifestEntry.allChannels', () {
    test('is available in every channel', () {
      const entry = FeatureManifestEntry.allChannels(
        feature: Feature.priceAlerts,
        defaultOn: true,
        displayName: 'x',
        description: 'x',
      );
      expect(entry.isAvailableIn(BuildChannel.production), isTrue);
      expect(entry.isAvailableIn(BuildChannel.beta), isTrue);
    });

    test('defaultOn:true defaults enabled in every channel', () {
      const entry = FeatureManifestEntry.allChannels(
        feature: Feature.priceAlerts,
        defaultOn: true,
        displayName: 'x',
        description: 'x',
      );
      expect(entry.defaultEnabledIn(BuildChannel.production), isTrue);
      expect(entry.defaultEnabledIn(BuildChannel.beta), isTrue);
    });

    test('defaultOn:false defaults disabled in every channel', () {
      const entry = FeatureManifestEntry.allChannels(
        feature: Feature.priceAlerts,
        defaultOn: false,
        displayName: 'x',
        description: 'x',
      );
      expect(entry.defaultEnabledIn(BuildChannel.production), isFalse);
      expect(entry.defaultEnabledIn(BuildChannel.beta), isFalse);
    });
  });

  group('per-channel availability + defaults', () {
    test('a beta-only feature is unavailable in production', () {
      const entry = FeatureManifestEntry(
        feature: Feature.hapticEcoCoach,
        availableChannels: {BuildChannel.beta},
        defaultEnabledChannels: {BuildChannel.beta},
        displayName: 'x',
        description: 'x',
      );
      expect(entry.isAvailableIn(BuildChannel.beta), isTrue);
      expect(entry.isAvailableIn(BuildChannel.production), isFalse);
      expect(entry.defaultEnabledIn(BuildChannel.beta), isTrue);
      expect(entry.defaultEnabledIn(BuildChannel.production), isFalse);
    });

    test('a feature can be opt-out in beta and opt-in in production', () {
      const entry = FeatureManifestEntry(
        feature: Feature.hapticEcoCoach,
        availableChannels: {BuildChannel.production, BuildChannel.beta},
        defaultEnabledChannels: {BuildChannel.beta},
        displayName: 'x',
        description: 'x',
      );
      expect(entry.defaultEnabledIn(BuildChannel.beta), isTrue);
      expect(entry.defaultEnabledIn(BuildChannel.production), isFalse);
    });
  });

  group('FeatureManifest.defaultEnabledSet', () {
    const manifest = FeatureManifest({
      Feature.priceAlerts: FeatureManifestEntry(
        feature: Feature.priceAlerts,
        availableChannels: {BuildChannel.production, BuildChannel.beta},
        defaultEnabledChannels: {BuildChannel.production, BuildChannel.beta},
        displayName: 'always',
        description: 'on in both',
      ),
      Feature.hapticEcoCoach: FeatureManifestEntry(
        feature: Feature.hapticEcoCoach,
        availableChannels: {BuildChannel.production, BuildChannel.beta},
        defaultEnabledChannels: {BuildChannel.beta},
        displayName: 'beta-only-default',
        description: 'on in beta only',
      ),
    });

    test('resolves the default-on set for a given channel', () {
      expect(manifest.defaultEnabledSet(BuildChannel.production),
          {Feature.priceAlerts});
      expect(manifest.defaultEnabledSet(BuildChannel.beta),
          {Feature.priceAlerts, Feature.hapticEcoCoach});
    });

    test('no-arg defaults to the production channel', () {
      expect(manifest.defaultEnabledSet(),
          manifest.defaultEnabledSet(BuildChannel.production));
    });
  });

  group('FeatureManifest.defaultManifest', () {
    const manifest = FeatureManifest.defaultManifest;

    // #4212 — the ONE deliberate departure from the #1673 migration's
    // "everything, everywhere" snapshot: the fleet capabilities are
    // registered before the manager dashboard exists, so production must
    // not be able to switch them on at all (ADR 0025 D6 keeps the single
    // privacy-policy bump for that later slice). The set is listed here
    // rather than skipped, so widening it is a deliberate edit.
    const betaOnlyOnPurpose = <Feature>{
      Feature.fleetMode,
      Feature.fleetManagerTools,
    };

    test('every entry is available in beta, and in production too unless '
        'it is deliberately beta-only (#1673 migration, #4212)', () {
      for (final entry in manifest.entries.values) {
        expect(entry.isAvailableIn(BuildChannel.beta), isTrue,
            reason: '${entry.feature} must be available in beta');
        expect(entry.isAvailableIn(BuildChannel.production),
            !betaOnlyOnPurpose.contains(entry.feature),
            reason: '${entry.feature}: production availability must match '
                'the beta-only list above');
      }
    });

    test('production and beta default sets match — channel-agnostic '
        'defaults preserve pre-#1673 behaviour', () {
      expect(manifest.defaultEnabledSet(BuildChannel.production),
          manifest.defaultEnabledSet(BuildChannel.beta));
    });
  });
}
