import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

/// Canonical fuel types across all countries.
///
/// Sealed class hierarchy enables exhaustive pattern matching while allowing
/// richer metadata (icon, unit, category) per fuel type. New fuel types can
/// be added as subclasses without modifying existing switch expressions.
///
/// For JSON serialization in freezed models, annotate the field with
/// `@FuelTypeJsonConverter()`.
sealed class FuelType {
  /// API-compatible identifier (lowercase, used for serialization and cache keys).
  final String apiValue;

  /// Human-readable label used when no localization is available.
  final String displayName;

  /// Material icon for UI display.
  final IconData icon;

  /// Price unit (e.g. 'EUR/L', 'EUR/kg', 'EUR/kWh').
  final String unit;

  /// Whether this is a traditional fuel, alternative fuel, or meta type.
  final FuelCategory category;

  const FuelType({
    required this.apiValue,
    required this.displayName,
    required this.icon,
    required this.unit,
    required this.category,
  });

  /// All known fuel type instances, ordered for UI display.
  static const List<FuelType> values = [
    e5, e10, e98, diesel, dieselPremium, e85,
    lpg, cng, hydrogen, electric, all,
  ];

  // ── Singleton instances (backward-compatible with former enum values) ──

  static const FuelType e5 = FuelTypeE5._();
  static const FuelType e10 = FuelTypeE10._();
  static const FuelType e98 = FuelTypeE98._();
  static const FuelType diesel = FuelTypeDiesel._();
  static const FuelType dieselPremium = FuelTypeDieselPremium._();
  static const FuelType e85 = FuelTypeE85._();
  static const FuelType lpg = FuelTypeLpg._();
  static const FuelType cng = FuelTypeCng._();
  static const FuelType hydrogen = FuelTypeHydrogen._();
  static const FuelType electric = FuelTypeElectric._();
  static const FuelType all = FuelTypeAll._();

  /// Parse a string (typically from JSON or an API) into a [FuelType].
  /// Case-insensitive. Returns [FuelType.all] for unknown values.
  ///
  /// Accepts both snake_case apiValues ('diesel_premium') and legacy
  /// camelCase enum names ('dieselPremium') for backward compatibility
  /// with stored Hive/JSON data.
  static FuelType fromString(String value) {
    final lower = value.toLowerCase();
    for (final type in values) {
      if (type.apiValue == lower) return type;
    }
    // Legacy camelCase names from old enum serialization
    return switch (lower) {
      'dieselpremium' => FuelType.dieselPremium,
      _ => FuelType.all,
    };
  }

  /// Short programmatic name (mirrors former enum .name).
  String get name => apiValue;

  /// Whether this is a conventional (fossil-based) fuel type.
  bool get isConventional => category == FuelCategory.conventional;

  /// Whether this is an alternative fuel (LPG, CNG, H2, electric).
  bool get isAlternative => category == FuelCategory.alternative;

  @override
  String toString() => 'FuelType.$apiValue';
}

/// Classification of fuel types.
enum FuelCategory {
  /// Petrol/diesel based fuels
  conventional,

  /// LPG, CNG, hydrogen, electric, biofuels
  alternative,

  /// Meta types like "all"
  meta,
}

/// Interchangeable family a typical vehicle can physically accept.
///
/// A petrol car can be filled with any of E5 / E10 / E98 / E85 at the
/// pump (the mix changes the actual burn but the hardware accepts it),
/// a diesel car takes diesel or diesel-premium, LPG / CNG / electric
/// cars are one-fuel-only. Used by the fill-up form to offer "you
/// normally run E10 but you filled with E85 today" flexibility
/// without showing impossible options like EV on a diesel receipt
/// (#713).
enum FuelCompatibilityFamily { petrol, diesel, lpg, cng, electric, hydrogen }

/// The compatibility family a single [FuelType] belongs to.
FuelCompatibilityFamily fuelCompatibilityFamily(FuelType fuel) {
  return switch (fuel) {
    FuelTypeE5() ||
    FuelTypeE10() ||
    FuelTypeE98() ||
    FuelTypeE85() =>
      FuelCompatibilityFamily.petrol,
    FuelTypeDiesel() ||
    FuelTypeDieselPremium() =>
      FuelCompatibilityFamily.diesel,
    FuelTypeLpg() => FuelCompatibilityFamily.lpg,
    FuelTypeCng() => FuelCompatibilityFamily.cng,
    FuelTypeElectric() => FuelCompatibilityFamily.electric,
    FuelTypeHydrogen() => FuelCompatibilityFamily.hydrogen,
    // "All" is the search-time wildcard; treat as petrol for UI fallback.
    FuelTypeAll() => FuelCompatibilityFamily.petrol,
  };
}

/// Ordered list of fuels a vehicle whose primary fuel is [primary]
/// can practically be filled with. The first entry is always [primary]
/// so dropdowns show it on top.
List<FuelType> compatibleFuelsFor(FuelType primary) {
  final list = switch (fuelCompatibilityFamily(primary)) {
    FuelCompatibilityFamily.petrol => const [
        FuelType.e10,
        FuelType.e5,
        FuelType.e98,
        FuelType.e85,
      ],
    FuelCompatibilityFamily.diesel => const [
        FuelType.diesel,
        FuelType.dieselPremium,
      ],
    FuelCompatibilityFamily.lpg => const [FuelType.lpg],
    FuelCompatibilityFamily.cng => const [FuelType.cng],
    FuelCompatibilityFamily.electric => const [FuelType.electric],
    FuelCompatibilityFamily.hydrogen => const [FuelType.hydrogen],
  };
  // Pin [primary] first so the picker's default landing option is the
  // vehicle's configured fuel.
  final reordered = <FuelType>[primary, ...list.where((f) => f != primary)];
  return reordered;
}

// ── Subclasses ──────────────────────────────────────────────────────────────

final class FuelTypeE5 extends FuelType {
  const FuelTypeE5._()
      : super(
          apiValue: 'e5',
          displayName: 'Super E5',
          icon: Icons.local_gas_station,
          unit: 'EUR/L',
          category: FuelCategory.conventional,
        );
}

final class FuelTypeE10 extends FuelType {
  const FuelTypeE10._()
      : super(
          apiValue: 'e10',
          displayName: 'Super E10',
          icon: Icons.local_gas_station,
          unit: 'EUR/L',
          category: FuelCategory.conventional,
        );
}

final class FuelTypeE98 extends FuelType {
  const FuelTypeE98._()
      : super(
          apiValue: 'e98',
          displayName: 'Super 98',
          icon: Icons.local_gas_station,
          unit: 'EUR/L',
          category: FuelCategory.conventional,
        );
}

final class FuelTypeDiesel extends FuelType {
  const FuelTypeDiesel._()
      : super(
          apiValue: 'diesel',
          displayName: 'Diesel',
          icon: Icons.local_gas_station,
          unit: 'EUR/L',
          category: FuelCategory.conventional,
        );
}

final class FuelTypeDieselPremium extends FuelType {
  const FuelTypeDieselPremium._()
      : super(
          apiValue: 'diesel_premium',
          displayName: 'Diesel Premium',
          icon: Icons.local_gas_station,
          unit: 'EUR/L',
          category: FuelCategory.conventional,
        );
}

final class FuelTypeE85 extends FuelType {
  const FuelTypeE85._()
      : super(
          apiValue: 'e85',
          displayName: 'E85 / Bio\u00e9thanol',
          icon: Icons.eco,
          unit: 'EUR/L',
          category: FuelCategory.alternative,
        );
}

final class FuelTypeLpg extends FuelType {
  const FuelTypeLpg._()
      : super(
          apiValue: 'lpg',
          displayName: 'GPL / LPG',
          icon: Icons.propane_tank,
          unit: 'EUR/L',
          category: FuelCategory.alternative,
        );
}

final class FuelTypeCng extends FuelType {
  const FuelTypeCng._()
      : super(
          apiValue: 'cng',
          displayName: 'GNV / CNG',
          icon: Icons.propane_tank,
          unit: 'EUR/kg',
          category: FuelCategory.alternative,
        );
}

final class FuelTypeHydrogen extends FuelType {
  const FuelTypeHydrogen._()
      : super(
          apiValue: 'hydrogen',
          displayName: 'Hydrog\u00e8ne / H2',
          icon: Icons.water_drop,
          unit: 'EUR/kg',
          category: FuelCategory.alternative,
        );
}

final class FuelTypeElectric extends FuelType {
  const FuelTypeElectric._()
      : super(
          apiValue: 'electric',
          displayName: 'Electric \u26a1',
          icon: Icons.ev_station,
          unit: 'EUR/kWh',
          category: FuelCategory.alternative,
        );
}

final class FuelTypeAll extends FuelType {
  const FuelTypeAll._()
      : super(
          apiValue: 'all',
          displayName: 'All',
          icon: Icons.select_all,
          unit: '',
          category: FuelCategory.meta,
        );
}

// ── JSON Converter for freezed/json_serializable ────────────────────────────

/// Use this converter on [FuelType] fields in freezed models:
/// ```dart
/// @FuelTypeJsonConverter()
/// FuelType fuelType,
/// ```
class FuelTypeJsonConverter implements JsonConverter<FuelType, String> {
  const FuelTypeJsonConverter();

  @override
  FuelType fromJson(String json) => FuelType.fromString(json);

  @override
  String toJson(FuelType object) => object.apiValue;
}

// ── Country mappings ────────────────────────────────────────────────────────

/// Default fuel types for any country not present in [_countryFuels].
///
/// Mirrors the historical `default:` branch of `fuelTypesForCountry`: the
/// minimal set every petrol/diesel station can be assumed to carry, plus
/// the EV and "all" wildcard.
const List<FuelType> _defaultCountryFuels = [
  FuelType.e5,
  FuelType.e10,
  FuelType.diesel,
  FuelType.electric,
  FuelType.all,
];

/// Declarative per-country fuel-type catalogue.
///
/// Each entry is the exact ordered list returned for that ISO 3166-1
/// alpha-2 country code. Order matters: the UI fuel-type selector renders
/// the list in this order, so the most common fuel for each country sits
/// first. Every list ends with [FuelType.electric] followed by
/// [FuelType.all] (the search-time wildcard) — keep that tail when adding
/// a new country.
const Map<String, List<FuelType>> _countryFuels = {
  // DE: Tankerkönig publishes E5, E10, Diesel.
  'DE': [FuelType.e5, FuelType.e10, FuelType.diesel, FuelType.electric, FuelType.all],
  // FR: Prix Carburants — SP95-E10 first (most common at French pumps),
  // then SP95 / SP98, Gazole, E85 (Bioéthanol), GPL.
  'FR': [
    FuelType.e10, FuelType.e5, FuelType.e98, FuelType.diesel,
    FuelType.e85, FuelType.lpg, FuelType.electric, FuelType.all,
  ],
  // AT: Spritpreisrechner — Super 95 (E5/E10), Diesel.
  'AT': [FuelType.e5, FuelType.e10, FuelType.diesel, FuelType.electric, FuelType.all],
  // ES: Geoportal Gasolineras — Gasolina 95/98, Diésel A/A+, GLP.
  'ES': [
    FuelType.e5, FuelType.e10, FuelType.e98, FuelType.diesel,
    FuelType.dieselPremium, FuelType.lpg, FuelType.electric, FuelType.all,
  ],
  // IT: MIMIT (osservaprezzi) — Benzina, Gasolio, GPL, Metano (CNG).
  'IT': [
    FuelType.e5, FuelType.diesel, FuelType.lpg, FuelType.cng, FuelType.electric, FuelType.all,
  ],
  // LU: Luxembourg regulated prices (#574): Sans Plomb 95 (mapped to
  // E5/E10), Sans Plomb 98 (E98), Diesel, LPG.
  'LU': [
    FuelType.e5, FuelType.e10, FuelType.e98, FuelType.diesel,
    FuelType.lpg, FuelType.electric, FuelType.all,
  ],
  // SI: Slovenia sells NMB-95 (→ e5), NMB-100 (premium, → e98), Dizel
  // (→ diesel), Dizel Premium, and LPG. #575
  'SI': [
    FuelType.e5, FuelType.e98, FuelType.diesel,
    FuelType.dieselPremium, FuelType.lpg, FuelType.electric, FuelType.all,
  ],
  // KR: South Korea (OPINET): Gasoline (→ e5), Premium Gasoline (→ e98),
  // Diesel, LPG. Kerosene is published by OPINET but has no FuelType
  // enum today — added in a follow-up. #597
  'KR': [
    FuelType.e5, FuelType.e98, FuelType.diesel,
    FuelType.lpg, FuelType.electric, FuelType.all,
  ],
  // CL: Chile (CNE Bencina en Línea): Gasolina 93/95 (→ e5),
  // Gasolina 97 (→ e98), Diésel, Gas licuado / LPG. Kerosene is
  // published by CNE but has no FuelType enum today. #596
  'CL': [
    FuelType.e5, FuelType.e98, FuelType.diesel,
    FuelType.lpg, FuelType.electric, FuelType.all,
  ],
  // GR: Greece (Paratiritirio Timon via fuelpricesgr community API):
  // Αμόλυβδη 95 (→ e5), Αμόλυβδη 100 (→ e98), Diesel, Υγραέριο /
  // LPG. Diesel heating is published but intentionally dropped
  // (not a motoring fuel). #576
  'GR': [
    FuelType.e5, FuelType.e98, FuelType.diesel,
    FuelType.lpg, FuelType.electric, FuelType.all,
  ],
  // RO: Romania (Monitorul Prețurilor — pretcarburant.ro): Benzină
  // Standard (→ e5), Benzină Premium (→ e98), Motorină Standard
  // (→ diesel), Motorină Premium (→ diesel premium), GPL
  // (→ lpg). 15-minute government-mandated updates. #577
  'RO': [
    FuelType.e5, FuelType.e98, FuelType.diesel,
    FuelType.dieselPremium, FuelType.lpg, FuelType.electric, FuelType.all,
  ],
};

/// Returns fuel types available for a given country code.
///
/// Looks up [countryCode] in [_countryFuels]; falls back to
/// [_defaultCountryFuels] for unknown countries (the same minimal set the
/// previous `switch` returned via its `default:` branch).
List<FuelType> fuelTypesForCountry(String countryCode) {
  return _countryFuels[countryCode] ?? _defaultCountryFuels;
}
