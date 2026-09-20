// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/country/country_provider.dart';
import '../../../../core/language/language_provider.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feature_management/application/app_profile_provider.dart';
import '../../../feature_management/domain/app_profile.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../providers/api_key_validator_provider.dart';
import '../../providers/onboarding_platform_steps_provider.dart';
import '../../providers/onboarding_wizard_provider.dart';
import '../widgets/onboarding_navigation_buttons.dart';
import '../widgets/onboarding_progress_indicator.dart';
import 'onboarding_step_list.dart';
import '../../../../core/widgets/page_scaffold.dart';

/// Multi-step onboarding wizard with progress indicator.
///
/// Step layout depends on the user's [AppProfile] choice on the first
/// page (#1517 / #1518):
///
/// The composition itself lives in `onboarding_step_list.dart`
/// ([buildOnboardingSteps]) — see its table for which page appears
/// under which profile. Vehicle is shown for Medium because manual
/// fill-up logging needs a vehicle to attach to; OBD2 is Full only
/// because the rest of the OBD2 stack (auto-record, consumption
/// analytics) is also Full-only.
///
/// #4217 — the per-step indices below are **lookups into the built
/// list**, not arithmetic. Two conditional fleet pages now sit before
/// Vehicle and before Done, so any hard-coded "Vehicle is index 2"
/// would be wrong for a fleet driver.
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

  /// Zero-based index of [id] in the current composition, or -1 when
  /// this profile / platform / country does not include that step.
  int _indexOf(OnboardingStepId id) => indexOfStep(_buildSteps(), id);

  /// Zero-based index of the Vehicles step, or -1 (Basic).
  int get _vehiclesStepIndex => _indexOf(OnboardingStepId.vehicles);

  /// Zero-based index of the OBD2 adapter step, or -1 (Basic +
  /// Medium). On iOS the iOS-only standby explainer (#1542 phase 6)
  /// sits between Vehicle and OBD2 — the lookup absorbs that, and the
  /// fleet identity page, without arithmetic.
  int get _obd2StepIndex => _indexOf(OnboardingStepId.obd2);

  /// Zero-based index of the optional API key step, or -1.
  int get _apiKeyStepIndex => _indexOf(OnboardingStepId.apiKey);

  bool _isLastStep(int currentStep) => currentStep == _stepCount - 1;

  @override
  void dispose() {
    _pageController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    ref.read(onboardingWizardControllerProvider.notifier).setStep(step);
    unawaited(
      _pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
  }

  void _next(int currentStep) {
    // Step 0 (ProfileChoiceStep) advances itself via `onProfilePicked`
    // once the user taps a card. If they hit the wizard's "Next" button
    // without picking, refuse with a hint — otherwise the wizard would
    // enter the next step with a null `activeAppProfileProvider`.
    // #3987 — no error SnackBar: the Next button is disabled with the
    // reason shown beside it while no use mode is picked. This guard only
    // covers a programmatic call; the button cannot fire in that state.
    if (_nextDisabledReason(currentStep, AppLocalizations.of(context)) !=
        null) {
      return;
    }
    if (_isLastStep(currentStep)) {
      unawaited(_finishOnboarding());
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
    // #3159 — read BEFORE the validate await: a post-await ref.read throws
    // a StateError if the wizard unmounted while the network call ran.
    final apiKeys = ref.read(apiKeyStorageProvider);
    ctrl.setLoading(true);
    try {
      final validator = ref.read(apiKeyValidatorProvider);
      final result = await validator.validate(apiKey);
      if (!result.isValid) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          SnackBarHelper.showError(
            context,
            l10n.invalidApiKey(result.errorMessage ?? ''),
          );
        }
        return false;
      }
      // #3746 — the wizard validates against Tankerkönig, so the key it
      // stores is the DE slot.
      await apiKeys.setApiKey('de', apiKey);
      return true;
    } finally {
      if (mounted) ctrl.setLoading(false);
    }
  }

  Future<void> _completeSetup() async {
    final ctrl = ref.read(onboardingWizardControllerProvider.notifier);
    // #3159 — every ref.read happens BEFORE the first await so the
    // persistence chain never touches a dead WidgetRef if the wizard
    // unmounts mid-save. The captured repo/notifier finish the writes
    // either way.
    final settings = ref.read(settingsStorageProvider);
    final country = ref.read(activeCountryProvider);
    final language = ref.read(activeLanguageProvider);
    final wizardState = ref.read(onboardingWizardControllerProvider);
    final profileRepo = ref.read(profileRepositoryProvider);
    final profileNotifier = ref.read(activeProfileProvider.notifier);
    ctrl.setLoading(true);
    try {
      await settings.skipSetup();

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
      profileNotifier.refresh();

      if (mounted) context.go(RoutePaths.search);
    } finally {
      if (mounted) ctrl.setLoading(false);
    }
  }

  /// Returns whether the current step is an optional one that can be skipped.
  bool _isCurrentStepSkippable(int currentStep) {
    // OBD2 + Vehicles are always skippable when shown; API key is
    // skippable when it shows. The OBD2 step owns its own skip button,
    // but surfacing the wizard's "Skip" too keeps the UX consistent
    // with the rest of the optional steps. On iOS the OBD2 step is
    // informational-only (App Review 5.1.1(iv), #3535), so there is
    // nothing to skip — Next advances just the same.
    if (_obd2StepIndex != -1 && currentStep == _obd2StepIndex) {
      return ref.read(onboardingObd2ConnectFlowEnabledProvider);
    }
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

  /// #3987 — picking a use mode no longer advances by itself: Next is the
  /// one primary action on every step, and it enables itself through the
  /// watched [activeAppProfileProvider]. The callback stays so the step can
  /// still tell the wizard a pick happened (haptics, analytics, later).
  void _onProfilePicked() {}

  /// Why Next is disabled on [step], or null when it may fire (#3987).
  String? _nextDisabledReason(int step, AppLocalizations l10n) =>
      step == 0 && ref.read(activeAppProfileProvider) == null
          ? l10n.onboardingPickUseMode
          : null;

  List<OnboardingStep> _buildSteps() {
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
    // not setting up. Platform resolution lives in the dedicated
    // dispatch-seam provider (#3163) so this screen stays free of
    // inline `defaultTargetPlatform` branching.
    final showIosStandby =
        showObd2 && ref.watch(onboardingIncludesIosStandbyStepProvider);
    return buildOnboardingSteps(
      showFleet: ref.watch(
        onboardingWizardControllerProvider.select((s) => s.fleetIntent),
      ),
      showVehicle: showVehicle,
      showIosStandby: showIosStandby,
      showObd2: showObd2,
      requiresApiKey: country.requiresApiKey,
      onProfilePicked: _onProfilePicked,
      onObd2Proceed: _advanceFromObd2,
      onObd2AutoFillSuccess: _advanceAfterObd2AutoFill,
      apiKeyController: _apiKeyController,
      onUseDemoData: () {
        _apiKeyController.clear();
        _skip(_apiKeyStepIndex);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch country to rebuild when it changes (affects step count).
    ref.watch(activeCountryProvider);
    final wizardState = ref.watch(onboardingWizardControllerProvider);
    final currentStep = wizardState.currentStep;
    final isLoading = wizardState.isLoading;
    final steps = _buildSteps();
    final l10n = AppLocalizations.of(context);

    // #3987 — a real page title (PageScaffold), and no `n / N` text: the
    // progress indicator carries the position, visibly and as semantics.
    return PageScaffold(
      title: l10n.onboardingTitle,
      automaticallyImplyLeading: false,
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
                children: [for (final step in steps) step.child],
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
              nextDisabledReason: _nextDisabledReason(currentStep, l10n),
            ),
          ],
        ),
      ),
    );
  }
}
