import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../search/domain/entities/fuel_type.dart';
import '../data/models/user_profile.dart';

part 'profile_edit_provider.g.dart';

/// UI state for the profile edit sheet. Text input values live in
/// [TextEditingController]s owned by the sheet itself (Flutter lifecycle);
/// everything the form needs to rebuild on lives here.
class ProfileEditState {
  final FuelType fuelType;
  final double radius;
  final LandingScreen landingScreen;
  final String? countryCode;
  final String? languageCode;
  final double routeSegmentKm;
  final bool avoidHighways;
  final bool showFuel;
  final bool showElectric;
  final String ratingMode;

  const ProfileEditState({
    required this.fuelType,
    required this.radius,
    required this.landingScreen,
    required this.countryCode,
    required this.languageCode,
    required this.routeSegmentKm,
    required this.avoidHighways,
    required this.showFuel,
    required this.showElectric,
    required this.ratingMode,
  });

  factory ProfileEditState.fromProfile(UserProfile p) => ProfileEditState(
        fuelType: p.preferredFuelType,
        radius: p.defaultSearchRadius,
        landingScreen: p.landingScreen,
        countryCode: p.countryCode,
        languageCode: p.languageCode,
        routeSegmentKm: p.routeSegmentKm,
        avoidHighways: p.avoidHighways,
        showFuel: p.showFuel,
        showElectric: p.showElectric,
        ratingMode: p.ratingMode,
      );

  ProfileEditState copyWith({
    FuelType? fuelType,
    double? radius,
    LandingScreen? landingScreen,
    String? countryCode,
    bool clearCountry = false,
    String? languageCode,
    bool clearLanguage = false,
    double? routeSegmentKm,
    bool? avoidHighways,
    bool? showFuel,
    bool? showElectric,
    String? ratingMode,
  }) {
    return ProfileEditState(
      fuelType: fuelType ?? this.fuelType,
      radius: radius ?? this.radius,
      landingScreen: landingScreen ?? this.landingScreen,
      countryCode: clearCountry ? null : (countryCode ?? this.countryCode),
      languageCode: clearLanguage ? null : (languageCode ?? this.languageCode),
      routeSegmentKm: routeSegmentKm ?? this.routeSegmentKm,
      avoidHighways: avoidHighways ?? this.avoidHighways,
      showFuel: showFuel ?? this.showFuel,
      showElectric: showElectric ?? this.showElectric,
      ratingMode: ratingMode ?? this.ratingMode,
    );
  }
}

/// Family provider keyed on the profile id, so a sheet edit never leaks
/// across profiles and each sheet gets its own scoped state that is
/// automatically disposed when the sheet closes.
@riverpod
class ProfileEditController extends _$ProfileEditController {
  @override
  ProfileEditState build(UserProfile initial) =>
      ProfileEditState.fromProfile(initial);

  void setFuelType(FuelType v) => state = state.copyWith(fuelType: v);
  void setRadius(double v) => state = state.copyWith(radius: v);
  void setRouteSegmentKm(double v) =>
      state = state.copyWith(routeSegmentKm: v);
  void setAvoidHighways(bool v) => state = state.copyWith(avoidHighways: v);
  void setShowFuel(bool v) => state = state.copyWith(showFuel: v);
  void setShowElectric(bool v) => state = state.copyWith(showElectric: v);
  void setRatingMode(String v) => state = state.copyWith(ratingMode: v);
  void setLandingScreen(LandingScreen v) =>
      state = state.copyWith(landingScreen: v);
  void setCountryCode(String? v) =>
      state = state.copyWith(countryCode: v, clearCountry: v == null);
  void setLanguageCode(String? v) =>
      state = state.copyWith(languageCode: v, clearLanguage: v == null);
}
