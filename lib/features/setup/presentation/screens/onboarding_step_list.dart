// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The onboarding wizard's step composition, as data (#4217).
///
/// The wizard used to hard-code "Vehicle is index 2, OBD2 is 3 or 4" in
/// getters that had to be re-derived by hand every time a step was
/// added or gated. #4217 adds two more conditional steps (the fleet
/// identity step and the privacy summary), which makes arithmetic
/// indices a bug waiting to happen: the screen now asks the built list
/// *where* a step is, and this file is the single place that decides
/// what the list contains and in what order.
///
/// Every step carries an [OnboardingStepId], so a lookup is a name, not
/// a number, and a step that is not in the current composition answers
/// `-1` exactly as the old getters did.
library;

import 'package:flutter/material.dart';

import '../widgets/api_key_step.dart';
import '../widgets/completion_step.dart';
import '../widgets/country_language_step.dart';
import '../widgets/fleet_identity_step.dart';
import '../widgets/landing_screen_step.dart';
import '../widgets/onboarding_ios_standby_step.dart';
import '../widgets/onboarding_obd2_step.dart';
import '../widgets/preferences_step.dart';
import '../widgets/privacy_summary_step.dart';
import '../widgets/profile_choice_step.dart';
import '../widgets/vehicles_step.dart';

/// Identity of a wizard page — what the screen looks steps up by.
enum OnboardingStepId {
  profileChoice,
  fleetIdentity,
  countryLanguage,
  vehicles,
  iosStandby,
  obd2,
  preferences,
  landingScreen,
  apiKey,
  privacySummary,
  completion,
}

/// One page of the wizard: its identity and the widget that renders it.
class OnboardingStep {
  const OnboardingStep(this.id, this.child);

  final OnboardingStepId id;
  final Widget child;
}

/// Builds the ordered page list for the current profile, platform,
/// country and fleet intent.
///
/// | Step | Basic | Medium | Full | + fleet |
/// | --- | :-: | :-: | :-: | :-: |
/// | Profile choice | ✓ | ✓ | ✓ | ✓ |
/// | Fleet identity | — | — | — | ✓ |
/// | Country & language | ✓ | ✓ | ✓ | ✓ |
/// | Vehicle | — | ✓ | ✓ | ✓ |
/// | iOS standby explainer | — | — | iOS | iOS |
/// | OBD2 adapter | — | — | ✓ | cond |
/// | Preferences · Landing screen | ✓ | ✓ | ✓ | ✓ |
/// | API key | cond | cond | cond | cond |
/// | Privacy summary | — | — | — | ✓ |
/// | Done | ✓ | ✓ | ✓ | ✓ |
///
/// The fleet pages are the only fleet-visible change to onboarding: a
/// personal user's page list is byte-for-byte what it was before #4217.
List<OnboardingStep> buildOnboardingSteps({
  required bool showFleet,
  required bool showVehicle,
  required bool showIosStandby,
  required bool showObd2,
  required bool requiresApiKey,
  required VoidCallback onProfilePicked,
  required VoidCallback onObd2Proceed,
  required VoidCallback onObd2AutoFillSuccess,
  required TextEditingController apiKeyController,
  required VoidCallback onUseDemoData,
}) {
  return [
    OnboardingStep(
      OnboardingStepId.profileChoice,
      ProfileChoiceStep(onProfilePicked: onProfilePicked),
    ),
    if (showFleet)
      const OnboardingStep(
        OnboardingStepId.fleetIdentity,
        FleetIdentityStep(),
      ),
    const OnboardingStep(
      OnboardingStepId.countryLanguage,
      CountryLanguageStep(),
    ),
    if (showVehicle)
      const OnboardingStep(OnboardingStepId.vehicles, VehiclesStep()),
    if (showIosStandby)
      const OnboardingStep(
        OnboardingStepId.iosStandby,
        OnboardingIosStandbyStep(),
      ),
    if (showObd2)
      OnboardingStep(
        OnboardingStepId.obd2,
        OnboardingObd2Step(
          onProceed: onObd2Proceed,
          onAutoFillSuccess: onObd2AutoFillSuccess,
        ),
      ),
    const OnboardingStep(OnboardingStepId.preferences, PreferencesStep()),
    const OnboardingStep(
      OnboardingStepId.landingScreen,
      LandingScreenStep(),
    ),
    if (requiresApiKey)
      OnboardingStep(
        OnboardingStepId.apiKey,
        ApiKeyStep(
          apiKeyController: apiKeyController,
          onUseDemoData: onUseDemoData,
        ),
      ),
    if (showFleet)
      const OnboardingStep(
        OnboardingStepId.privacySummary,
        PrivacySummaryStep(),
      ),
    const OnboardingStep(OnboardingStepId.completion, CompletionStep()),
  ];
}

/// Zero-based position of [id] in [steps], or `-1` when the current
/// composition does not include it.
int indexOfStep(List<OnboardingStep> steps, OnboardingStepId id) {
  for (var i = 0; i < steps.length; i++) {
    if (steps[i].id == id) return i;
  }
  return -1;
}
