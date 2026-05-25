// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/country/country_provider.dart';
import '../../../../core/language/language_provider.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feature_management/application/app_profile_provider.dart';
import '../../../feature_management/domain/app_profile.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../providers/api_key_validator_provider.dart';
import '../../providers/onboarding_wizard_provider.dart';
import '../widgets/api_key_step.dart';
import '../widgets/completion_step.dart';
import '../widgets/country_language_step.dart';
import '../widgets/landing_screen_step.dart';
import '../widgets/onboarding_ios_standby_step.dart';
import '../widgets/onboarding_navigation_buttons.dart';
import '../widgets/onboarding_obd2_step.dart';
import '../widgets/onboarding_progress_indicator.dart';
import '../widgets/preferences_step.dart';
import '../widgets/profile_choice_step.dart';
import '../widgets/vehicles_step.dart';

/// Multi-step onboarding wizard with progress indicator.
///
/// Step layout depends on the user's [AppProfile] choice on the first
/// page (#1517 / #1518):
///
/// | Step | Basic | Medium | Full |
/// | --- | :-: | :-: | :-: |
/// | 0 — Profile choice (Welcome + Sparkilo brand + 3 cards) | ✓ | ✓ | ✓ |
/// | 1 — Country & Language | ✓ | ✓ | ✓ |
/// | 2 — Vehicle | — | ✓ | ✓ |
/// | 3 — OBD2 adapter (paired with the vehicle from step 2) | — | — | ✓ |
/// | 4 — Preferences | ✓ | ✓ | ✓ |
/// | 5 — Landing screen | ✓ | ✓ | ✓ |
/// | 6 — API key (only if country requires) | cond | cond | cond |
/// | 7 — Done | ✓ | ✓ | ✓ |
///
/// Vehicle is shown for Medium because manual fill-up logging needs a
/// vehicle to attach to. OBD2 is Full only because the rest of the
/// OBD2 stack (auto-record, gamification, consumption analytics) is
/// also Full-only.
///
/// Wizard progress and loading flag live in
/// [onboardingWizardControllerProvider]; the API-key [TextEditingController]
/// and the [PageController] remain local because they must follow the
/// Flutter widget lifecycle.
class OnboardingWizardScreen extends ConsumerStatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  ConsumerState<OnboardingWizardScreen> createState() =>
      _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState
    extends ConsumerState<OnboardingWizardScreen> {
  final _pageController = PageController();
  final _apiKeyController = TextEditingController();

  /// Returns the total number of steps based on profile + API-key need.
  /// Always derived from `_buildSteps().length` so changing step
  /// composition (e.g. profile-driven inclusion) updates step counts
  /// automatically.
  int get _stepCount => _buildSteps().length;

  /// Zero-based index of the Vehicles step under the active profile,
  /// or -1 when the profile doesn't include it (Basic).
  int get _vehiclesStepIndex {
    final profile = ref.read(activeAppProfileProvider);
    if (profile == AppProfile.basic || profile == null) return -1;
    return 2; // Welcome+Profile (0), Country (1), Vehicle (2)
  }

  /// Zero-based index of the OBD2 adapter step under the active
  /// profile, or -1 when the profile doesn't include it
  /// (Basic + Medium). On iOS the index shifts by one because the
  /// iOS-only standby explainer (#1542 phase 6) sits between Vehicle
  /// and OBD2.
  int get _obd2StepIndex {
    final profile = ref.read(activeAppProfileProvider);
    if (profile != AppProfile.full && profile != AppProfile.custom) return -1;
    // Welcome+Profile (0), Country (1), Vehicle (2), [iOS standby (3)],
    // OBD2 (3 or 4 depending on platform).
    return defaultTargetPlatform == TargetPlatform.iOS ? 4 : 3;
  }

  /// Zero-based index of the optional API key step.
  int get _apiKeyStepIndex {
    final country = ref.read(activeCountryProvider);
    if (!country.requiresApiKey) return -1;
    // API-key sits just before the Done step. Compute it relative to
    // _stepCount so we don't drift when other steps come and go.
    return _stepCount - 2;
  }

  bool _isLastStep(int currentStep) => currentStep == _stepCount - 1;

  @override
  void dispose() {
    _pageController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    ref.read(onboardingWizardControllerProvider.notifier).setStep(step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _next(int currentStep) {
    // Step 0 (ProfileChoiceStep) advances itself via `onProfilePicked`
    // once the user taps a card. If they hit the wizard's "Next" button
    // without picking, refuse with a hint — otherwise the wizard would
    // enter the next step with a null `activeAppProfileProvider`.
    if (currentStep == 0 &&
        ref.read(activeAppProfileProvider) == null) {
      SnackBarHelper.showError(
        context,
        AppLocalizations.of(context)?.onboardingPickUseMode ??
            'Pick a use mode to continue.',
      );
      return;
    }
    if (_isLastStep(currentStep)) {
      _finishOnboarding();
    } else {
      _goToStep(currentStep + 1);
    }
  }

  void _back(int currentStep) {
    if (currentStep > 0) {
      _goToStep(currentStep - 1);
    }
  }

  /// Skips the current step (for optional steps like API key).
  void _skip(int currentStep) {
    if (!_isLastStep(currentStep)) {
      _goToStep(currentStep + 1);
    }
  }

  Future<void> _finishOnboarding() async {
    final country = ref.read(activeCountryProvider);

    // If there's an API key, validate it first
    if (country.requiresApiKey) {
      final apiKey = _apiKeyController.text.trim();
      if (apiKey.isNotEmpty) {
        final success = await _validateAndSaveKey(apiKey);
        if (!success) return;
      }
    }

    await _completeSetup();
  }

  Future<bool> _validateAndSaveKey(String apiKey) async {
    final ctrl = ref.read(onboardingWizardControllerProvider.notifier);
    ctrl.setLoading(true);
    try {
      final validator = ref.read(apiKeyValidatorProvider);
      final result = await validator.validate(apiKey);
      if (!result.isValid) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          SnackBarHelper.showError(context, l10n?.invalidApiKey(result.errorMessage ?? '') ?? 'Invalid API key: ${result.errorMessage}');
        }
        return false;
      }
      final apiKeys = ref.read(apiKeyStorageProvider);
      await apiKeys.setApiKey(apiKey);
      return true;
    } finally {
      if (mounted) ctrl.setLoading(false);
    }
  }

  Future<void> _completeSetup() async {
    final ctrl = ref.read(onboardingWizardControllerProvider.notifier);
    ctrl.setLoading(true);
    try {
      final settings = ref.read(settingsStorageProvider);
      await settings.skipSetup();

      final country = ref.read(activeCountryProvider);
      final language = ref.read(activeLanguageProvider);
      final wizardState = ref.read(onboardingWizardControllerProvider);

      final profileRepo = ref.read(profileRepositoryProvider);
      final profile = await profileRepo.ensureDefaultProfile();

      final updated = profile.copyWith(
        countryCode: country.code,
        languageCode: language.code,
        homeZipCode: wizardState.homeZipCode,
        defaultSearchRadius: wizardState.defaultSearchRadius,
        preferredFuelType: wizardState.preferredFuelType,
        landingScreen: wizardState.landingScreen,
      );
      await profileRepo.updateProfile(updated);
      ref.read(activeProfileProvider.notifier).refresh();

      if (mounted) context.go('/');
    } finally {
      if (mounted) ctrl.setLoading(false);
    }
  }

  /// Returns whether the current step is an optional one that can be skipped.
  bool _isCurrentStepSkippable(int currentStep) {
    // OBD2 + Vehicles are always skippable when shown; API key is
    // skippable when it shows. The OBD2 step owns its own skip button,
    // but surfacing the wizard's "Skip" too keeps the UX consistent
    // with the rest of the optional steps.
    if (_obd2StepIndex != -1 && currentStep == _obd2StepIndex) return true;
    if (_vehiclesStepIndex != -1 && currentStep == _vehiclesStepIndex) {
      return true;
    }
    return _apiKeyStepIndex != -1 && currentStep == _apiKeyStepIndex;
  }

  /// Advance past the OBD2 step in response to skip / partial decode /
  /// VIN read failure. The OBD2 step is now AFTER Vehicle (#1518), so
  /// failure cases hand control to the next step (Preferences).
  void _advanceFromObd2() {
    if (_obd2StepIndex == -1) return; // OBD2 not in the active profile
    _goToStep(_obd2StepIndex + 1);
  }

  /// Successful OBD2-driven auto-fill (#816). With Vehicle now BEFORE
  /// OBD2 (#1518), the auto-fill writes the decoded VIN data onto the
  /// vehicle the user already created, then advances to the next step
  /// after OBD2 (Preferences).
  void _advanceAfterObd2AutoFill() {
    if (_obd2StepIndex == -1) return;
    _goToStep(_obd2StepIndex + 1);
  }

  /// Picks a profile from step 0 and advances to step 1.
  void _onProfilePicked() {
    _goToStep(1);
  }

  List<Widget> _buildSteps() {
    final country = ref.watch(activeCountryProvider);
    final profile = ref.watch(activeAppProfileProvider);
    final showVehicle =
        profile == AppProfile.medium ||
            profile == AppProfile.full ||
            profile == AppProfile.custom;
    final showObd2 = profile == AppProfile.full || profile == AppProfile.custom;
    // #1542 phase 6 — on iOS, prepend an explainer step before the
    // OBD2 pairing so the user understands the three iOS-only
    // compromises (open once after reboot, don't force-quit, grant
    // Always location). Same gating as `showObd2`: an iOS user who
    // skipped OBD2 doesn't need to be warned about a flow they're
    // not setting up.
    final showIosStandby = showObd2 &&
        defaultTargetPlatform == TargetPlatform.iOS;
    return [
      ProfileChoiceStep(onProfilePicked: _onProfilePicked),
      const CountryLanguageStep(),
      if (showVehicle) const VehiclesStep(),
      if (showIosStandby) const OnboardingIosStandbyStep(),
      if (showObd2)
        OnboardingObd2Step(
          onProceed: _advanceFromObd2,
          onAutoFillSuccess: _advanceAfterObd2AutoFill,
        ),
      const PreferencesStep(),
      const LandingScreenStep(),
      if (country.requiresApiKey)
        ApiKeyStep(
          apiKeyController: _apiKeyController,
          onUseDemoData: () {
            _apiKeyController.clear();
            _skip(_apiKeyStepIndex);
          },
        ),
      const CompletionStep(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Watch country to rebuild when it changes (affects step count).
    ref.watch(activeCountryProvider);
    final wizardState = ref.watch(onboardingWizardControllerProvider);
    final currentStep = wizardState.currentStep;
    final isLoading = wizardState.isLoading;
    final steps = _buildSteps();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Progress indicator
            OnboardingProgressIndicator(
              currentStep: currentStep,
              stepCount: _stepCount,
            ),
            const SizedBox(height: 8),
            // Step counter text
            Text(
              '${currentStep + 1} / $_stepCount',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  ref
                      .read(onboardingWizardControllerProvider.notifier)
                      .setStep(index);
                },
                children: steps,
              ),
            ),
            // Navigation buttons
            OnboardingNavigationButtons(
              currentStep: currentStep,
              isLoading: isLoading,
              isLastStep: _isLastStep(currentStep),
              isSkippable: _isCurrentStepSkippable(currentStep),
              onBack: () => _back(currentStep),
              onNext: () => _next(currentStep),
              onSkip: () => _skip(currentStep),
            ),
          ],
        ),
      ),
    );
  }
}
