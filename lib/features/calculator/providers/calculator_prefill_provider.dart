// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/price_utils.dart';
import '../../../core/utils/station_extensions.dart';
import '../../consumption/providers/consumption_providers.dart';
import '../../consumption/providers/trip_history_provider.dart';
import '../../profile/providers/effective_fuel_type_provider.dart';
import '../../search/domain/entities/station.dart';
import '../../search/providers/search_filters_provider.dart';
import '../../search/providers/search_provider.dart';
import '../../search/providers/selected_station_provider.dart';
import '../../vehicle/domain/entities/vehicle_profile.dart';
import '../../vehicle/providers/vehicle_providers.dart';

part 'calculator_prefill_provider.g.dart';

/// The "use mine" prefill values the calculator can pull from the rest
/// of the app (#2543). Every field is nullable so a cold-open
/// calculator — no recorded trip, no vehicle, no search — simply hides
/// the corresponding `ActionChip` instead of offering a bogus value.
///
/// [isEv] reflects the active vehicle so the consumption chip can label
/// itself with the right unit mask (`kWh/100 km` vs `L/100 km`).
class CalculatorPrefill {
  /// Distance of the most recent recorded trip, in km. Null when no
  /// trip history exists.
  final double? distanceKm;

  /// A representative consumption figure (L/100 km, or kWh/100 km for
  /// an EV) drawn from the active vehicle's aggregates, falling back to
  /// the fill-up consumption stats. Null when neither source has data.
  final double? consumptionPer100Km;

  /// Per-litre price the user is most likely planning around — the
  /// selected station's price for their effective fuel, else the
  /// cheapest nearby price. Null when no station price is available.
  final double? pricePerLiter;

  /// Whether the active vehicle is an EV / hybrid — drives the
  /// consumption chip's unit mask.
  final bool isEv;

  const CalculatorPrefill({
    this.distanceKm,
    this.consumptionPer100Km,
    this.pricePerLiter,
    this.isEv = false,
  });
}

/// Resolves the [CalculatorPrefill] from the live app state. Kept as a
/// provider (not inline in the screen) so the resolution priority is
/// independently testable and the screen stays thin.
@riverpod
CalculatorPrefill calculatorPrefill(Ref ref) {
  final vehicle = ref.watch(activeVehicleProfileProvider);
  return CalculatorPrefill(
    distanceKm: _resolveDistanceKm(ref),
    consumptionPer100Km: _resolveConsumption(ref, vehicle),
    pricePerLiter: _resolvePrice(ref),
    isEv: vehicle?.isEv ?? false,
  );
}

/// Last recorded trip's distance, or null when the history is empty.
double? _resolveDistanceKm(Ref ref) {
  final trips = ref.watch(tripHistoryListProvider);
  if (trips.isEmpty) return null;
  final d = trips.first.summary.distanceKm;
  return d > 0 ? d : null;
}

/// Representative consumption: active-vehicle aggregates first (the
/// vehicle the user actually drives), then the fill-up stats average,
/// then null (the screen keeps its 7.0 default and hides the chip).
double? _resolveConsumption(Ref ref, VehicleProfile? vehicle) {
  final fromVehicle = _vehicleAggregateConsumption(vehicle);
  if (fromVehicle != null) return fromVehicle;

  final stats = ref.watch(consumptionStatsProvider);
  final avg = stats.avgConsumptionL100km;
  if (avg != null && avg > 0) return avg;
  return null;
}

/// Distance-weighted mean consumption across the vehicle's trip-length
/// buckets, falling back to a time-share-weighted mean over the speed
/// histogram. Returns null when the vehicle (or its aggregates) carry
/// no usable data — the cold-start case.
double? _vehicleAggregateConsumption(VehicleProfile? vehicle) {
  if (vehicle == null) return null;

  final lengths = vehicle.tripLengthAggregates;
  if (lengths != null) {
    var weightedSum = 0.0;
    var totalKm = 0.0;
    for (final bucket in [lengths.short, lengths.medium, lengths.long]) {
      if (bucket == null || bucket.totalDistanceKm <= 0) continue;
      weightedSum += bucket.meanLPer100km * bucket.totalDistanceKm;
      totalKm += bucket.totalDistanceKm;
    }
    if (totalKm > 0) return weightedSum / totalKm;
  }

  final histogram = vehicle.speedConsumptionAggregates;
  if (histogram != null && histogram.bands.isNotEmpty) {
    var weightedSum = 0.0;
    var totalShare = 0.0;
    for (final band in histogram.bands) {
      if (band.timeShareFraction <= 0) continue;
      weightedSum += band.meanLPer100km * band.timeShareFraction;
      totalShare += band.timeShareFraction;
    }
    if (totalShare > 0) return weightedSum / totalShare;
  }

  return null;
}

/// Price to plan around: the selected station's price for the effective
/// fuel, else the cheapest nearby price across the current search
/// results. Null when no usable price exists.
double? _resolvePrice(Ref ref) {
  final fuel = ref.watch(effectiveFuelTypeProvider);

  final selectedId = ref.watch(selectedStationProvider);
  if (selectedId != null) {
    final stations = ref.watch(fuelStationsProvider);
    final Station? selected =
        stations.where((s) => s.id == selectedId).firstOrNull;
    final price = selected?.priceFor(fuel);
    if (price != null && price > 0) return price;
  }

  final stations = ref.watch(fuelStationsProvider);
  if (stations.isEmpty) return null;
  final (minP, _) = priceRange(stations, fuel, requirePositive: true);
  return minP > 0 ? minP : null;
}
