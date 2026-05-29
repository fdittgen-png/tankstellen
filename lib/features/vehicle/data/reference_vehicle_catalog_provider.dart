// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/entities/reference_vehicle.dart';

part 'reference_vehicle_catalog_provider.g.dart';

/// Asset path the catalog JSON ships at. Exposed so tests can override
/// the bundle and feed a fixture without copying the path string.
const String referenceVehicleCatalogAssetPath =
    'assets/reference_vehicles/vehicles.json';

/// Loads the bundled reference vehicle catalog (#950 phase 1).
///
/// `keepAlive: true` because the catalog is static for the lifetime of
/// the app — re-decoding the JSON on every read would be wasteful.
/// Phase 2 (obd2_service) and phase 4 (VehicleProfile migration) both
/// read this provider; the cached `List<ReferenceVehicle>` is shared.
@Riverpod(keepAlive: true)
Future<List<ReferenceVehicle>> referenceVehicleCatalog(Ref ref) async {
  // The asset load stays on the main isolate (rootBundle is not available
  // off it), but the ~142 KB JSON decode + N× fromJson deserialization is
  // pushed to a background isolate via compute() so it can't jank the UI
  // on first read (#2192). Mirrors the compute(_parseCsv, …) pattern in
  // argentina_station_service.dart.
  final raw = await rootBundle.loadString(referenceVehicleCatalogAssetPath);
  return compute(_parseCatalog, raw);
}

/// Top-level parser run on a background isolate by [referenceVehicleCatalog].
///
/// Decodes the catalog JSON and deserializes each entry into a
/// [ReferenceVehicle]. Must stay top-level (no captured state) so it can be
/// dispatched through [compute].
List<ReferenceVehicle> _parseCatalog(String json) {
  final decoded = jsonDecode(json);
  if (decoded is! List) {
    // The asset is checked into source — a malformed file is a
    // shipping bug, not a runtime condition. Throw loudly so CI
    // catches it via the catalog test.
    throw StateError(
      'Reference vehicle catalog must be a JSON array; '
      'got ${decoded.runtimeType}',
    );
  }
  return decoded
      .map((entry) =>
          ReferenceVehicle.fromJson(entry as Map<String, dynamic>))
      .toList(growable: false);
}

/// Returns the best catalog match for [make], [model], and [year], or
/// `null` if no entry covers the trio (#950 phase 1).
///
/// Lookup is case-insensitive on make + model, and inclusive on the
/// production-year window. While the catalog is loading, this returns
/// `null` (the AsyncValue is unresolved) — callers should re-watch the
/// underlying [referenceVehicleCatalogProvider] if they need to wait.
@Riverpod(keepAlive: true)
ReferenceVehicle? referenceVehicleByMakeModel(
  Ref ref, {
  required String make,
  required String model,
  required int year,
}) {
  final catalog =
      ref.watch(referenceVehicleCatalogProvider).value ?? const [];
  final lcMake = make.toLowerCase();
  final lcModel = model.toLowerCase();
  for (final v in catalog) {
    if (v.make.toLowerCase() == lcMake &&
        v.model.toLowerCase() == lcModel &&
        v.coversYear(year)) {
      return v;
    }
  }
  return null;
}
