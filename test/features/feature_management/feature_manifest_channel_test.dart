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
        feature: Feature.gamification,
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
        feature: Feature.gamification,
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
      Feature.gamification: FeatureManifestEntry(
        feature: Feature.gamification,
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
          {Feature.priceAlerts, Feature.gamification});
    });

    test('no-arg defaults to the production channel', () {
      expect(manifest.defaultEnabledSet(),
          manifest.defaultEnabledSet(BuildChannel.production));
    });
  });

  group('FeatureManifest.defaultManifest', () {
    const manifest = FeatureManifest.defaultManifest;

    test('every entry is available in both channels (#1673 migration)', () {
      for (final entry in manifest.entries.values) {
        expect(entry.isAvailableIn(BuildChannel.production), isTrue,
            reason: '${entry.feature} must be available in production');
        expect(entry.isAvailableIn(BuildChannel.beta), isTrue,
            reason: '${entry.feature} must be available in beta');
      }
    });

    test('production and beta default sets match — channel-agnostic '
        'defaults preserve pre-#1673 behaviour', () {
      expect(manifest.defaultEnabledSet(BuildChannel.production),
          manifest.defaultEnabledSet(BuildChannel.beta));
    });
  });
}
