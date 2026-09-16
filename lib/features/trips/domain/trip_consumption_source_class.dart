// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/domain/consumption_estimate.dart';
import 'trip_fuel_source.dart';

/// The seam between the trip layer's [TripFuelSourceKind] and the
/// canonical [ConsumptionSourceClass] (#4230, Epic #4222).
///
/// ## Why the mapping lives here and not in `core/`
///
/// `feature_boundary_test` pins **core → feature at zero** (#3129), so
/// `core/domain/consumption_estimate.dart` cannot import
/// `features/trips/domain/trip_fuel_source.dart`. The canonical contract
/// therefore restates the four source classes itself, and the translation
/// sits on the feature side — the side that owns the trip vocabulary.
///
/// ## Why two enums rather than one
///
/// They answer the same question at different layers, and #4230's
/// merged-in #4207 content forbids adding a fifth *provenance* type while
/// also requiring a contract `core` consumers can speak. Restating four
/// cases across a boundary that must not be crossed is the smaller cost.
///
/// The `switch` below is exhaustive over [TripFuelSourceKind], so adding
/// a fifth kind is a **compile error here** rather than a silent
/// mis-mapping. That, plus `trip_consumption_source_class_test.dart`'s
/// parity assertions, is what keeps the two enums from drifting.
extension TripFuelSourceKindMapping on TripFuelSourceKind {
  /// This kind as the canonical class.
  ///
  /// The one deliberate rename: [TripFuelSourceKind.gps] becomes
  /// [ConsumptionSourceClass.gpsOnly]. "gps" beside "measured" and
  /// "estimated" reads like a third *quality*, when it is a GPS-only
  /// input set producing a modelled litre — the longer name says which.
  ConsumptionSourceClass get asConsumptionSourceClass => switch (this) {
        TripFuelSourceKind.measured => ConsumptionSourceClass.measured,
        TripFuelSourceKind.estimated => ConsumptionSourceClass.estimated,
        TripFuelSourceKind.gps => ConsumptionSourceClass.gpsOnly,
        TripFuelSourceKind.none => ConsumptionSourceClass.none,
      };
}
