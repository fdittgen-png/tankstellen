import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../profile/data/models/user_profile.dart';
import '../../search/domain/entities/fuel_type.dart';
import '../../vehicle/domain/entities/vin_data.dart';

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

  /// Decoded VIN carried across the OBD2 onboarding step (#816) and the
  /// subsequent vehicle-details step. Ephemeral — stays in memory only
  /// until the user saves the profile (or finishes the wizard).
  final VinData? obd2VinData;

  /// Set to `true` when the OBD2 adapter connected successfully but the
  /// VIN read returned null (#816). Used by the following manual
  /// vehicle step to show a small "Couldn't read VIN — enter manually"
  /// banner so the user isn't left wondering why auto-fill didn't
  /// happen.
  final bool obd2VinReadFailed;

  OnboardingWizardState({
    this.currentStep = 0,
    this.isLoading = false,
    this.homeZipCode,
    this.defaultSearchRadius = 10.0,
    FuelType? preferredFuelType,
    this.landingScreen = LandingScreen.nearest,
    this.obd2VinData,
    this.obd2VinReadFailed = false,
  }) : preferredFuelType = preferredFuelType ?? FuelType.e10;

  OnboardingWizardState copyWith({
    int? currentStep,
    bool? isLoading,
    String? homeZipCode,
    double? defaultSearchRadius,
    FuelType? preferredFuelType,
    LandingScreen? landingScreen,
    VinData? obd2VinData,
    bool? obd2VinReadFailed,
  }) {
    return OnboardingWizardState(
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      homeZipCode: homeZipCode ?? this.homeZipCode,
      defaultSearchRadius: defaultSearchRadius ?? this.defaultSearchRadius,
      preferredFuelType: preferredFuelType ?? this.preferredFuelType,
      landingScreen: landingScreen ?? this.landingScreen,
      obd2VinData: obd2VinData ?? this.obd2VinData,
      obd2VinReadFailed: obd2VinReadFailed ?? this.obd2VinReadFailed,
    );
  }
}

@Riverpod(keepAlive: true)
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

  /// Record the decoded VIN from the OBD2 onboarding step (#816). Also
  /// clears the "VIN read failed" banner in case the user retries after
  /// a previous failure.
  void setObd2VinData(VinData? data) => state = state.copyWith(
        obd2VinData: data,
        obd2VinReadFailed: false,
      );

  /// Flag that the OBD2 adapter connected but the VIN could not be read
  /// (#816). The next manual vehicle step consults this to surface the
  /// "Couldn't read VIN" banner.
  void setObd2VinReadFailed() =>
      state = state.copyWith(obd2VinReadFailed: true);
}
