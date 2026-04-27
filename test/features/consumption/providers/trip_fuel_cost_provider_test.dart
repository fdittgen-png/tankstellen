import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/domain/services/trip_fuel_cost_estimator.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/consumption/providers/trip_fuel_cost_provider.dart';
import 'package:tankstellen/features/consumption/providers/trip_history_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// Unit tests for `tripFuelCostProvider` (Refs #561).
///
/// The provider's pure helper [estimateTripFuelCost] is covered by
/// `trip_fuel_cost_estimator_test.dart` — these tests intentionally
/// pin the orchestration around it: trip lookup, vehicle filtering,
/// defensive newest-first sort, and null short-circuits when the
/// inputs do not yield a usable price.
void main() {
  group('tripFuelCostProvider', () {
    test('returns null when tripId does not match any history entry', () {
      final container = _container(
        trips: [_trip(id: 'trip-1', vehicleId: 'v1')],
        fillUps: [_fillUp(id: 'f1', vehicleId: 'v1')],
      );

      expect(container.read(tripFuelCostProvider('missing')), isNull);
    });

    test('returns null when the matched trip has no vehicleId', () {
      final container = _container(
        trips: [_trip(id: 'trip-1', vehicleId: null)],
        fillUps: [_fillUp(id: 'f1', vehicleId: 'v1')],
      );

      expect(container.read(tripFuelCostProvider('trip-1')), isNull);
    });

    test('returns null when the global fill-up list is empty', () {
      final container = _container(
        trips: [_trip(id: 'trip-1', vehicleId: 'v1')],
        fillUps: const [],
      );

      expect(container.read(tripFuelCostProvider('trip-1')), isNull);
    });

    test(
        'returns null when no fill-up matches the trip vehicle '
        '(vehicle filter empties the list)', () {
      final container = _container(
        trips: [_trip(id: 'trip-1', vehicleId: 'v1')],
        // Both fill-ups belong to a DIFFERENT vehicle — after the
        // provider's vehicle filter the list is empty, so the cost
        // must be null instead of leaking another car's price.
        fillUps: [
          _fillUp(id: 'f-other-1', vehicleId: 'other'),
          _fillUp(id: 'f-other-2', vehicleId: 'other'),
        ],
      );

      expect(container.read(tripFuelCostProvider('trip-1')), isNull);
    });

    test(
        'ignores fill-ups for other vehicles even when they would '
        'otherwise be the most recent eligible price', () {
      final tripStart = DateTime(2026, 4, 25, 14);
      final trip = _trip(
        id: 'trip-1',
        vehicleId: 'v1',
        fuelLitersConsumed: 0.5,
        startedAt: tripStart,
      );
      // The "other vehicle" fill-up is NEWER and would dominate if
      // the provider failed to filter by vehicle. The v1 fill-up is
      // older but still eligible — it's the one that must drive the
      // returned cost.
      final ownFillUp = _fillUp(
        id: 'f-own',
        vehicleId: 'v1',
        date: DateTime(2026, 4, 20, 9),
        liters: 40,
        totalCost: 60, // 1.50 €/L
      );
      final otherVehicleFillUp = _fillUp(
        id: 'f-other',
        vehicleId: 'other',
        date: DateTime(2026, 4, 24, 9),
        liters: 40,
        totalCost: 100, // 2.50 €/L — would be picked if not filtered
      );
      final container = _container(
        trips: [trip],
        fillUps: [otherVehicleFillUp, ownFillUp],
      );

      final cost = container.read(tripFuelCostProvider('trip-1'));
      expect(cost, isNotNull);
      // Must come from the v1 fill-up (1.50), not the other vehicle.
      expect(cost!, closeTo(0.5 * 1.50, 1e-9));
    });

    test(
        'sorts the filtered fill-ups newest-first defensively before '
        'delegating to the helper', () {
      // Hand the provider an OLDEST-first list to simulate a malformed
      // import. The helper documents "newest first" — if the provider
      // didn't re-sort, the helper would return the OLDEST eligible
      // price (1.50 €/L) instead of the most recent one (2.00 €/L).
      final tripStart = DateTime(2026, 4, 25, 14);
      final trip = _trip(
        id: 'trip-1',
        vehicleId: 'v1',
        fuelLitersConsumed: 1.0,
        startedAt: tripStart,
      );
      final oldest = _fillUp(
        id: 'f-old',
        vehicleId: 'v1',
        date: DateTime(2026, 4, 1, 9),
        liters: 40,
        totalCost: 60, // 1.50 €/L
      );
      final newest = _fillUp(
        id: 'f-new',
        vehicleId: 'v1',
        date: DateTime(2026, 4, 24, 9),
        liters: 40,
        totalCost: 80, // 2.00 €/L — must be picked
      );
      final container = _container(
        trips: [trip],
        // Oldest first — the provider must re-sort before delegating.
        fillUps: [oldest, newest],
      );

      final cost = container.read(tripFuelCostProvider('trip-1'));
      expect(cost, isNotNull);
      expect(cost!, closeTo(2.0, 1e-9));
    });

    test(
        'happy path matches estimateTripFuelCost over the filtered + '
        'newest-first sorted inputs', () {
      final tripStart = DateTime(2026, 4, 25, 14);
      final trip = _trip(
        id: 'trip-1',
        vehicleId: 'v1',
        fuelLitersConsumed: 0.27,
        startedAt: tripStart,
      );
      final v1Newer = _fillUp(
        id: 'f-v1-new',
        vehicleId: 'v1',
        date: DateTime(2026, 4, 24, 9),
        liters: 40,
        totalCost: 66, // 1.65 €/L — expected to drive the cost
      );
      final v1Older = _fillUp(
        id: 'f-v1-old',
        vehicleId: 'v1',
        date: DateTime(2026, 4, 1, 9),
        liters: 40,
        totalCost: 60, // 1.50 €/L
      );
      final otherVehicle = _fillUp(
        id: 'f-other',
        vehicleId: 'other',
        date: DateTime(2026, 4, 26, 9),
        liters: 40,
        totalCost: 200, // would-be-newest noise
      );
      // Provider input is intentionally messy: oldest-first AND
      // contains a foreign vehicle — exercises both filter and sort.
      final container = _container(
        trips: [trip],
        fillUps: [v1Older, otherVehicle, v1Newer],
      );

      // Compute the helper's expected output over the manually
      // filtered + newest-first sorted list. Keeps the test focused
      // on the provider's orchestration rather than the helper's math.
      final expected = estimateTripFuelCost(
        trip: trip,
        fillUpsForVehicle: [v1Newer, v1Older],
      );

      final actual = container.read(tripFuelCostProvider('trip-1'));
      expect(actual, isNotNull);
      expect(expected, isNotNull);
      expect(actual!, closeTo(expected!, 1e-9));
    });
  });
}

/// Fake [TripHistoryList] that returns a fixed list — sidesteps Hive
/// so we can exercise the provider's wiring with synthetic data.
class _FakeTripHistoryList extends TripHistoryList {
  _FakeTripHistoryList(this._value);
  final List<TripHistoryEntry> _value;

  @override
  List<TripHistoryEntry> build() => _value;
}

/// Fake [FillUpList] that returns a fixed list — same idea, no repo.
class _FakeFillUpList extends FillUpList {
  _FakeFillUpList(this._value);
  final List<FillUp> _value;

  @override
  List<FillUp> build() => _value;
}

ProviderContainer _container({
  required List<TripHistoryEntry> trips,
  required List<FillUp> fillUps,
}) {
  final container = ProviderContainer(overrides: [
    tripHistoryListProvider.overrideWith(() => _FakeTripHistoryList(trips)),
    fillUpListProvider.overrideWith(() => _FakeFillUpList(fillUps)),
  ]);
  addTearDown(container.dispose);
  return container;
}

TripHistoryEntry _trip({
  required String id,
  required String? vehicleId,
  double? fuelLitersConsumed = 0.27,
  DateTime? startedAt,
}) {
  return TripHistoryEntry(
    id: id,
    vehicleId: vehicleId,
    summary: TripSummary(
      distanceKm: 10,
      maxRpm: 0,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
      fuelLitersConsumed: fuelLitersConsumed,
      startedAt: startedAt ?? DateTime(2026, 4, 25, 14),
      distanceSource: 'virtual',
    ),
  );
}

FillUp _fillUp({
  required String id,
  required String vehicleId,
  DateTime? date,
  double liters = 40,
  double totalCost = 66,
}) {
  return FillUp(
    id: id,
    date: date ?? DateTime(2026, 4, 24, 9),
    liters: liters,
    totalCost: totalCost,
    odometerKm: 0,
    fuelType: FuelType.e10,
    vehicleId: vehicleId,
  );
}
