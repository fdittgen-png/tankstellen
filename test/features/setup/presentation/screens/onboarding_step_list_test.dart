// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// #4217 — the wizard's step indices used to be arithmetic ("Vehicle is
// index 2, OBD2 is 3 or 4 depending on the platform"). Two conditional
// fleet pages break every one of those numbers, so the screen now looks
// steps up by name. These tests are the pin: each case states a
// composition and the positions it must produce, so a future step
// inserted in the middle fails here rather than silently sending the
// OBD2 skip button to the Preferences page.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/setup/presentation/screens/onboarding_step_list.dart';

void main() {
  late TextEditingController apiKey;

  setUp(() => apiKey = TextEditingController());
  tearDown(() => apiKey.dispose());

  List<OnboardingStepId> compose({
    bool showFleet = false,
    bool showVehicle = false,
    bool showIosStandby = false,
    bool showObd2 = false,
    bool requiresApiKey = false,
  }) =>
      buildOnboardingSteps(
        showFleet: showFleet,
        showVehicle: showVehicle,
        showIosStandby: showIosStandby,
        showObd2: showObd2,
        requiresApiKey: requiresApiKey,
        onProfilePicked: () {},
        onObd2Proceed: () {},
        onObd2AutoFillSuccess: () {},
        apiKeyController: apiKey,
        onUseDemoData: () {},
      ).map((s) => s.id).toList();

  group('composition', () {
    test('a Basic personal user gets the pre-#4217 five pages', () {
      expect(
        compose(),
        [
          OnboardingStepId.profileChoice,
          OnboardingStepId.countryLanguage,
          OnboardingStepId.preferences,
          OnboardingStepId.landingScreen,
          OnboardingStepId.completion,
        ],
      );
    });

    test('a Full personal user on iOS with an API-key country is '
        'unchanged by the fleet slice', () {
      expect(
        compose(
          showVehicle: true,
          showIosStandby: true,
          showObd2: true,
          requiresApiKey: true,
        ),
        [
          OnboardingStepId.profileChoice,
          OnboardingStepId.countryLanguage,
          OnboardingStepId.vehicles,
          OnboardingStepId.iosStandby,
          OnboardingStepId.obd2,
          OnboardingStepId.preferences,
          OnboardingStepId.landingScreen,
          OnboardingStepId.apiKey,
          OnboardingStepId.completion,
        ],
      );
    });

    test('a personal user never gets a fleet page, whatever else is on',
        () {
      final ids = compose(
        showVehicle: true,
        showObd2: true,
        requiresApiKey: true,
      );
      expect(ids, isNot(contains(OnboardingStepId.fleetIdentity)));
      expect(ids, isNot(contains(OnboardingStepId.privacySummary)));
    });

    test('fleet identity sits right after the intent card, and the '
        'privacy summary right before Done', () {
      final ids = compose(showFleet: true, showVehicle: true);
      expect(ids, [
        OnboardingStepId.profileChoice,
        OnboardingStepId.fleetIdentity,
        OnboardingStepId.countryLanguage,
        OnboardingStepId.vehicles,
        OnboardingStepId.preferences,
        OnboardingStepId.landingScreen,
        OnboardingStepId.privacySummary,
        OnboardingStepId.completion,
      ]);
    });
  });

  group('lookups', () {
    test('Vehicle moves from 2 to 3 when the fleet page is inserted — the '
        'exact drift a hard-coded index would have missed', () {
      final personal = compose(showVehicle: true);
      final fleet = compose(showFleet: true, showVehicle: true);

      expect(indexOfStep(_steps(personal), OnboardingStepId.vehicles), 2);
      expect(indexOfStep(_steps(fleet), OnboardingStepId.vehicles), 3);
    });

    test('OBD2 absorbs both the iOS explainer and the fleet page', () {
      expect(
        indexOfStep(
          _steps(compose(showVehicle: true, showObd2: true)),
          OnboardingStepId.obd2,
        ),
        3,
      );
      expect(
        indexOfStep(
          _steps(compose(
            showVehicle: true,
            showIosStandby: true,
            showObd2: true,
          )),
          OnboardingStepId.obd2,
        ),
        4,
      );
      expect(
        indexOfStep(
          _steps(compose(
            showFleet: true,
            showVehicle: true,
            showIosStandby: true,
            showObd2: true,
          )),
          OnboardingStepId.obd2,
        ),
        5,
      );
    });

    test('the API-key page is no longer "one before the end" for a fleet '
        'user — the privacy summary sits between it and Done', () {
      final ids = compose(showFleet: true, requiresApiKey: true);
      final steps = _steps(ids);

      expect(indexOfStep(steps, OnboardingStepId.apiKey), ids.length - 3);
      expect(
        indexOfStep(steps, OnboardingStepId.completion),
        ids.length - 1,
      );
    });

    test('a step outside the composition answers -1, as the old getters '
        'did', () {
      final steps = _steps(compose());
      expect(indexOfStep(steps, OnboardingStepId.vehicles), -1);
      expect(indexOfStep(steps, OnboardingStepId.obd2), -1);
      expect(indexOfStep(steps, OnboardingStepId.apiKey), -1);
      expect(indexOfStep(steps, OnboardingStepId.fleetIdentity), -1);
    });
  });
}

/// Rebuilds a lookup-able list from a bare id sequence — the widgets
/// are irrelevant to an index.
List<OnboardingStep> _steps(List<OnboardingStepId> ids) =>
    [for (final id in ids) OnboardingStep(id, const SizedBox.shrink())];
