import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_wizard_provider.g.dart';

/// UI state for the multi-step onboarding wizard. API key text value lives
/// in a local [TextEditingController]; everything else lives here.
class OnboardingWizardState {
  final int currentStep;
  final bool isLoading;

  const OnboardingWizardState({
    this.currentStep = 0,
    this.isLoading = false,
  });

  OnboardingWizardState copyWith({int? currentStep, bool? isLoading}) {
    return OnboardingWizardState(
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@riverpod
class OnboardingWizardController extends _$OnboardingWizardController {
  @override
  OnboardingWizardState build() => const OnboardingWizardState();

  void setStep(int step) => state = state.copyWith(currentStep: step);

  void setLoading(bool loading) => state = state.copyWith(isLoading: loading);
}
