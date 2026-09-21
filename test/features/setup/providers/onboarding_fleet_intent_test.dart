// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// #4217 — the fourth intent card. `applyProfileChoice` is the one place
// the preset bundle and the fleet flag are applied together, in that
// order: `select` REPLACES the enabled set, so enabling fleet mode
// first would silently lose it. The tests below pin that order, and the
// symmetric rule that going back to a personal card takes fleet mode
// away again — otherwise a user who changed their mind would keep the
// Settings → Fleet topic and the fleet wizard pages forever.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/feature_management/api.dart';
import 'package:tankstellen/features/feature_management/data/app_profile_repository.dart';
import 'package:tankstellen/features/setup/providers/onboarding_wizard_provider.dart';

void main() {
  ProviderContainer containerOn(BuildChannel channel) {
    final container = ProviderContainer(overrides: [
      buildChannelProvider.overrideWithValue(channel),
      appProfileRepositoryProvider.overrideWithValue(_MemoryProfileRepo()),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  test('a personal card records no fleet intent and picks its preset',
      () async {
    final container = containerOn(BuildChannel.beta);

    await container
        .read(onboardingWizardControllerProvider.notifier)
        .applyProfileChoice(AppProfile.full);

    expect(container.read(onboardingWizardControllerProvider).fleetIntent,
        isFalse);
    expect(container.read(activeAppProfileProvider), AppProfile.full);
    expect(container.read(enabledFeaturesProvider),
        isNot(contains(Feature.fleetMode)));
  });

  test('the fleet card picks the Medium preset and switches fleet mode on '
      'once its TankSync prerequisite is satisfied', () async {
    final container = containerOn(BuildChannel.beta);
    await container
        .read(featureFlagsProvider.notifier)
        .enable(Feature.tankSync);

    await container
        .read(onboardingWizardControllerProvider.notifier)
        .applyProfileChoice(AppProfile.medium, fleet: true);

    expect(container.read(onboardingWizardControllerProvider).fleetIntent,
        isTrue);
    expect(container.read(activeAppProfileProvider), AppProfile.medium);
    expect(container.read(enabledFeaturesProvider),
        contains(Feature.fleetMode));
  });

  test('the Medium bundle carries the TankSync prerequisite, so the fleet '
      'card works from a clean install', () async {
    final container = containerOn(BuildChannel.beta);

    await container
        .read(onboardingWizardControllerProvider.notifier)
        .applyProfileChoice(AppProfile.medium, fleet: true);

    expect(container.read(enabledFeaturesProvider),
        containsAll([Feature.tankSync, Feature.fleetMode]));
  });

  test('on production the flag can never be switched on (ADR 0025 D6) — '
      'and the intent survives, so the step that explains why is shown',
      () async {
    final container = containerOn(BuildChannel.production);
    await container
        .read(featureFlagsProvider.notifier)
        .enable(Feature.tankSync);

    await container
        .read(onboardingWizardControllerProvider.notifier)
        .applyProfileChoice(AppProfile.medium, fleet: true);

    expect(container.read(enabledFeaturesProvider),
        isNot(contains(Feature.fleetMode)));
    expect(container.read(onboardingWizardControllerProvider).fleetIntent,
        isTrue,
        reason: 'a missing capability must not silently drop the page '
            'that would have told the user about it');
  });

  test('picking a personal card after the fleet card undoes fleet mode',
      () async {
    final container = containerOn(BuildChannel.beta);
    final wizard = container.read(onboardingWizardControllerProvider.notifier);
    await container
        .read(featureFlagsProvider.notifier)
        .enable(Feature.tankSync);
    await wizard.applyProfileChoice(AppProfile.medium, fleet: true);
    expect(container.read(enabledFeaturesProvider),
        contains(Feature.fleetMode));

    await wizard.applyProfileChoice(AppProfile.basic);

    expect(container.read(onboardingWizardControllerProvider).fleetIntent,
        isFalse);
    expect(container.read(enabledFeaturesProvider),
        isNot(contains(Feature.fleetMode)));
  });
}

/// In-memory profile store — `select` persists through this.
class _MemoryProfileRepo implements AppProfileRepository {
  AppProfile? _stored;

  @override
  AppProfile? load() => _stored;

  @override
  Future<void> save(AppProfile profile) async => _stored = profile;

  @override
  bool get isEmpty => _stored == null;
}
