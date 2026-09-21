// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../profile/data/models/user_profile.dart';
import '../../../core/domain/fuel_type.dart';
import '../../feature_management/api.dart';
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

  /// #4217 — the user picked the company/fleet-vehicle intent on the
  /// first page. Drives the two fleet-only wizard pages (fleet identity
  /// and privacy summary).
  ///
  /// Deliberately NOT `Feature.fleetMode`: the flag cannot be switched
  /// on without a configured TankSync backend, and a driver whose
  /// employer's database is not set up yet must still reach the step
  /// that TELLS them so (ADR 0025 D2/D3 — disabled with a reason, never
  /// a silently missing page).
  final bool fleetIntent;

  /// What the driver typed on the fleet identity step (#4217). Held
  /// here, not in the step's own [TextEditingController], because
  /// #4217's "back navigation preserves data" rule has to survive the
  /// page leaving the `PageView`'s cache.
  final String fleetInviteCode;
  final String fleetOrgName;

  OnboardingWizardState({
    this.currentStep = 0,
    this.isLoading = false,
    this.homeZipCode,
    this.defaultSearchRadius = 10.0,
    FuelType? preferredFuelType,
    this.landingScreen = LandingScreen.nearest,
    this.obd2VinData,
    this.obd2VinReadFailed = false,
    this.fleetIntent = false,
    this.fleetInviteCode = '',
    this.fleetOrgName = '',
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
    bool? fleetIntent,
    String? fleetInviteCode,
    String? fleetOrgName,
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
      fleetIntent: fleetIntent ?? this.fleetIntent,
      fleetInviteCode: fleetInviteCode ?? this.fleetInviteCode,
      fleetOrgName: fleetOrgName ?? this.fleetOrgName,
    );
  }
}

@Riverpod(keepAlive: true)
class OnboardingWizardController extends _$OnboardingWizardController {
  @override
  OnboardingWizardState build() => OnboardingWizardState();

  void setStep(int step) => state = state.copyWith(currentStep: step);

  /// Apply the use-mode card the user tapped on the first page (#1518,
  /// #4217).
  ///
  /// One call so the three personal cards and the fleet card leave the
  /// app in a consistent state: the preset bundle is applied first
  /// (`select` REPLACES the enabled set), then fleet mode is switched on
  /// or off to match [fleet]. Picking a personal card after the fleet
  /// card therefore takes the fleet pages — and the Settings topic —
  /// away again, instead of leaving a half-fleet app behind.
  ///
  /// Enabling is **best effort**: `Feature.fleetMode` is beta-only and
  /// requires `Feature.tankSync` (ADR 0025 D3/D6), so on a production
  /// build or without a configured backend the flag stays off. The
  /// intent is still recorded, because the fleet identity step is what
  /// explains why — see [OnboardingWizardState.fleetIntent].
  Future<void> applyProfileChoice(
    AppProfile profile, {
    bool fleet = false,
  }) async {
    state = state.copyWith(fleetIntent: fleet);
    await ref.read(activeAppProfileProvider.notifier).select(profile);
    final flags = ref.read(featureFlagsProvider.notifier);
    if (!fleet) {
      await flags.disable(Feature.fleetMode);
      return;
    }
    final manifest = ref.read(featureManifestProvider);
    final channel = ref.read(buildChannelProvider);
    final enabled = ref.read(enabledFeaturesProvider);
    // Pre-checked rather than try/catch: `enable` throws for both a
    // channel-unavailable feature and a missing prerequisite, and an
    // intent card is not the place to surface either as an error.
    if (manifest.entryFor(Feature.fleetMode).isAvailableIn(channel) &&
        canEnable(Feature.fleetMode, manifest, enabled)) {
      await flags.enable(Feature.fleetMode);
    }
  }

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

  /// #4217 — remember the invite code / fleet name as they are typed,
  /// so stepping away and back does not lose them.
  void setFleetInviteCode(String code) =>
      state = state.copyWith(fleetInviteCode: code);

  void setFleetOrgName(String name) =>
      state = state.copyWith(fleetOrgName: name);
}
