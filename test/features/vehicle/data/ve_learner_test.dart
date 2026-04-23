import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/vehicle/data/repositories/vehicle_profile_repository.dart';
import 'package:tankstellen/features/vehicle/data/ve_learner.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';

/// Seed helper — builds a [TripHistoryEntry] with the handful of
/// fields the learner actually reads (distance, integrated fuel,
/// startedAt/endedAt window). Everything else gets zero defaults.
TripHistoryEntry _tripEntry({
  required String id,
  required String vehicleId,
  required DateTime startedAt,
  required DateTime endedAt,
  required double distanceKm,
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
      endedAt: endedAt,
    ),
  );
}

void main() {
  group('VeLearner.reconcileAfterFillUp', () {
    late _FakeSettings settings;
    late VehicleProfileRepository profileRepo;
    late _InMemoryTrips trips;
    late VeLearner learner;

    final previousFill = DateTime(2026, 4, 1, 8);
    final currentFill = DateTime(2026, 4, 15, 18);

    setUp(() async {
      settings = _FakeSettings();
      profileRepo = VehicleProfileRepository(settings);
      trips = _InMemoryTrips();
      learner = VeLearner(
        profileRepository: profileRepo,
        tripHistoryLoader: trips.loadAll,
        // Static sample counter so guards aren't accidentally
        // tripped by wall-clock duration — test trips don't have
        // realistic startedAt/endedAt ranges.
        sampleCounter: (_) => 600,
      );
      // Seed vehicle A with the default η_v.
      await profileRepo.save(const VehicleProfile(
        id: 'veh-a',
        name: 'Peugeot 107',
      ));
    });

    test('10% overestimate adjusts η_v and bumps sample counter',
        () async {
      // integrated=55, pumped=50 → new_estimate = 0.85 × (50/55) =
      // 0.77272727…; EWMA blend = 0.7 × 0.85 + 0.3 × 0.77272727 =
      // 0.82681818. The issue spec rounds this to ~0.82 which is the
      // value the UI surfaces.
      trips.entries.add(_tripEntry(
        id: 't1',
        vehicleId: 'veh-a',
        startedAt: previousFill.add(const Duration(hours: 2)),
        endedAt: previousFill.add(const Duration(hours: 5)),
        distanceKm: 200,
        fuelLitersConsumed: 55,
      ));

      final result = await learner.reconcileAfterFillUp(
        vehicleId: 'veh-a',
        pumpedLiters: 50,
        fillUpTimestamp: currentFill,
        previousFillUpTimestamp: previousFill,
      );

      expect(result, isNotNull);
      expect(result!.previousVe, closeTo(0.85, 1e-9));
      expect(result.newVe, closeTo(0.82681818, 1e-4));
      expect(result.sampleCount, 1);

      final updated = profileRepo.getById('veh-a')!;
      expect(updated.volumetricEfficiency, closeTo(0.82681818, 1e-4));
      expect(updated.volumetricEfficiencySamples, 1);
    });

    test('short trip (< 50 km) is ignored — profile untouched',
        () async {
      trips.entries.add(_tripEntry(
        id: 't1',
        vehicleId: 'veh-a',
        startedAt: previousFill.add(const Duration(hours: 2)),
        endedAt: previousFill.add(const Duration(hours: 3)),
        distanceKm: 30,
        fuelLitersConsumed: 3,
      ));

      final result = await learner.reconcileAfterFillUp(
        vehicleId: 'veh-a',
        pumpedLiters: 3,
        fillUpTimestamp: currentFill,
        previousFillUpTimestamp: previousFill,
      );

      expect(result, isNull);
      final unchanged = profileRepo.getById('veh-a')!;
      expect(unchanged.volumetricEfficiency, 0.85);
      expect(unchanged.volumetricEfficiencySamples, 0);
    });

    test('too-few OBD2 samples is ignored', () async {
      // Thin-samples learner — same trip distance & fuel, but the
      // sample counter reports 3 samples. Under the 10-sample floor.
      final thinLearner = VeLearner(
        profileRepository: profileRepo,
        tripHistoryLoader: trips.loadAll,
        sampleCounter: (_) => 3,
      );
      trips.entries.add(_tripEntry(
        id: 't1',
        vehicleId: 'veh-a',
        startedAt: previousFill.add(const Duration(hours: 2)),
        endedAt: previousFill.add(const Duration(hours: 5)),
        distanceKm: 200,
        fuelLitersConsumed: 55,
      ));

      final result = await thinLearner.reconcileAfterFillUp(
        vehicleId: 'veh-a',
        pumpedLiters: 50,
        fillUpTimestamp: currentFill,
        previousFillUpTimestamp: previousFill,
      );

      expect(result, isNull);
      expect(profileRepo.getById('veh-a')!.volumetricEfficiency, 0.85);
    });

    test('outlier (|gap|/pumped > 40%) is ignored', () async {
      // integrated=80, pumped=50 — 60 % gap, way over the 40 % outlier
      // cutoff. The user probably missed logging an earlier fill-up.
      trips.entries.add(_tripEntry(
        id: 't1',
        vehicleId: 'veh-a',
        startedAt: previousFill.add(const Duration(hours: 2)),
        endedAt: previousFill.add(const Duration(hours: 10)),
        distanceKm: 400,
        fuelLitersConsumed: 80,
      ));

      final result = await learner.reconcileAfterFillUp(
        vehicleId: 'veh-a',
        pumpedLiters: 50,
        fillUpTimestamp: currentFill,
        previousFillUpTimestamp: previousFill,
      );

      expect(result, isNull);
      expect(profileRepo.getById('veh-a')!.volumetricEfficiency, 0.85);
    });

    test('clamps above 1.0 — extreme under-integration', () async {
      // Seed η near 1.0, pump way more than integrated — the raw new
      // estimate would exceed 1.0 and the clamp must engage.
      await profileRepo.save(const VehicleProfile(
        id: 'veh-a',
        name: 'Peugeot 107',
        volumetricEfficiency: 0.98,
      ));
      trips.entries.add(_tripEntry(
        id: 't1',
        vehicleId: 'veh-a',
        startedAt: previousFill.add(const Duration(hours: 2)),
        endedAt: previousFill.add(const Duration(hours: 5)),
        distanceKm: 200,
        // Only 5 % gap so we stay inside the 40 % outlier cutoff.
        fuelLitersConsumed: 48,
      ));

      final result = await learner.reconcileAfterFillUp(
        vehicleId: 'veh-a',
        pumpedLiters: 50,
        fillUpTimestamp: currentFill,
        previousFillUpTimestamp: previousFill,
      );

      expect(result, isNotNull);
      expect(result!.newVe, lessThanOrEqualTo(1.0));
      expect(result.newVe, greaterThanOrEqualTo(0.98));
      // Custom learner with a lower ewmaBlend → raw value dominates
      // and the clamp kicks in.
      final aggressive = VeLearner(
        profileRepository: profileRepo,
        tripHistoryLoader: trips.loadAll,
        sampleCounter: (_) => 600,
        ewmaBlend: 0.0,
      );
      await profileRepo.save(const VehicleProfile(
        id: 'veh-a',
        name: 'Peugeot 107',
        volumetricEfficiency: 0.98,
      ));
      final r2 = await aggressive.reconcileAfterFillUp(
        vehicleId: 'veh-a',
        pumpedLiters: 50,
        fillUpTimestamp: currentFill,
        previousFillUpTimestamp: previousFill,
      );
      // raw = 0.98 × 50/48 ≈ 1.0208 — must be clamped to 1.0.
      expect(r2!.newVe, 1.0);
    });

    test('clamps below 0.5 — extreme over-integration', () async {
      // Learner with ewmaBlend = 0 (no smoothing) + a huge gap within
      // the 40 % outlier window. 0.85 × (36/60) = 0.51 — set η
      // artificially low so the raw estimate undershoots 0.5.
      await profileRepo.save(const VehicleProfile(
        id: 'veh-a',
        name: 'Peugeot 107',
        volumetricEfficiency: 0.70,
      ));
      trips.entries.add(_tripEntry(
        id: 't1',
        vehicleId: 'veh-a',
        startedAt: previousFill.add(const Duration(hours: 2)),
        endedAt: previousFill.add(const Duration(hours: 10)),
        distanceKm: 400,
        // 35 % over pumped, inside the 40 % outlier cutoff, but the
        // η_v that would explain it is 0.70 × 50/67.5 ≈ 0.518 — still
        // above 0.5. To force the clamp we drop ewmaBlend to 0 and
        // shave η to 0.60 so raw = 0.60 × 50/67.5 ≈ 0.444 < 0.5.
        fuelLitersConsumed: 67.5,
      ));

      final raw = VeLearner(
        profileRepository: profileRepo,
        tripHistoryLoader: trips.loadAll,
        sampleCounter: (_) => 600,
        ewmaBlend: 0.0,
      );
      await profileRepo.save(const VehicleProfile(
        id: 'veh-a',
        name: 'Peugeot 107',
        volumetricEfficiency: 0.60,
      ));
      final r = await raw.reconcileAfterFillUp(
        vehicleId: 'veh-a',
        pumpedLiters: 50,
        fillUpTimestamp: currentFill,
        previousFillUpTimestamp: previousFill,
      );
      expect(r, isNotNull);
      expect(r!.newVe, 0.5);
    });

    test('no trip between fill-ups is ignored', () async {
      // Trip logged BEFORE the previous fill-up — the learner must
      // filter it out by timestamp and return null rather than
      // silently calibrating off stale data.
      trips.entries.add(_tripEntry(
        id: 't1',
        vehicleId: 'veh-a',
        startedAt: previousFill.subtract(const Duration(days: 5)),
        endedAt: previousFill.subtract(const Duration(days: 5, hours: -3)),
        distanceKm: 200,
        fuelLitersConsumed: 55,
      ));

      final result = await learner.reconcileAfterFillUp(
        vehicleId: 'veh-a',
        pumpedLiters: 50,
        fillUpTimestamp: currentFill,
        previousFillUpTimestamp: previousFill,
      );

      expect(result, isNull);
      expect(profileRepo.getById('veh-a')!.volumetricEfficiency, 0.85);
    });

    test('multi-vehicle isolation — B unaffected when A calibrates',
        () async {
      await profileRepo.save(const VehicleProfile(
        id: 'veh-b',
        name: 'Renault Zoe',
      ));
      trips.entries.add(_tripEntry(
        id: 't1',
        vehicleId: 'veh-a',
        startedAt: previousFill.add(const Duration(hours: 2)),
        endedAt: previousFill.add(const Duration(hours: 5)),
        distanceKm: 200,
        fuelLitersConsumed: 55,
      ));

      final result = await learner.reconcileAfterFillUp(
        vehicleId: 'veh-a',
        pumpedLiters: 50,
        fillUpTimestamp: currentFill,
        previousFillUpTimestamp: previousFill,
      );
      expect(result, isNotNull);

      final a = profileRepo.getById('veh-a')!;
      final b = profileRepo.getById('veh-b')!;
      expect(a.volumetricEfficiency, isNot(0.85));
      expect(a.volumetricEfficiencySamples, 1);
      // Vehicle B kept its cold-start default and its zero counter —
      // A's calibration did not bleed through.
      expect(b.volumetricEfficiency, 0.85);
      expect(b.volumetricEfficiencySamples, 0);
    });

    test('missing previous fill-up means first-ever calibration '
        'over the full history', () async {
      trips.entries.add(_tripEntry(
        id: 't1',
        vehicleId: 'veh-a',
        startedAt: currentFill.subtract(const Duration(days: 3)),
        endedAt: currentFill.subtract(const Duration(days: 3, hours: -3)),
        distanceKm: 200,
        fuelLitersConsumed: 55,
      ));

      final result = await learner.reconcileAfterFillUp(
        vehicleId: 'veh-a',
        pumpedLiters: 50,
        fillUpTimestamp: currentFill,
        previousFillUpTimestamp: null,
      );

      expect(result, isNotNull);
      expect(result!.sampleCount, 1);
    });

    test('accuracy improvement is a positive percentage', () async {
      trips.entries.add(_tripEntry(
        id: 't1',
        vehicleId: 'veh-a',
        startedAt: previousFill.add(const Duration(hours: 2)),
        endedAt: previousFill.add(const Duration(hours: 5)),
        distanceKm: 200,
        fuelLitersConsumed: 55,
      ));

      final result = await learner.reconcileAfterFillUp(
        vehicleId: 'veh-a',
        pumpedLiters: 50,
        fillUpTimestamp: currentFill,
        previousFillUpTimestamp: previousFill,
      );

      expect(result, isNotNull);
      expect(result!.accuracyImprovementPct, greaterThan(0));
      expect(result.accuracyImprovementPct, lessThanOrEqualTo(100));
    });
  });
}

/// In-memory trip history so the learner can exercise the time
/// window filter without touching Hive.
class _InMemoryTrips {
  final List<TripHistoryEntry> entries = [];
  List<TripHistoryEntry> loadAll() => List.unmodifiable(entries);
}

class _FakeSettings implements SettingsStorage {
  final Map<String, dynamic> _data = {};

  @override
  dynamic getSetting(String key) => _data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  bool get isSetupComplete => false;

  @override
  bool get isSetupSkipped => false;

  @override
  Future<void> skipSetup() async {}

  @override
  Future<void> resetSetupSkip() async {}
}
