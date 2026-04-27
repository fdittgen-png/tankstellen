import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/domain/services/tank_level_estimator.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/consumption/providers/tank_level_provider.dart';
import 'package:tankstellen/features/consumption/providers/trip_history_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

/// Unit tests for the `tankLevelProvider` orchestration (Refs #561).
///
/// The pure math lives in [estimateTankLevel] and is covered by
/// `tank_level_estimator_test.dart`. These tests pin only the wiring
/// the provider adds on top of the helper:
///   * unknown sentinel for unknown vehicles / no fill-ups
///   * fill-up vehicle filtering
///   * defensive newest-first sort
///   * trip filtering by vehicle, by lastFillUp date, and on null startedAt
///   * happy path matches the helper's output for the filtered inputs
class _StubVehicleProfileList extends VehicleProfileList {
  _StubVehicleProfileList(this._value);
  final List<VehicleProfile> _value;

  @override
  List<VehicleProfile> build() => _value;
}

class _StubFillUpList extends FillUpList {
  _StubFillUpList(this._value);
  final List<FillUp> _value;

  @override
  List<FillUp> build() => _value;
}

class _StubTripHistoryList extends TripHistoryList {
  _StubTripHistoryList(this._value);
  final List<TripHistoryEntry> _value;

  @override
  List<TripHistoryEntry> build() => _value;
}

void main() {
  // 50 L combustion vehicle. Same shape as the estimator-test fixture
  // so we can call [estimateTankLevel] directly and compare field-wise.
  const vehicle = VehicleProfile(
    id: 'v1',
    name: 'Test Car',
    type: VehicleType.combustion,
    tankCapacityL: 50,
  );

  const otherVehicle = VehicleProfile(
    id: 'v2',
    name: 'Other Car',
    type: VehicleType.combustion,
    tankCapacityL: 60,
  );

  FillUp fillUp({
    required String id,
    required DateTime date,
    String vehicleId = 'v1',
    double liters = 45,
  }) {
    return FillUp(
      id: id,
      date: date,
      liters: liters,
      totalCost: liters * 1.8,
      odometerKm: 100000,
      fuelType: FuelType.diesel,
      vehicleId: vehicleId,
    );
  }

  TripHistoryEntry trip({
    required String id,
    required DateTime? startedAt,
    required double distanceKm,
    String vehicleId = 'v1',
    double? fuelLitersConsumed,
  }) {
    return TripHistoryEntry(
      id: id,
      vehicleId: vehicleId,
      summary: TripSummary(
        distanceKm: distanceKm,
        maxRpm: 0,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        fuelLitersConsumed: fuelLitersConsumed,
        startedAt: startedAt,
      ),
    );
  }

  ProviderContainer makeContainer({
    List<VehicleProfile> vehicles = const [],
    List<FillUp> fillUps = const [],
    List<TripHistoryEntry> trips = const [],
  }) {
    final c = ProviderContainer(overrides: [
      vehicleProfileListProvider
          .overrideWith(() => _StubVehicleProfileList(vehicles)),
      fillUpListProvider.overrideWith(() => _StubFillUpList(fillUps)),
      tripHistoryListProvider.overrideWith(() => _StubTripHistoryList(trips)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('tankLevelProvider — unknown sentinel', () {
    test('vehicleId not matching any stored vehicle → unknown', () {
      final c = makeContainer(
        vehicles: const [vehicle],
        fillUps: [
          fillUp(id: 'f1', date: DateTime(2026, 4, 1)),
        ],
      );

      final result = c.read(tankLevelProvider('does-not-exist'));

      expect(result.hasFillUp, isFalse);
      expect(result.lastFillUpDate, isNull);
      expect(result.levelL, 0);
      expect(result.capacityL, isNull);
    });

    test('matched vehicle with zero fill-ups for it → unknown', () {
      // The list contains a fill-up — but for OTHER vehicle. After the
      // vehicleId filter, the per-vehicle list is empty, so the
      // provider must still return the unknown sentinel.
      final c = makeContainer(
        vehicles: const [vehicle, otherVehicle],
        fillUps: [
          fillUp(id: 'f1', date: DateTime(2026, 4, 1), vehicleId: 'v2'),
        ],
      );

      final result = c.read(tankLevelProvider('v1'));

      expect(result.hasFillUp, isFalse);
      expect(result.lastFillUpDate, isNull);
      expect(result.levelL, 0);
    });
  });

  group('tankLevelProvider — fill-up filtering', () {
    test('fill-ups for other vehicles are excluded', () {
      // v1 has one fill-up logging 45 L on Apr 1. v2 has a much later
      // fill-up — if the provider didn't filter, it would pick v2's
      // date as `lastFillUpDate`.
      final v1FillUp = fillUp(id: 'f1', date: DateTime(2026, 4, 1));
      final v2FillUp =
          fillUp(id: 'f2', date: DateTime(2026, 4, 25), vehicleId: 'v2');

      final c = makeContainer(
        vehicles: const [vehicle, otherVehicle],
        fillUps: [v2FillUp, v1FillUp],
      );

      final result = c.read(tankLevelProvider('v1'));

      // Only v1's fill-up was considered → its date wins.
      expect(result.lastFillUpDate, v1FillUp.date);
      // No trips after Apr 1 in this container, so level is full
      // capacity (50 L) and method is the vacuous obd2.
      expect(result.levelL, 50);
      expect(result.capacityL, 50);
      expect(result.tripsSince, 0);
      expect(result.method, TankLevelEstimationMethod.obd2);
    });

    test('fill-ups passed oldest-first are still treated newest-first '
        'by the helper (defensive sort)', () {
      // Fill-ups deliberately oldest-first to prove the provider
      // re-sorts before delegating. The helper consults only the head
      // entry, so picking the wrong head would change the answer:
      //   - oldest as "last": Apr 1, capacity 50, no trips after that
      //     → trips between Apr 1 and Apr 20 would be folded in.
      //   - newest as "last" (correct): Apr 20, no trips after that
      //     → level == capacity, no consumption.
      final oldest = fillUp(id: 'f-old', date: DateTime(2026, 4, 1));
      final newest = fillUp(id: 'f-new', date: DateTime(2026, 4, 20));
      final tripBetween = trip(
        id: 't-mid',
        startedAt: DateTime(2026, 4, 10),
        distanceKm: 100,
        fuelLitersConsumed: 10,
      );

      final c = makeContainer(
        vehicles: const [vehicle],
        fillUps: [oldest, newest], // intentionally oldest-first
        trips: [tripBetween],
      );

      final result = c.read(tankLevelProvider('v1'));

      // Provider sorted internally → newest is the head → trip is
      // BEFORE the head and is excluded.
      expect(result.lastFillUpDate, newest.date);
      expect(result.tripsSince, 0);
      expect(result.levelL, 50);
    });
  });

  group('tankLevelProvider — trip filtering', () {
    test('trips before the most recent fill-up are excluded', () {
      final lastFillUp = fillUp(id: 'f1', date: DateTime(2026, 4, 1, 8));
      final tripBefore = trip(
        id: 't-old',
        startedAt: DateTime(2026, 3, 20),
        distanceKm: 100,
        fuelLitersConsumed: 10,
      );
      final tripAfter = trip(
        id: 't-new',
        startedAt: DateTime(2026, 4, 1, 10),
        distanceKm: 30,
        fuelLitersConsumed: 2,
      );

      final c = makeContainer(
        vehicles: const [vehicle],
        fillUps: [lastFillUp],
        trips: [tripBefore, tripAfter],
      );

      final result = c.read(tankLevelProvider('v1'));

      // 50 - 2 = 48; only the post-fill-up trip is folded in.
      expect(result.tripsSince, 1);
      expect(result.levelL, closeTo(48, 0.001));
    });

    test('trips with startedAt == null are dropped from the helper input',
        () {
      final lastFillUp = fillUp(id: 'f1', date: DateTime(2026, 4, 1));
      final nullStart = trip(
        id: 't-null',
        startedAt: null,
        distanceKm: 50,
        fuelLitersConsumed: 5,
      );
      final realTrip = trip(
        id: 't-real',
        startedAt: DateTime(2026, 4, 2),
        distanceKm: 30,
        fuelLitersConsumed: 2,
      );

      final c = makeContainer(
        vehicles: const [vehicle],
        fillUps: [lastFillUp],
        trips: [nullStart, realTrip],
      );

      final result = c.read(tankLevelProvider('v1'));

      // Only the real trip survives the filter; null-start stays out.
      expect(result.tripsSince, 1);
      expect(result.levelL, closeTo(48, 0.001));
    });

    test('trips for other vehicles are excluded', () {
      final lastFillUp = fillUp(id: 'f1', date: DateTime(2026, 4, 1));
      final v1Trip = trip(
        id: 't-v1',
        startedAt: DateTime(2026, 4, 2),
        distanceKm: 30,
        fuelLitersConsumed: 2,
      );
      final v2Trip = trip(
        id: 't-v2',
        startedAt: DateTime(2026, 4, 3),
        distanceKm: 100,
        fuelLitersConsumed: 9,
        vehicleId: 'v2',
      );

      final c = makeContainer(
        vehicles: const [vehicle, otherVehicle],
        fillUps: [lastFillUp],
        trips: [v1Trip, v2Trip],
      );

      final result = c.read(tankLevelProvider('v1'));

      // v2's trip is excluded → only v1's 2 L counted.
      expect(result.tripsSince, 1);
      expect(result.levelL, closeTo(48, 0.001));
    });

    test('a trip starting exactly at lastFillUpDate is kept '
        '(at-or-after, not strictly-after)', () {
      final fillDate = DateTime(2026, 4, 1, 8);
      final lastFillUp = fillUp(id: 'f1', date: fillDate);
      final exactTrip = trip(
        id: 't-exact',
        startedAt: fillDate, // exactly at the boundary
        distanceKm: 30,
        fuelLitersConsumed: 2,
      );

      final c = makeContainer(
        vehicles: const [vehicle],
        fillUps: [lastFillUp],
        trips: [exactTrip],
      );

      final result = c.read(tankLevelProvider('v1'));

      expect(result.tripsSince, 1);
      expect(result.levelL, closeTo(48, 0.001));
    });
  });

  group('tankLevelProvider — happy path', () {
    test('matches estimateTankLevel for the filtered, sorted inputs', () {
      // Mixed inputs: two fill-ups (oldest-first to exercise the
      // sort), one trip for v2 (must be excluded), one trip with
      // null startedAt (must be dropped), one real trip.
      final oldFill = fillUp(id: 'f-old', date: DateTime(2026, 3, 15));
      final newFill = fillUp(id: 'f-new', date: DateTime(2026, 4, 1));
      final v1TripObd = trip(
        id: 't1',
        startedAt: DateTime(2026, 4, 2, 9),
        distanceKm: 30,
        fuelLitersConsumed: 2.5,
      );
      final v1TripFallback = trip(
        id: 't2',
        startedAt: DateTime(2026, 4, 3, 10),
        distanceKm: 40,
        // no fuelLitersConsumed → fallback path
      );
      final v2Trip = trip(
        id: 't-v2',
        startedAt: DateTime(2026, 4, 5),
        distanceKm: 100,
        fuelLitersConsumed: 8,
        vehicleId: 'v2',
      );
      final nullStart = trip(
        id: 't-null',
        startedAt: null,
        distanceKm: 999,
        fuelLitersConsumed: 99,
      );

      final c = makeContainer(
        vehicles: const [vehicle, otherVehicle],
        fillUps: [oldFill, newFill],
        trips: [v1TripObd, v2Trip, nullStart, v1TripFallback],
      );

      final result = c.read(tankLevelProvider('v1'));

      // Compute the expected estimate by hand-applying the same
      // filters the provider promises and calling the pure helper.
      final expectedFillUps = [newFill, oldFill]; // newest-first
      final expectedTrips = [v1TripObd, v1TripFallback];
      final expected = estimateTankLevel(
        vehicle: vehicle,
        fillUps: expectedFillUps,
        trips: expectedTrips,
      );

      expect(result.levelL, closeTo(expected.levelL, 0.0001));
      expect(result.capacityL, expected.capacityL);
      expect(result.lastFillUpDate, expected.lastFillUpDate);
      expect(result.method, expected.method);
      expect(result.rangeKm, closeTo(expected.rangeKm!, 0.0001));
      expect(result.tripsSince, expected.tripsSince);

      // Sanity: this configuration should genuinely exercise the
      // mixed branch (one OBD2 + one fallback trip after the latest
      // fill-up).
      expect(result.method, TankLevelEstimationMethod.mixed);
      expect(result.tripsSince, 2);
    });
  });
}
