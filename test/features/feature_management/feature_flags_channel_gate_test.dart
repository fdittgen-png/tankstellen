// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/data/feature_flags_repository.dart';
import 'package:tankstellen/features/feature_management/domain/build_channel.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/feature_management/domain/feature_manifest.dart';

/// Build-channel enforcement in `FeatureFlags` (#1674, epic #1670).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // A synthetic manifest exercising every channel shape:
  // - [everywhere]        — available + default-on in both channels.
  // - [betaOnly]          — exists in beta only.
  // - [perChannelDefault] — available in both channels but default-on
  //                         in beta only (opt-out in beta, opt-in in
  //                         production).
  const everywhere = Feature.priceAlerts;
  const betaOnly = Feature.gamification;
  const perChannelDefault = Feature.priceHistory;
  const manifest = FeatureManifest({
    everywhere: FeatureManifestEntry.allChannels(
      feature: everywhere,
      defaultOn: true,
      displayName: 'everywhere',
      description: 'available in every channel',
    ),
    betaOnly: FeatureManifestEntry(
      feature: betaOnly,
      availableChannels: {BuildChannel.beta},
      defaultEnabledChannels: {BuildChannel.beta},
      displayName: 'beta-only',
      description: 'available in beta only',
    ),
    perChannelDefault: FeatureManifestEntry(
      feature: perChannelDefault,
      availableChannels: {BuildChannel.production, BuildChannel.beta},
      defaultEnabledChannels: {BuildChannel.beta},
      displayName: 'per-channel-default',
      description: 'available in both channels, default-on in beta only',
    ),
  });

  ProviderContainer containerFor(
    BuildChannel channel, {
    FeatureFlagsRepository? repository,
  }) {
    final c = ProviderContainer(overrides: [
      featureManifestProvider.overrideWithValue(manifest),
      buildChannelProvider.overrideWithValue(channel),
      featureFlagsRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('buildChannelProvider defaults to production', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(buildChannelProvider), BuildChannel.production);
  });

  group('default set resolves per channel', () {
    test('a beta-only feature is force-off in a production build', () async {
      final c = containerFor(BuildChannel.production);
      await c.read(featureFlagsProvider.future);
      final enabled = c.read(enabledFeaturesProvider);
      expect(enabled, contains(everywhere));
      expect(enabled, isNot(contains(betaOnly)));
    });

    test('a beta-only feature is default-on in a beta build', () async {
      final c = containerFor(BuildChannel.beta);
      await c.read(featureFlagsProvider.future);
      final enabled = c.read(enabledFeaturesProvider);
      expect(enabled, containsAll(<Feature>{everywhere, betaOnly}));
    });
  });

  group('per-channel opt-in / opt-out defaults resolve through FeatureFlags',
      () {
    test('a both-channels feature is opt-in (default-off) in production',
        () async {
      final c = containerFor(BuildChannel.production);
      await c.read(featureFlagsProvider.future);
      expect(c.read(enabledFeaturesProvider),
          isNot(contains(perChannelDefault)));
    });

    test('the same feature is opt-out (default-on) in beta', () async {
      final c = containerFor(BuildChannel.beta);
      await c.read(featureFlagsProvider.future);
      expect(c.read(enabledFeaturesProvider), contains(perChannelDefault));
    });
  });

  group('enable() honours the channel gate', () {
    test('enabling a channel-unavailable feature throws', () async {
      final c = containerFor(BuildChannel.production);
      await c.read(featureFlagsProvider.future);
      expect(
        () => c.read(featureFlagsProvider.notifier).enable(betaOnly),
        throwsStateError,
      );
    });

    test('enabling an available feature succeeds in its channel', () async {
      final c = containerFor(BuildChannel.beta);
      await c.read(featureFlagsProvider.future);
      await c.read(featureFlagsProvider.notifier).enable(betaOnly);
      expect(c.read(featureFlagsProvider).asData?.value, contains(betaOnly));
    });
  });

  group('persisted channel-unavailable features are force-off on load', () {
    late Directory tmpDir;
    late Box<dynamic> box;

    setUp(() async {
      tmpDir = Directory.systemTemp.createTempSync('ff_channel_test_');
      Hive.init(tmpDir.path);
      box = await Hive.openBox<dynamic>(
        'ff_${DateTime.now().microsecondsSinceEpoch}',
      );
    });

    tearDown(() async {
      await box.deleteFromDisk();
      await Hive.close();
      tmpDir.deleteSync(recursive: true);
    });

    test('a persisted beta-only feature is dropped in a production build',
        () async {
      // Box persists the beta-only feature as enabled.
      await box.put(betaOnly.name, true);
      final c = containerFor(
        BuildChannel.production,
        repository: FeatureFlagsRepository(box: box, manifest: manifest),
      );
      final state = await c.read(featureFlagsProvider.future);
      expect(state, isNot(contains(betaOnly)));
    });
  });
}
