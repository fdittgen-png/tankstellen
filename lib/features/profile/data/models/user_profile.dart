import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../search/domain/entities/fuel_type.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

enum LandingScreen {
  search('search'),
  favorites('favorites'),
  map('map'),
  cheapest('cheapest'),
  nearest('nearest');

  final String key;
  const LandingScreen(this.key);

  /// Localized display name. Falls back to English.
  String localizedName(String languageCode) {
    const names = {
      'search': {'en': 'Search', 'de': 'Suche', 'fr': 'Recherche', 'es': 'Buscar', 'it': 'Cerca', 'nl': 'Zoeken', 'da': 'Søg', 'sv': 'Sök', 'fi': 'Haku', 'pl': 'Szukaj'},
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
    @Default(LandingScreen.search) LandingScreen landingScreen,
    @Default([]) List<String> favoriteStationIds,
    String? homeZipCode,
    @Default(false) bool autoUpdatePosition,
    String? countryCode,
    String? languageCode,
    @Default(50.0) double routeSegmentKm,
    @Default(false) bool avoidHighways,
    @Default(true) bool showFuel,
    @Default(true) bool showElectric,
    /// Rating sharing mode:
    /// - 'local' — ratings saved only on this device
    /// - 'private' — synced with user's database but not shared
    /// - 'shared' — visible to all users of the database
    @Default('local') String ratingMode,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
