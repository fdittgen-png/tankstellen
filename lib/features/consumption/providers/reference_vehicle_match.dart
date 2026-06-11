// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/error_logger.dart';
import '../../vehicle/data/reference_vehicle_catalog_provider.dart';
import '../../vehicle/data/vehicle_profile_catalog_matcher.dart';
import '../../vehicle/domain/entities/reference_vehicle.dart';
import '../../../core/domain/vehicle_profile.dart';

/// Resolve the bundled-catalog row for [profile] (#1422 phase 1), so the
/// OBD2 recording controller can use the engine-tech-derived η_v default
/// instead of the legacy 0.85 literal until VeLearner converges.
///
/// Returns null when the profile is null, the catalog hasn't loaded, or no
/// tier hits. Swallows provider-wiring errors so widget tests don't have to
/// override the catalog graph just to start a recording. Extracted from
/// `Obd2RecordingPipeline` (#2506) to keep that file under the 400-line cap
/// while #2187/#2188/#2190 decompose the surrounding recording stack.
ReferenceVehicle? tryMatchReferenceVehicle(Ref ref, VehicleProfile? profile) {
  if (profile == null) return null;
  try {
    final catalog = ref.read(referenceVehicleCatalogProvider).value;
    if (catalog == null || catalog.isEmpty) return null;
    return VehicleProfileCatalogMatcher.bestMatch(
      profile: profile,
      catalog: catalog,
    );
  } catch (e, st) {
    unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {
      'where': 'Obd2RecordingPipeline: reference catalog unavailable'
    }));
    return null;
  }
}
