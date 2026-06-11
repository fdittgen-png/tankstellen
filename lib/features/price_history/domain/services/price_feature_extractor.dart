// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../core/calendar/public_holiday_calendar.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/station.dart';
import '../../data/models/price_record.dart';
import '../entities/feature_vector.dart';

/// Pure-Dart producer of [FeatureVector]s from raw [PriceRecord]
/// history. The phase-2 TFLite model (#1117) consumes the output of
/// this service for both offline training and on-device inference, so
/// the contract here mirrors [FeatureVector] exactly.
///
/// The extractor is stateless and side-effect-free — it does no I/O
/// and never fetches a station. The caller passes the [Station] (or
/// `null`) so brand and country flow through deterministically.
class PriceFeatureExtractor {
  const PriceFeatureExtractor();

  /// Builds one [FeatureVector] per record that has a price for the
  /// given [fuelType]. Records without a price (e.g. a snapshot where
  /// only diesel is set but the caller wants e10) are skipped.
  ///
  /// [station] supplies brand and ISO country code; pass `null` when
  /// the station is unknown — those fields will be `null` on the
  /// resulting vectors.
  ///
  /// [countryCodeOverride] lets the caller plug in a country resolved
  /// via [Countries.countryCodeForStationId] (or any other source)
  /// when the [Station] entity is unavailable. When both [station]
  /// and [countryCodeOverride] are provided, [countryCodeOverride]
  /// wins — the override is treated as the more authoritative source.
  List<FeatureVector> extract({
    required List<PriceRecord> records,
    required FuelType fuelType,
    Station? station,
    String? countryCodeOverride,
  }) {
    final brand = station?.brand;
    final country = countryCodeOverride ?? _countryFromStation(station);

    final out = <FeatureVector>[];
    for (final record in records) {
      final price = _priceForFuelType(record, fuelType);
      if (price == null) continue;

      out.add(
        FeatureVector(
          hourOfDay: record.recordedAt.hour,
          dayOfWeek: record.recordedAt.weekday,
          brand: brand,
          countryCode: country,
          isHoliday: PublicHolidayCalendar.isPublicHoliday(
            record.recordedAt,
            country,
          ),
          priceEur: price,
          observedAt: record.recordedAt,
        ),
      );
    }
    return out;
  }
}

/// Extracts the price for [fuelType] from [record], returning `null`
/// for fuel types that the [PriceRecord] schema does not carry
/// (hydrogen, electric, the `all` meta-type).
double? _priceForFuelType(PriceRecord record, FuelType fuelType) {
  return switch (fuelType) {
    FuelTypeE5() => record.e5,
    FuelTypeE10() => record.e10,
    FuelTypeE98() => record.e98,
    FuelTypeDiesel() => record.diesel,
    FuelTypeDieselPremium() => record.dieselPremium,
    FuelTypeE85() => record.e85,
    FuelTypeLpg() => record.lpg,
    FuelTypeCng() => record.cng,
    FuelTypeHydrogen() || FuelTypeElectric() || FuelTypeAll() => null,
  };
}

/// Phase-1 stations don't carry an explicit ISO country code field
/// (see [Station]); we leave country resolution to the caller's
/// [countryCodeOverride] in that case. This indirection keeps the
/// extractor honest — it won't invent a country from a postcode.
String? _countryFromStation(Station? station) {
  if (station == null) return null;
  // Phase-1 Station entity has no country field. When phase 2 adds one,
  // wire it here without changing the public extractor API.
  return null;
}
