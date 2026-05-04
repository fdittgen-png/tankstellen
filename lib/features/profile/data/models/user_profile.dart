import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/station_amenity.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

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
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
