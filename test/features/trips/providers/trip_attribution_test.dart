// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/api.dart';

/// #4364 acceptance box 3 — the history browser and a comparison need
/// different attribution, so they get different providers.
class _FakeTripList extends TripHistoryList {
  _FakeTripList(this._value);
  final List<TripHistoryEntry> _value;
  @override
  List<TripHistoryEntry> build() => _value;
}

TripHistoryEntry _trip(String id, String? vehicleId, int day) =>
    TripHistoryEntry(
      id: id,
      vehicleId: vehicleId,
      summary: TripSummary(
        distanceKm: 20,
        maxRpm: 3000,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        fuelLitersConsumed: 1.2,
        avgLPer100Km: 6,
        startedAt: DateTime.utc(2026, 1, day, 8),
        endedAt: DateTime.utc(2026, 1, day, 9),
      ),
    );

void main() {
  final trips = [
    _trip('t1', 'a', 1),
    _trip('t2', null, 2),
    _trip('t3', 'b', 3),
  ];

  ProviderContainer container() {
    final c = ProviderContainer(overrides: [
      tripHistoryListProvider.overrideWith(() => _FakeTripList(trips)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('the history browser still keeps unassigned trips (#889)', () {
    final c = container();
    expect(c.read(tripsForVehicleProvider('a')).map((t) => t.id),
        containsAll(['t1', 't2']));
  });

  test('strict attribution credits an unassigned trip to nobody', () {
    final c = container();
    expect(c.read(tripsAttributedToVehicleProvider('a')).map((t) => t.id),
        ['t1']);
    expect(c.read(tripsAttributedToVehicleProvider('b')).map((t) => t.id),
        ['t3']);
  });

  test('the unassigned trips are counted once, not per vehicle', () {
    final c = container();
    expect(c.read(unattributedTripCountProvider), 1);
  });

  test('the predicate is the one both sides share', () {
    expect(tripIsAttributedTo(trips[0], 'a'), isTrue);
    expect(tripIsAttributedTo(trips[1], 'a'), isFalse);
    expect(tripIsAttributedTo(trips[1], 'b'), isFalse);
  });

  test('strict attribution keeps the newest-first ordering', () {
    final c = ProviderContainer(overrides: [
      tripHistoryListProvider.overrideWith(() => _FakeTripList([
            _trip('old', 'a', 1),
            _trip('new', 'a', 9),
          ])),
    ]);
    addTearDown(c.dispose);
    expect(c.read(tripsAttributedToVehicleProvider('a')).map((t) => t.id),
        ['new', 'old']);
  });
}
