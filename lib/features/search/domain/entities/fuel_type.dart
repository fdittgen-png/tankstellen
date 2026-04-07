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

/// Returns fuel types available for a given country code.
List<FuelType> fuelTypesForCountry(String countryCode) {
  switch (countryCode) {
    case 'DE':
      return [FuelType.e5, FuelType.e10, FuelType.diesel, FuelType.electric, FuelType.all];
    case 'FR':
      return [
        FuelType.e10, FuelType.e5, FuelType.e98, FuelType.diesel,
        FuelType.e85, FuelType.lpg, FuelType.electric, FuelType.all,
      ];
    case 'AT':
      return [FuelType.e5, FuelType.e10, FuelType.diesel, FuelType.electric, FuelType.all];
    case 'ES':
      return [
        FuelType.e5, FuelType.e10, FuelType.e98, FuelType.diesel,
        FuelType.dieselPremium, FuelType.lpg, FuelType.electric, FuelType.all,
      ];
    case 'IT':
      return [
        FuelType.e5, FuelType.diesel, FuelType.lpg, FuelType.cng, FuelType.electric, FuelType.all,
      ];
    default:
      return [FuelType.e5, FuelType.e10, FuelType.diesel, FuelType.electric, FuelType.all];
  }
}
