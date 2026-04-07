import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/country/country_provider.dart';
import '../../../../core/language/language_provider.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../data/api_key_validator.dart';
import '../../providers/api_key_validator_provider.dart';
import '../widgets/api_key_step.dart';
import '../widgets/completion_step.dart';
import '../widgets/country_language_step.dart';
import '../widgets/onboarding_progress_indicator.dart';
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
  int _currentStep = 0;
  bool _isLoading = false;

  /// Returns the total number of steps based on whether the selected country
  /// requires an API key.
  int get _stepCount {
    final country = ref.read(activeCountryProvider);
    return country.requiresApiKey ? 4 : 3;
  }

  bool get _isLastStep => _currentStep == _stepCount - 1;

  @override
  void dispose() {
    _pageController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _next() {
    if (_isLastStep) {
      _finishOnboarding();
    } else {
      _goToStep(_currentStep + 1);
    }
  }

  void _back() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  /// Skips the current step (for optional steps like API key).
  void _skip() {
    if (!_isLastStep) {
      _goToStep(_currentStep + 1);
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
    setState(() => _isLoading = true);
    try {
      final validator = ref.read(apiKeyValidatorProvider);
      final result = await validator.validate(apiKey);
      if (!result.isValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid API key: ${result.errorMessage}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return false;
      }
      final apiKeys = ref.read(apiKeyStorageProvider);
      await apiKeys.setApiKey(apiKey);
      return true;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completeSetup() async {
    setState(() => _isLoading = true);
    try {
      final settings = ref.read(settingsStorageProvider);
      await settings.skipSetup();

      final country = ref.read(activeCountryProvider);
      final language = ref.read(activeLanguageProvider);

      final profileRepo = ref.read(profileRepositoryProvider);
      final profile = await profileRepo.ensureDefaultProfile();

      final updated = profile.copyWith(
        countryCode: country.code,
        languageCode: language.code,
      );
      await profileRepo.updateProfile(updated);
      ref.read(activeProfileProvider.notifier).refresh();

      if (mounted) context.go('/');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Returns whether the current step is an optional one that can be skipped.
  bool get _isCurrentStepSkippable {
    final country = ref.read(activeCountryProvider);
    // The API key step is skippable (index 2 when country requires key)
    return country.requiresApiKey && _currentStep == 2;
  }

  List<Widget> _buildSteps() {
    final country = ref.watch(activeCountryProvider);
    return [
      const WelcomeStep(),
      const CountryLanguageStep(),
      if (country.requiresApiKey)
        ApiKeyStep(apiKeyController: _apiKeyController),
      const CompletionStep(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    // Watch country to rebuild when it changes (affects step count)
    ref.watch(activeCountryProvider);
    final steps = _buildSteps();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Progress indicator
            OnboardingProgressIndicator(
              currentStep: _currentStep,
              stepCount: _stepCount,
            ),
            const SizedBox(height: 8),
            // Step counter text
            Text(
              '${_currentStep + 1} / $_stepCount',
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
                  setState(() => _currentStep = index);
                },
                children: steps,
              ),
            ),
            // Navigation buttons
            Padding(
              padding: EdgeInsets.fromLTRB(
                32,
                16,
                32,
                16 + MediaQuery.of(context).viewPadding.bottom,
              ),
              child: Row(
                children: [
                  // Back button
                  if (_currentStep > 0)
                    TextButton.icon(
                      onPressed: _isLoading ? null : _back,
                      icon: const Icon(Icons.arrow_back),
                      label: Text(l10n?.onboardingBack ?? 'Back'),
                    )
                  else
                    const SizedBox(width: 80),
                  const Spacer(),
                  // Skip button (optional steps)
                  if (_isCurrentStepSkippable)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextButton(
                        onPressed: _isLoading ? null : _skip,
                        child: Text(l10n?.onboardingSkip ?? 'Skip'),
                      ),
                    ),
                  // Next / Finish button
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _next,
                    icon: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _isLastStep
                                ? Icons.check
                                : Icons.arrow_forward,
                          ),
                    label: Text(
                      _isLastStep
                          ? (l10n?.onboardingFinish ?? 'Get started')
                          : (l10n?.onboardingNext ?? 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
