import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/country/country_provider.dart';
import '../../../../core/language/language_provider.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../providers/api_key_validator_provider.dart';
import '../../providers/onboarding_wizard_provider.dart';
import '../widgets/api_key_step.dart';
import '../widgets/completion_step.dart';
import '../widgets/country_language_step.dart';
import '../widgets/landing_screen_step.dart';
import '../widgets/onboarding_navigation_buttons.dart';
import '../widgets/onboarding_progress_indicator.dart';
import '../widgets/preferences_step.dart';
import '../widgets/vehicles_step.dart';
import '../widgets/welcome_step.dart';

/// Multi-step onboarding wizard with progress indicator.
///
/// Steps:
/// 1. Welcome — app branding and introduction
/// 2. Country & Language — select locale preferences
/// 3. API Key — optional key entry (only if country requires it)
/// 4. Done — confirmation and finish
///
/// The API Key step is conditionally shown based on the selected country.
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

  /// Returns the total number of steps based on whether the selected country
  /// requires an API key.
  int get _stepCount {
    final country = ref.read(activeCountryProvider);
    // Welcome, Country, Vehicles, Preferences, Landing, [API Key], Done
    return country.requiresApiKey ? 7 : 6;
  }

  /// Zero-based index of the Vehicles step. Placed BEFORE Preferences so
  /// the user can pick a vehicle first — the fuel preference can then
  /// derive from the vehicle's fuel (#695).
  static const int _vehiclesStepIndex = 2;

  /// Zero-based index of the optional API key step.
  int get _apiKeyStepIndex {
    final country = ref.read(activeCountryProvider);
    return country.requiresApiKey ? 5 : -1;
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
    // Vehicles is always skippable; API key is skippable when it shows.
    if (currentStep == _vehiclesStepIndex) return true;
    return currentStep == _apiKeyStepIndex && _apiKeyStepIndex != -1;
  }

  List<Widget> _buildSteps() {
    final country = ref.watch(activeCountryProvider);
    return [
      const WelcomeStep(),
      const CountryLanguageStep(),
      const VehiclesStep(),
      const PreferencesStep(),
      const LandingScreenStep(),
      if (country.requiresApiKey)
        ApiKeyStep(apiKeyController: _apiKeyController),
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
