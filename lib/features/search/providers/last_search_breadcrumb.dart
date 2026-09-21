// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../../core/domain/fuel_type.dart';
import '../../../core/domain/search_params.dart' show SortBy;

/// #2320 — the anonymised breadcrumb of the most recent search that error
/// traces carry: which entry point, fuel, radius and sort. Deliberately
/// PII-free BY SIGNATURE — there is no parameter a coordinate, ZIP code or
/// location label could arrive through. Nulls read "default" (the value is
/// resolved from the active profile inside the search). Extracted from
/// `SearchState` so the contract is executable (#4235).
String lastSearchBreadcrumb(
  String mode, {
  FuelType? fuelType,
  double? radiusKm,
  SortBy? sortBy,
}) {
  final fuel = fuelType?.name ?? 'default';
  final radius = radiusKm?.toStringAsFixed(0) ?? 'default';
  final sort = sortBy?.apiValue ?? 'default';
  return 'mode=$mode fuel=$fuel radiusKm=$radius sort=$sort';
}
