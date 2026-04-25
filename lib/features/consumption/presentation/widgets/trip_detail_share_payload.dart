import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../data/trip_history_repository.dart';
import 'trip_detail_charts.dart';

/// Structured clipboard payload for the Share action on the trip
/// detail screen (#890): JSON header summarising the trip, followed
/// by a CSV block of every sample. This keeps the action useful for
/// both machines (paste into a diff tool) and humans (skim in a text
/// editor).
///
/// The implementation is shared with [buildTripDetailSharePayload],
/// which re-exposes the same function under a `@visibleForTesting`
/// name so tests can assert on the exact text written to the
/// clipboard while production code keeps using the unrestricted
/// helper.
String tripDetailSharePayload({
  required TripHistoryEntry entry,
  required VehicleProfile? vehicle,
  required List<TripDetailSample> samples,
}) {
  final s = entry.summary;
  final summary = <String, dynamic>{
    'id': entry.id,
    if (vehicle != null) 'vehicle': vehicle.name,
    if (entry.vehicleId != null) 'vehicleId': entry.vehicleId,
    if (s.startedAt != null) 'startedAt': s.startedAt!.toIso8601String(),
    if (s.endedAt != null) 'endedAt': s.endedAt!.toIso8601String(),
    'distanceKm': s.distanceKm,
    'distanceSource': s.distanceSource,
    if (s.avgLPer100Km != null) 'avgLPer100Km': s.avgLPer100Km,
    if (s.fuelLitersConsumed != null)
      'fuelLitersConsumed': s.fuelLitersConsumed,
    'maxRpm': s.maxRpm,
    'highRpmSeconds': s.highRpmSeconds,
    'idleSeconds': s.idleSeconds,
    'harshBrakes': s.harshBrakes,
    'harshAccelerations': s.harshAccelerations,
    'sampleCount': samples.length,
  };
  const encoder = JsonEncoder.withIndent('  ');
  final csvBuffer = StringBuffer()
    ..writeln('timestamp,speedKmh,rpm,fuelRateLPerHour');
  for (final sample in samples) {
    csvBuffer
      ..write(sample.timestamp.toIso8601String())
      ..write(',')
      ..write(sample.speedKmh.toStringAsFixed(2))
      ..write(',')
      ..write(sample.rpm?.toStringAsFixed(0) ?? '')
      ..write(',')
      ..writeln(sample.fuelRateLPerHour?.toStringAsFixed(3) ?? '');
  }
  return '${encoder.convert(summary)}\n\n${csvBuffer.toString()}';
}

/// Test-only alias of [tripDetailSharePayload].
///
/// Exposed under the historical `@visibleForTesting` name so existing
/// tests (which assert on the exact text copied to the clipboard) can
/// keep importing the same symbol after the share-payload helper was
/// extracted out of `trip_detail_screen.dart`.
@visibleForTesting
String buildTripDetailSharePayload({
  required TripHistoryEntry entry,
  required VehicleProfile? vehicle,
  required List<TripDetailSample> samples,
}) =>
    tripDetailSharePayload(
      entry: entry,
      vehicle: vehicle,
      samples: samples,
    );
