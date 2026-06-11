// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../search/domain/entities/fuel_type.dart';

/// Catalog-product parsing utilities for the Romanian *Monitorul
/// Prețurilor* observatory feed (monitorulpreturilor.info, #3193).
///
/// Single source of truth for how the observatory's gas-catalog product
/// ids map onto canonical [FuelType] values, plus the RON-per-litre
/// parser that filters out junk (zero, negative, non-numeric).
///
/// The id table mirrors the live `GET /pmonsvc/Gas/GetGasProductsFromCatalog`
/// response (recorded 2026-06-10):
///
/// ```json
/// { "Items": [
///   { "id": "11", "name": "Benzină standard" },
///   { "id": "12", "name": "Benzină premium" },
///   { "id": "21", "name": "Motorină standard" },
///   { "id": "22", "name": "Motorină premium" },
///   { "id": "31", "name": "GPL" },
///   { "id": "41", "name": "Încărcare Electrică" }
/// ] }
/// ```
///
/// `41` (EV charging) is intentionally unmapped — electric coverage
/// comes from OpenChargeMap, not the fuel observatory.
class RomaniaObservatoryKeys {
  RomaniaObservatoryKeys._();

  /// Observatory gas-catalog product id → canonical [FuelType].
  static const Map<String, FuelType> fuelForCatalogProductId = {
    '11': FuelType.e5, // Benzină standard
    '12': FuelType.e98, // Benzină premium
    '21': FuelType.diesel, // Motorină standard
    '22': FuelType.dieselPremium, // Motorină premium
    '31': FuelType.lpg, // GPL
  };

  /// Lookup for an observatory catalog product id. Returns `null` for
  /// unknown / intentionally dropped ids (e.g. `41` EV charging).
  static FuelType? lookup(String catalogProductId) =>
      fuelForCatalogProductId[catalogProductId.trim()];

  /// Romanian pump prices are RON (lei) per litre with up to three
  /// decimals (e.g. `7.259`). Accepts `num` and numeric strings.
  /// Rejects zero and negative values.
  static double? parseLeiPerLitre(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) {
      if (raw <= 0) return null;
      return raw.toDouble();
    }
    if (raw is String) {
      final t = raw.trim();
      if (t.isEmpty) return null;
      final v = double.tryParse(t);
      if (v == null || v <= 0) return null;
      return v;
    }
    return null;
  }
}
