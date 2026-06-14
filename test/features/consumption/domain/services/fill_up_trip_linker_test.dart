// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/domain/services/fill_up_trip_linker.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

/// #3138 — pins the plein-to-plein window semantics (#1361 / #888) now that the
/// linking math lives in the pure [FillUpTripLinker] (extracted out of the
/// `FillUpList` notifier). All behaviour is a function of the inputs — no
/// Riverpod, no Hive.

DateTime _d(int day) => DateTime.utc(2026, 6, day);

FillUp _fill({
  required String id,
  required int day,
  String? vehicleId = 'veh-a',
  bool isFullTank = true,
  bool isCorrection = false,
  List<String> linkedTripIds = const [],
}) =>
    FillUp(
      id: id,
      date: _d(day),
      liters: 40,
      totalCost: 60,
      odometerKm: 10000,
      fuelType: FuelType.e10,
      vehicleId: vehicleId,
      isFullTank: isFullTank,
      isCorrection: isCorrection,
      linkedTripIds: linkedTripIds,
    );

TripSummary _summary(DateTime start) => TripSummary(
      distanceKm: 12,
      maxRpm: 2800,
      highRpmSeconds: 10,
      idleSeconds: 30,
      harshBrakes: 0,
      harshAccelerations: 0,
      startedAt: start,
      endedAt: start.add(const Duration(minutes: 20)),
    );

TripHistoryEntry _trip(String id, int day, {String? vehicleId = 'veh-a'}) =>
    TripHistoryEntry(
      id: id,
      vehicleId: vehicleId,
      summary: _summary(_d(day)),
    );

void main() {
  const linker = FillUpTripLinker();

  group('windowFor', () {
    test('prior plein → lower bound is that plein, EXCLUSIVE', () {
      final closing = _fill(id: 'b', day: 20);
      final priorPlein = _fill(id: 'a', day: 10);
      final window = linker.windowFor(closing, [priorPlein, closing]);

      expect(window.start, _d(10));
      expect(window.inclusiveLower, isFalse);
      expect(window.upper, _d(20));
      // the prior plein's own date is excluded; the day after is in.
      expect(window.contains(_d(10)), isFalse);
      expect(window.contains(_d(11)), isTrue);
      expect(window.contains(_d(20)), isTrue); // upper inclusive
      expect(window.contains(_d(21)), isFalse);
    });

    test('no prior plein but earlier fills → earliest fill, INCLUSIVE', () {
      final closing = _fill(id: 'c', day: 20);
      final partialA = _fill(id: 'a', day: 8, isFullTank: false);
      final partialB = _fill(id: 'b', day: 12, isFullTank: false);
      final window = linker.windowFor(closing, [partialA, partialB, closing]);

      expect(window.start, _d(8));
      expect(window.inclusiveLower, isTrue);
      expect(window.contains(_d(8)), isTrue); // earliest fill IS in window
    });

    test('no prior fills at all → no lower bound (legacy #888)', () {
      final closing = _fill(id: 'a', day: 20);
      final window = linker.windowFor(closing, [closing]);

      expect(window.start, isNull);
      expect(window.contains(_d(1)), isTrue); // everything before upper qualifies
      expect(window.contains(_d(21)), isFalse);
    });
  });

  group('linkedTripIdsInWindow', () {
    test('returns only the in-window, same-vehicle trips', () {
      final closing = _fill(id: 'plein', day: 20);
      final priorPlein = _fill(id: 'prev', day: 10);
      final history = [
        _trip('t-early', 9), // before the prior plein → out
        _trip('t-in1', 12), // in window
        _trip('t-in2', 18), // in window
        _trip('t-other', 15, vehicleId: 'veh-b'), // other vehicle → out
        _trip('t-late', 25), // after closing → out
      ];

      final ids = linker.linkedTripIdsInWindow(
        fillUp: closing,
        history: history,
        allFills: [priorPlein, closing],
      );

      expect(ids, ['t-in1', 't-in2']);
    });

    test('empty when the fill-up has no vehicle bound', () {
      final closing = _fill(id: 'x', day: 20, vehicleId: null);
      expect(
        linker.linkedTripIdsInWindow(
          fillUp: closing,
          history: [_trip('t', 12, vehicleId: null)],
          allFills: [closing],
        ),
        isEmpty,
      );
    });
  });

  group('siblingsInWindow', () {
    test('the partials in the open window, excluding corrections + the close',
        () {
      final closing = _fill(id: 'plein', day: 20);
      final priorPlein = _fill(id: 'prev', day: 10);
      final partial = _fill(id: 'partial', day: 14, isFullTank: false);
      final correction = _fill(id: 'corr', day: 15, isCorrection: true);

      final siblings = linker.siblingsInWindow(
        fillUp: closing,
        allFills: [priorPlein, partial, correction, closing],
      );

      // prior plein is the EXCLUSIVE lower bound (out); the partial is in;
      // the correction is filtered; the closing fill itself is excluded.
      expect(siblings.map((f) => f.id), ['partial']);
    });
  });
}
