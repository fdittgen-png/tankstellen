// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/station_amenity.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

/// Which price the approach overlay flashes when the driver enters
/// the configured radius of a fuel station (#2067 / Epic #2065).
///
/// - [nearest] — price at the single nearest station the driver first
///   crossed the radius of. Stable; doesn't flip mid-approach.
/// - [cheapestInRadius] — price at the cheapest station currently
///   within the radius. Optimises for "best deal right now"; can flip
///   while driving.
enum ApproachPriceMode {
  nearest('nearest'),
  cheapestInRadius('cheapestInRadius');

  final String key;
  const ApproachPriceMode(this.key);
}

/// How to pick the **top-N stations per sample point** during a route
/// search (#2101 / Epic #2100 lever B). Smaller candidate pool feeds
/// into the isolate-hopped distance math, cutting compute proportionally.
///
/// - [cheapest] — take the N cheapest stations for the selected fuel
///   type at each sample point. Optimises for total trip cost.
/// - [nearest] — take the N stations closest to the sample point.
///   Optimises for minimum detour off the corridor.
enum RouteSearchCriterion {
  cheapest('cheapest'),
  nearest('nearest');

  final String key;
  const RouteSearchCriterion(this.key);
}

enum LandingScreen {
  favorites('favorites'),
  map('map'),
  cheapest('cheapest'),
  nearest('nearest');

  final String key;
  const LandingScreen(this.key);

  /// Localized display name. Falls back to English.
  String localizedName(String languageCode) {
    const names = {
      'favorites': {'en': 'Favorites', 'de': 'Favoriten', 'fr': 'Favoris', 'es': 'Favoritos', 'it': 'Preferiti', 'nl': 'Favorieten', 'da': 'Favoritter', 'sv': 'Favoriter', 'fi': 'Suosikit', 'pl': 'Ulubione'},
      'map': {'en': 'Map', 'de': 'Karte', 'fr': 'Carte', 'es': 'Mapa', 'it': 'Mappa', 'nl': 'Kaart', 'da': 'Kort', 'sv': 'Karta', 'fi': 'Kartta', 'pl': 'Mapa'},
      'cheapest': {'en': 'Cheapest nearby', 'de': 'Günstigste', 'fr': 'Moins cher', 'es': 'Más barato', 'it': 'Più economico', 'nl': 'Goedkoopste', 'da': 'Billigste', 'sv': 'Billigast', 'fi': 'Halvin', 'pl': 'Najtańsze'},
      'nearest': {'en': 'Nearest stations', 'de': 'Nächste Tankstellen', 'fr': 'À proximité', 'es': 'Estaciones cercanas', 'it': 'Stazioni vicine', 'nl': 'Dichtstbijzijnde', 'da': 'Nærmeste', 'sv': 'Närmaste', 'fi': 'Lähimmät', 'pl': 'Najbliższe'},
    };
    return names[key]?[languageCode] ?? names[key]?['en'] ?? key;
  }

  /// For backward compatibility with existing serialized profiles
  String get displayName => localizedName('en');
}

@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String name,
    @FuelTypeJsonConverter() @Default(FuelType.e10) FuelType preferredFuelType,
    @Default(10.0) double defaultSearchRadius,
    @Default(LandingScreen.nearest) LandingScreen landingScreen,
    @Default([]) List<String> favoriteStationIds,
    String? homeZipCode,
    @Default(false) bool autoUpdatePosition,
    String? countryCode,
    String? languageCode,
    @Default(50.0) double routeSegmentKm,
    @Default(false) bool avoidHighways,
    /// Maximum detour (km) the user is willing to deviate from the
    /// direct route when route-planning surfaces off-corridor stations
    /// (#1602). Feeds `RouteSearchState.searchAlongRoute`'s
    /// `searchRadiusKm` / `maxDetourKm`. The 5.0 km default matches the
    /// prior hard-coded call-site default, so existing profiles see no
    /// behaviour change.
    @Default(5.0) double routeDetourBudgetKm,
    /// Minimum price advantage (€/L) a route-planning station must have
    /// over the cheapest station found along the route to stay in the
    /// result feed (#1872). `0.0` disables the filter — every station
    /// along the route is shown (the default, behaviour-preserving).
    /// A positive value keeps only stations priced within this band of
    /// the route's cheapest, decluttering the feed to genuinely
    /// competitive stops.
    @Default(0.0) double minRouteSavingPerLiter,
    /// Per-sample-point top-N cap on route search (#2101 / Epic #2100
    /// lever B). The strategy keeps only the N best stations at each
    /// sample point, picked by [routeSearchCriterion]. Bounds the
    /// total result set to ~`samplePoints × N` for a 400 km route
    /// (vs unbounded today), and feeds a smaller candidate pool into
    /// the isolate-hopped distance math (#2102 / lever A). Default 10.
    @Default(10) int routeSearchTopNPerSamplePoint,
    /// Criterion used by lever B's top-N reduce (#2101). See
    /// [RouteSearchCriterion].
    @Default(RouteSearchCriterion.cheapest)
    RouteSearchCriterion routeSearchCriterion,
    @Deprecated(
      'Migrated to Feature.showFuel in #1373 phase 3c; kept for one-shot migration read.',
    )
    @Default(true) bool showFuel,
    @Deprecated(
      'Migrated to Feature.showElectric in #1373 phase 3c; kept for one-shot migration read.',
    )
    @Default(true) bool showElectric,
    /// Rating sharing mode:
    /// - 'local' — ratings saved only on this device
    /// - 'private' — synced with user's database but not shared
    /// - 'shared' — visible to all users of the database
    @Default('local') String ratingMode,
    /// Amenities the user requires at stations by default (empty = no filter).
    /// Persisted per-profile and loaded into the search criteria screen.
    @Default([]) List<StationAmenity> preferredAmenities,
    /// Optional reference to the user's default [VehicleProfile] (#694).
    /// When set, AddFillUpScreen pre-selects this vehicle. Null keeps the
    /// vehicle selector empty so the user can still log fill-ups without
    /// attributing them to any vehicle.
    String? defaultVehicleId,
    /// Tie-breaker for hybrid default vehicles (#706). Null on
    /// non-hybrid vehicles. When set to [FuelType.electric], search
    /// + station filters treat a hybrid like an EV; when set to any
    /// combustion fuel, they treat it like a petrol/diesel car.
    /// Defaults to null so existing profiles don't need migration.
    @FuelTypeJsonConverter() FuelType? hybridFuelChoice,
    /// Opt-in visibility of the Consumption tab in the bottom nav
    /// (#701). The tab stays hidden unless this is true AND at least
    /// one vehicle is configured — the log is vehicle-centric and a
    /// first-time user without a vehicle would only see the empty
    /// state.
    @Deprecated(
      'Migrated to Feature.showConsumptionTab in #1373 phase 3c; kept for one-shot migration read.',
    )
    @Default(false) bool showConsumptionTab,
    /// Master toggle for gamification surfaces (#1194). Defaults to
    /// true so existing users see no behaviour change. When flipped
    /// off, badges, scores, achievement tabs, and trophy iconography
    /// are hidden across the app — the underlying achievement
    /// evaluation continues to run so toggling back on instantly
    /// restores any earned badges.
    @Deprecated(
      'Migrated to Feature.gamification in #1373 phase 3b; kept for one-shot migration read.',
    )
    @Default(true) bool gamificationEnabled,
    /// Radius (in km) within which the in-trip approach overlay
    /// (#2067 / Epic #2065) grows + flips to a huge price figure for
    /// the user's fuel type. Range 0.5–5.0 in 0.5 km steps; default
    /// 1.0 km. In countries that use miles (UK/US), the slider label
    /// is rendered via `UnitFormatter`; the persisted value stays km.
    @Default(1.0) double approachRadiusKm,
    /// Which station price the approach overlay shows when the driver
    /// is inside [approachRadiusKm]: the nearest station the radius
    /// was crossed for, or the cheapest station currently in range.
    /// See [ApproachPriceMode].
    @Default(ApproachPriceMode.nearest) ApproachPriceMode approachPriceMode,
    /// Floor on how often the approach detector polls the search
    /// chain while a trajet is recording (#2067 / Epic #2065). The
    /// actual cadence is speed-adaptive (≈ 20 % of `radius_m / speed`)
    /// but is never tighter than this floor — protects the search
    /// provider quota. Range 1–10 s; default 5 s.
    @Default(5) int approachMinPollSeconds,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
