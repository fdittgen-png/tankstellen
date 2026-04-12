import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../profile/data/models/user_profile.dart';
import '../../search/domain/entities/fuel_type.dart';

part 'onboarding_wizard_provider.g.dart';

/// UI state for the multi-step onboarding wizard. API key text value lives
/// in a local [TextEditingController]; everything else lives here.
class OnboardingWizardState {
  final int currentStep;
  final bool isLoading;
  final String? homeZipCode;
  final double defaultSearchRadius;
  final FuelType preferredFuelType;
  final LandingScreen landingScreen;

  OnboardingWizardState({
    this.currentStep = 0,
    this.isLoading = false,
    this.homeZipCode,
    this.defaultSearchRadius = 10.0,
    FuelType? preferredFuelType,
    this.landingScreen = LandingScreen.search,
  }) : preferredFuelType = preferredFuelType ?? FuelType.e10;

  OnboardingWizardState copyWith({
    int? currentStep,
    bool? isLoading,
    String? homeZipCode,
    double? defaultSearchRadius,
    FuelType? preferredFuelType,
    LandingScreen? landingScreen,
  }) {
    return OnboardingWizardState(
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      homeZipCode: homeZipCode ?? this.homeZipCode,
      defaultSearchRadius: defaultSearchRadius ?? this.defaultSearchRadius,
      preferredFuelType: preferredFuelType ?? this.preferredFuelType,
      landingScreen: landingScreen ?? this.landingScreen,
    );
  }
}

@riverpod
class OnboardingWizardController extends _$OnboardingWizardController {
  @override
  OnboardingWizardState build() => OnboardingWizardState();

  void setStep(int step) => state = state.copyWith(currentStep: step);

  void setLoading(bool loading) => state = state.copyWith(isLoading: loading);

  void setHomeZipCode(String? zip) =>
      state = state.copyWith(homeZipCode: zip);

  void setDefaultSearchRadius(double radius) =>
      state = state.copyWith(defaultSearchRadius: radius);

  void setPreferredFuelType(FuelType type) =>
      state = state.copyWith(preferredFuelType: type);

  void setLandingScreen(LandingScreen screen) =>
      state = state.copyWith(landingScreen: screen);
}
