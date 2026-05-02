import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/domain/services/reconciler.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// Unit tests for [Reconciler] (#1361 phase 2a). The reconciler is
/// pure — every test passes inputs directly and asserts on the
/// returned [ReconciliationResult] without touching Hive or Riverpod.
void main() {
  const reconciler = Reconciler();

  FillUp makePlein({
    required String id,
    required DateTime date,
    required double liters,
    double odometerKm = 10000,
    String vehicleId = 'veh-a',
    bool isFullTank = true,
  }) =>
      FillUp(
        id: id,
        date: date,
        liters: liters,
        totalCost: liters * 1.5,
        odometerKm: odometerKm,
        fuelType: FuelType.e10,
        vehicleId: vehicleId,
        isFullTank: isFullTank,
      );

  TripSummary makeTrip({
    required DateTime startedAt,
    required double fuel,
    double distanceKm = 100,
  }) =>
      TripSummary(
        distanceKm: distanceKm,
        maxRpm: 0,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        fuelLitersConsumed: fuel,
        startedAt: startedAt,
        endedAt: startedAt.add(const Duration(hours: 1)),
      );

  group('Reconciler.reconcile', () {
    test('returns null when closing fill is not a plein', () {
      final partial = makePlein(
        id: 'partial',
        date: DateTime(2026, 4, 15),
        liters: 20,
        isFullTank: false,
      );
      final result = reconciler.reconcile(
        closingPlein: partial,
        allFillUpsForVehicle: const [],
        tripsForVehicle: const [],
      );
      expect(result, isNull);
    });

    test(
        'single plein with no trips → action skippedNoTrips, no '
        'correction', () {
      final plein = makePlein(
        id: 'p1',
        date: DateTime(2026, 4, 15),
        liters: 40,
      );
      final result = reconciler.reconcile(
        closingPlein: plein,
        allFillUpsForVehicle: [plein],
        tripsForVehicle: const [],
      );
      expect(result, isNotNull);
      expect(result!.action, ReconciliationAction.skippedNoTrips);
      expect(result.correction, isNull);
      expect(result.pumped, 40);
      expect(result.consumed, 0);
    });

    test(
        'plein with trips but gap below absolute threshold → '
        'skippedBelowThreshold', () {
      final prevPlein = makePlein(
        id: 'p0',
        date: DateTime(2026, 4, 1),
        liters: 40,
      );
      final closingPlein = makePlein(
        id: 'p1',
        date: DateTime(2026, 4, 15),
        liters: 40,
        odometerKm: 10500,
      );
      final trips = [
        makeTrip(
          startedAt: DateTime(2026, 4, 5),
          fuel: 39.7, // gap = 0.3 L (< 0.5 L absolute floor)
        ),
      ];
      final result = reconciler.reconcile(
        closingPlein: closingPlein,
        allFillUpsForVehicle: [prevPlein, closingPlein],
        tripsForVehicle: trips,
      );
      expect(result, isNotNull);
      expect(result!.action, ReconciliationAction.skippedBelowThreshold);
      expect(result.correction, isNull);
      expect(result.pumped, 40);
      expect(result.consumed, closeTo(39.7, 0.001));
    });

    test(
        'plein with trips, gap below relative threshold → '
        'skippedBelowThreshold', () {
      // pumped = 40, gap must exceed both 0.5 L AND 5 % of 40 = 2.0 L.
      // gap of 1 L passes the absolute floor but fails the relative
      // floor.
      final prevPlein = makePlein(
        id: 'p0',
        date: DateTime(2026, 4, 1),
        liters: 40,
      );
      final closingPlein = makePlein(
        id: 'p1',
        date: DateTime(2026, 4, 15),
        liters: 40,
        odometerKm: 10500,
      );
      final trips = [
        makeTrip(startedAt: DateTime(2026, 4, 5), fuel: 39.0),
      ];
      final result = reconciler.reconcile(
        closingPlein: closingPlein,
        allFillUpsForVehicle: [prevPlein, closingPlein],
        tripsForVehicle: trips,
      );
      expect(result!.action, ReconciliationAction.skippedBelowThreshold);
      expect(result.correction, isNull);
    });

    test(
        'plein with trips, gap above thresholds → action created with '
        'correct liters / midpoint odo and date', () {
      final prevDate = DateTime(2026, 4, 1);
      final closeDate = DateTime(2026, 4, 15);
      final prevPlein = makePlein(
        id: 'p0',
        date: prevDate,
        liters: 40,
        odometerKm: 10000,
      );
      final closingPlein = makePlein(
        id: 'p1',
        date: closeDate,
        liters: 40,
        odometerKm: 10800,
      );
      // Trip integrated 30 L, but pump shows 40 L. Gap = 10 L —
      // well over both floors.
      final trips = [
        makeTrip(startedAt: DateTime(2026, 4, 5), fuel: 30),
      ];
      final result = reconciler.reconcile(
        closingPlein: closingPlein,
        // Note: window starts AFTER prevPlein (exclusive lower
        // bound), so prevPlein's 40 L don't count toward `pumped`.
        allFillUpsForVehicle: [prevPlein, closingPlein],
        tripsForVehicle: trips,
      );
      expect(result, isNotNull);
      expect(result!.action, ReconciliationAction.created);
      expect(result.pumped, 40);
      expect(result.consumed, 30);
      expect(result.gap, 10);
      final correction = result.correction!;
      expect(correction.id, 'correction_p1');
      expect(correction.isCorrection, isTrue);
      expect(correction.isFullTank, isFalse);
      expect(correction.liters, 10);
      expect(correction.totalCost, 0);
      expect(correction.fuelType, FuelType.e10);
      expect(correction.vehicleId, 'veh-a');
      expect(correction.stationName, isNull);
      expect(correction.stationId, isNull);
      // Window's first fill (closingPlein itself, since prev is
      // excluded). Midpoint of [closeDate, closeDate] = closeDate.
      // BUT — the closing plein is its own first fill in the window,
      // so the midpoint collapses; that's fine because the spec
      // explicitly says midpoint of [windowFills.first, closingPlein].
      // Since both are the same fill, the midpoint equals closeDate.
      expect(correction.date, closeDate);
      expect(correction.odometerKm, 10800);
    });

    test(
        'midpoint with partials in window — correction date and odo '
        'fall between the first windowFill and the closing plein', () {
      final prevPlein = makePlein(
        id: 'p0',
        date: DateTime(2026, 4, 1),
        liters: 40,
        odometerKm: 10000,
      );
      final partial = makePlein(
        id: 'p-mid',
        date: DateTime(2026, 4, 8),
        liters: 20,
        odometerKm: 10300,
        isFullTank: false,
      );
      final closingPlein = makePlein(
        id: 'p1',
        date: DateTime(2026, 4, 15),
        liters: 25,
        odometerKm: 10800,
      );
      // Pumped in window = 20 (partial) + 25 (closing) = 45.
      // Trips integrated 30 L → gap = 15 L. Above thresholds.
      final trips = [
        makeTrip(startedAt: DateTime(2026, 4, 5), fuel: 15),
        makeTrip(startedAt: DateTime(2026, 4, 12), fuel: 15),
      ];
      final result = reconciler.reconcile(
        closingPlein: closingPlein,
        allFillUpsForVehicle: [prevPlein, partial, closingPlein],
        tripsForVehicle: trips,
      );
      expect(result!.action, ReconciliationAction.created);
      expect(result.pumped, 45);
      expect(result.consumed, 30);
      final correction = result.correction!;
      // First fill in window is the partial (the prev plein is
      // strictly outside the window). Midpoint date is
      // (Apr 8 + Apr 15) / 2 = Apr 11 12:00.
      expect(
        correction.date,
        DateTime(2026, 4, 11, 12),
      );
      // Midpoint odometer = (10300 + 10800) / 2 = 10550.
      expect(correction.odometerKm, 10550);
      expect(correction.liters, 15);
    });

    test('negative gap → action clampedNegative, no correction', () {
      // OBD2 integrator over-estimated. Pump delivered 30 L, trips
      // claimed 40 L. We don't synthesise a "ghost" reverse fill.
      final prevPlein = makePlein(
        id: 'p0',
        date: DateTime(2026, 4, 1),
        liters: 40,
      );
      final closingPlein = makePlein(
        id: 'p1',
        date: DateTime(2026, 4, 15),
        liters: 30,
        odometerKm: 10500,
      );
      final trips = [
        makeTrip(startedAt: DateTime(2026, 4, 5), fuel: 40),
      ];
      final result = reconciler.reconcile(
        closingPlein: closingPlein,
        allFillUpsForVehicle: [prevPlein, closingPlein],
        tripsForVehicle: trips,
      );
      expect(result!.action, ReconciliationAction.clampedNegative);
      expect(result.correction, isNull);
      expect(result.pumped, 30);
      expect(result.consumed, 40);
      expect(result.gap, lessThan(0));
    });

    test(
        'no previous plein → window starts (inclusive) at first fill '
        'of the same vehicle', () {
      // Closing plein is the first plein for the vehicle but a
      // partial top-up came earlier. Window is [partial.date,
      // closing.date], both inclusive.
      final partial = makePlein(
        id: 'p-mid',
        date: DateTime(2026, 4, 8),
        liters: 20,
        odometerKm: 10100,
        isFullTank: false,
      );
      final closingPlein = makePlein(
        id: 'p1',
        date: DateTime(2026, 4, 15),
        liters: 30,
        odometerKm: 10500,
      );
      // Pumped = 20 + 30 = 50, integrated trips = 30 → gap = 20.
      final trips = [
        makeTrip(startedAt: DateTime(2026, 4, 10), fuel: 30),
      ];
      final result = reconciler.reconcile(
        closingPlein: closingPlein,
        allFillUpsForVehicle: [partial, closingPlein],
        tripsForVehicle: trips,
      );
      expect(result!.action, ReconciliationAction.created);
      expect(result.pumped, 50);
      expect(result.consumed, 30);
      expect(result.correction!.liters, 20);
    });

    test('vehicle filtering excludes other-vehicle fills and trips', () {
      final closingPlein = makePlein(
        id: 'p1',
        date: DateTime(2026, 4, 15),
        liters: 40,
        vehicleId: 'veh-a',
      );
      // Other-vehicle fills should NOT contribute to pumped, even
      // though the caller passed a mixed list. The reconciler
      // filters by vehicleId internally.
      final otherVehicleFill = makePlein(
        id: 'p-other',
        date: DateTime(2026, 4, 10),
        liters: 100,
        vehicleId: 'veh-b',
      );
      // Other-vehicle trips should NOT contribute to consumed.
      // Caller's responsibility per signature; we test the
      // helper that pre-filters trips for the wired path.
      final result = reconciler.reconcile(
        closingPlein: closingPlein,
        allFillUpsForVehicle: [otherVehicleFill, closingPlein],
        tripsForVehicle: const [],
      );
      // Pumped should be 40, not 140.
      expect(result!.pumped, 40);
      // No trips → skippedNoTrips.
      expect(result.action, ReconciliationAction.skippedNoTrips);
    });

    test(
        're-running over a window that already has a correction does '
        'NOT double-count the previous correction in `pumped`', () {
      // First time: gap = 10 L, correction synthesised.
      final prevPlein = makePlein(
        id: 'p0',
        date: DateTime(2026, 4, 1),
        liters: 40,
        odometerKm: 10000,
      );
      final closingPlein = makePlein(
        id: 'p1',
        date: DateTime(2026, 4, 15),
        liters: 40,
        odometerKm: 10800,
      );
      final trips = [
        makeTrip(startedAt: DateTime(2026, 4, 5), fuel: 30),
      ];
      // Stale correction from a previous run sits in the list.
      final staleCorrection = FillUp(
        id: 'correction_p1',
        date: DateTime(2026, 4, 8),
        liters: 10,
        totalCost: 0,
        odometerKm: 10400,
        fuelType: FuelType.e10,
        vehicleId: 'veh-a',
        isFullTank: false,
        isCorrection: true,
      );
      final result = reconciler.reconcile(
        closingPlein: closingPlein,
        allFillUpsForVehicle: [prevPlein, staleCorrection, closingPlein],
        tripsForVehicle: trips,
      );
      // Pumped must still be 40 (closing plein only, prev plein is
      // outside the window, stale correction is excluded).
      expect(result!.pumped, 40);
      expect(result.consumed, 30);
      expect(result.correction!.liters, 10);
      expect(result.correction!.id, 'correction_p1');
    });
  });
}
