// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/build_channel.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/feature_management/domain/feature_activation_preview.dart';
import 'package:tankstellen/features/feature_management/domain/feature_dependency_graph.dart';
import 'package:tankstellen/features/feature_management/domain/feature_manifest.dart';

import 'workflow_test_repository.dart';

void main() {
  late WorkflowTestRepository repo;
  late ProviderContainer container;
  const manifest = FeatureManifest.defaultManifest;
  setUp(() {
    repo = WorkflowTestRepository({Feature.gpsTripPath, Feature.autoRecord});
    container = ProviderContainer(
      overrides: [
        featureFlagsRepositoryProvider.overrideWithValue(repo),
        buildChannelProvider.overrideWithValue(BuildChannel.production),
      ],
    );
  });
  tearDown(() => container.dispose());

  Future<FeatureActivationPreview> preview() async =>
      FeatureActivationPreview.resolve(
        target: Feature.showConsumptionTab,
        manifest: manifest,
        channel: BuildChannel.production,
        enabled: await container.read(featureFlagsProvider.future),
      )!;

  test(
    'preview includes dormant dependents and applies one durable write',
    () async {
      final plan = await preview();
      expect(plan.required, {
        Feature.showConsumptionTab,
        Feature.obd2TripRecording,
      });
      expect(plan.activated, containsAll([Feature.gpsTripPath, Feature.autoRecord]));
      expect(repo.writes, 0);
      final flags = container.read(featureFlagsProvider.notifier);
      expect(await flags.activateReviewed(plan), isTrue);
      expect(repo.writes, 1);
      expect(repo.stored, containsAll(plan.required));
      expect(
        isEffectivelyEnabled(Feature.gpsTripPath, manifest, repo.stored),
        isTrue,
      );
      await flags.disable(Feature.obd2TripRecording);
      expect(repo.stored, contains(Feature.gpsTripPath));
      expect(
        isEffectivelyEnabled(Feature.gpsTripPath, manifest, repo.stored),
        isFalse,
      );
    },
  );

  test(
    'concurrent change invalidates confirmation without overwriting it',
    () async {
      final plan = await preview();
      final flags = container.read(featureFlagsProvider.notifier);
      final change = flags.enable(Feature.showFuel);
      final apply = flags.activateReviewed(plan);
      await change;
      expect(await apply, isFalse);
      expect(repo.stored, {Feature.gpsTripPath, Feature.autoRecord, Feature.showFuel});
      expect(repo.writes, 1);
    },
  );

  test('failed persistence publishes nothing and retry can succeed', () async {
    final plan = await preview();
    final flags = container.read(featureFlagsProvider.notifier);
    repo.fail = true;
    await expectLater(flags.activateReviewed(plan), throwsException);
    expect(await container.read(featureFlagsProvider.future), plan.before);
    expect(repo.stored, plan.before);
    repo.fail = false;
    expect(await flags.activateReviewed(plan), isTrue);
  });

  test('unavailable prerequisite prevents the whole activation', () {
    final entries = {...manifest.entries};
    entries[Feature.obd2TripRecording] = const FeatureManifestEntry(
      feature: Feature.obd2TripRecording,
      availableChannels: {BuildChannel.beta},
      displayName: 'fixture',
      description: 'fixture',
    );
    expect(
      FeatureActivationPreview.resolve(
        target: Feature.showConsumptionTab,
        manifest: FeatureManifest(entries),
        channel: BuildChannel.production,
        enabled: {},
      ),
      isNull,
    );
  });
}
