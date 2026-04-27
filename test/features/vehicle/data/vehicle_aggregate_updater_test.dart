import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/vehicle/data/repositories/vehicle_profile_repository.dart';
import 'package:tankstellen/features/vehicle/data/vehicle_aggregate_updater.dart';
import 'package:tankstellen/features/vehicle/domain/entities/speed_consumption_histogram.dart';
import 'package:tankstellen/features/vehicle/domain/entities/trip_length_breakdown.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';

/// Builds a [TripHistoryEntry] with the minimum metadata the aggregator
/// looks at: distance, fuel, vehicle id. Other summary fields default
/// to zero / null so the test reads at the call site.
TripHistoryEntry _trip({
  required String id,
  required String vehicleId,
  required double km,
  double? litres,
  List<TripSample> samples = const [],
}) {
  return TripHistoryEntry(
    id: id,
    vehicleId: vehicleId,
    summary: TripSummary(
      distanceKm: km,
      maxRpm: 0,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
      fuelLitersConsumed: litres,
      avgLPer100Km: (litres != null && km > 0) ? litres / km * 100 : null,
      startedAt: DateTime(2026, 4, 1).add(Duration(minutes: int.parse(id))),
    ),
    samples: samples,
  );
}

TripSample _sample({double speedKmh = 50, double? fuelRateLPerHour}) {
  return TripSample(
    timestamp: DateTime(2026, 4, 1),
    speedKmh: speedKmh,
    rpm: 1500,
    fuelRateLPerHour: fuelRateLPerHour,
  );
}

void main() {
  group('aggregateByTripLength (#1193 phase 2)', () {
    test(
        '3 short + 4 medium + 2 long trips → expected breakdown; '
        'long bucket below threshold becomes null', () {
      final trips = <TripHistoryEntry>[
        // 3 shorts at 5/8/12 km, 0.5/0.7/1.0 L
        _trip(id: '1', vehicleId: 'v', km: 5, litres: 0.5),
        _trip(id: '2', vehicleId: 'v', km: 8, litres: 0.7),
        _trip(id: '3', vehicleId: 'v', km: 12, litres: 1.0),
        // 4 mediums at 20/25/30/40 km, 1.5/2.0/2.4/3.0 L
        _trip(id: '4', vehicleId: 'v', km: 20, litres: 1.5),
        _trip(id: '5', vehicleId: 'v', km: 25, litres: 2.0),
        _trip(id: '6', vehicleId: 'v', km: 30, litres: 2.4),
        _trip(id: '7', vehicleId: 'v', km: 40, litres: 3.0),
        // 2 longs (below the 3-trip threshold so this bucket is null)
        _trip(id: '8', vehicleId: 'v', km: 60, litres: 4.0),
        _trip(id: '9', vehicleId: 'v', km: 100, litres: 7.0),
      ];

      final result = aggregateByTripLength(trips);

      expect(result.short, isNotNull);
      expect(result.short!.tripCount, 3);
      expect(result.short!.totalDistanceKm, closeTo(25, 1e-9));
      expect(result.short!.totalLitres, closeTo(2.2, 1e-9));
      expect(result.short!.meanLPer100km, closeTo(2.2 / 25 * 100, 1e-9));

      expect(result.medium, isNotNull);
      expect(result.medium!.tripCount, 4);
      expect(result.medium!.totalDistanceKm, closeTo(115, 1e-9));
      expect(result.medium!.totalLitres, closeTo(8.9, 1e-9));
      expect(result.medium!.meanLPer100km, closeTo(8.9 / 115 * 100, 1e-9));

      // Long has only 2 trips → below per-bucket threshold → null
      expect(result.long, isNull);
    });

    test('empty trip list → all buckets null', () {
      final result = aggregateByTripLength(const []);
      expect(result.short, isNull);
      expect(result.medium, isNull);
      expect(result.long, isNull);
    });

    test(
        'trips without fuelLitersConsumed still count toward the bucket '
        'but contribute zero litres — documented under-statement', () {
      final trips = <TripHistoryEntry>[
        _trip(id: '1', vehicleId: 'v', km: 5, litres: null),
        _trip(id: '2', vehicleId: 'v', km: 5, litres: null),
        _trip(id: '3', vehicleId: 'v', km: 5, litres: 0.5),
      ];
      final result = aggregateByTripLength(trips);
      expect(result.short!.tripCount, 3);
      expect(result.short!.totalDistanceKm, closeTo(15, 1e-9));
      expect(result.short!.totalLitres, closeTo(0.5, 1e-9));
    });
  });

  group('aggregateSpeedConsumption (#1193 phase 2)', () {
    test(
        'samples spanning multiple bands above threshold → expected histogram; '
        'sparse band excluded', () {
      final samples = <TripSample>[
        // Band (0,30): 60 samples (above 50) — fuel rate 1.0 L/h
        for (var i = 0; i < 60; i++) _sample(speedKmh: 20, fuelRateLPerHour: 1.0),
        // Band (30,50): 80 samples — fuel rate 2.0 L/h
        for (var i = 0; i < 80; i++) _sample(speedKmh: 40, fuelRateLPerHour: 2.0),
        // Band (50,80): 100 samples — fuel rate 3.0 L/h
        for (var i = 0; i < 100; i++) _sample(speedKmh: 65, fuelRateLPerHour: 3.0),
        // Band (80,110): 30 samples — BELOW threshold → excluded
        for (var i = 0; i < 30; i++) _sample(speedKmh: 95, fuelRateLPerHour: 5.0),
      ];

      final result = aggregateSpeedConsumption(samples);

      // 3 of 5 template bands should appear — (0,30), (30,50), (50,80).
      // (80,110) is below threshold; (110, null) has no samples.
      expect(result.bands, hasLength(3));

      final low = result.bands.firstWhere((b) => b.minKmh == 0);
      expect(low.sampleCount, 60);
      expect(low.timeShareFraction, closeTo(60 / 270, 1e-9));
      // mean L/100km = (1.0 L/h × 60 s / 3600) / (20 km/h × 60 s / 3600 km) × 100
      //              = (1.0 / 20) × 100 = 5.0 L/100 km
      expect(low.meanLPer100km, closeTo(5.0, 1e-9));

      final mid = result.bands.firstWhere((b) => b.minKmh == 30);
      expect(mid.sampleCount, 80);
      // (2.0 / 40) × 100 = 5.0 L/100 km
      expect(mid.meanLPer100km, closeTo(5.0, 1e-9));

      final high = result.bands.firstWhere((b) => b.minKmh == 50);
      expect(high.sampleCount, 100);
      // (3.0 / 65) × 100 ≈ 4.615 L/100 km
      expect(high.meanLPer100km, closeTo(3.0 / 65 * 100, 1e-9));

      // No band below threshold should appear.
      expect(result.bands.where((b) => b.minKmh == 80).isEmpty, isTrue);
    });

    test('empty samples → empty histogram (cold-start signal)', () {
      final result = aggregateSpeedConsumption(const []);
      expect(result.bands, isEmpty);
    });

    test(
        'samples without fuelRateLPerHour still count toward sample count '
        'and time share — documented under-statement', () {
      final samples = <TripSample>[
        for (var i = 0; i < 60; i++) _sample(speedKmh: 20, fuelRateLPerHour: null),
      ];
      final result = aggregateSpeedConsumption(samples);
      expect(result.bands, hasLength(1));
      expect(result.bands.single.sampleCount, 60);
      // No fuel-rate data → zero litres → mean = 0.
      expect(result.bands.single.meanLPer100km, closeTo(0.0, 1e-9));
    });
  });

  group('foldTripLengthIncremental (#1193 phase 2 — Welford)', () {
    test(
        'fold-by-fold over N trips matches a full recompute over the same '
        'N trips for sums + counts (exact)', () {
      final trips = <TripHistoryEntry>[
        _trip(id: '1', vehicleId: 'v', km: 5, litres: 0.5),
        _trip(id: '2', vehicleId: 'v', km: 8, litres: 0.7),
        _trip(id: '3', vehicleId: 'v', km: 12, litres: 1.0),
        _trip(id: '4', vehicleId: 'v', km: 20, litres: 1.5),
        _trip(id: '5', vehicleId: 'v', km: 25, litres: 2.0),
        _trip(id: '6', vehicleId: 'v', km: 30, litres: 2.4),
        _trip(id: '7', vehicleId: 'v', km: 60, litres: 4.0),
        _trip(id: '8', vehicleId: 'v', km: 100, litres: 7.0),
        _trip(id: '9', vehicleId: 'v', km: 120, litres: 8.4),
      ];

      // Fold-in path: start from null, add each trip one by one.
      TripLengthBreakdown? folded;
      for (final t in trips) {
        folded = foldTripLengthIncremental(folded, t);
      }

      // Reference: full recompute.
      final reference = aggregateByTripLength(trips);

      // Sums + counts: bit-exact for buckets that exist on both sides.
      // Note: full recompute returns null for buckets below the
      // per-bucket threshold (3); fold-in returns the running total
      // even at count=1 — that's intentional, the threshold is applied
      // by `aggregateByTripLength` at emit time, not by the fold. So
      // we only compare buckets where both sides are non-null.
      if (reference.short != null && folded?.short != null) {
        expect(folded!.short!.tripCount, reference.short!.tripCount);
        expect(folded.short!.totalDistanceKm,
            closeTo(reference.short!.totalDistanceKm, 1e-12));
        expect(folded.short!.totalLitres,
            closeTo(reference.short!.totalLitres, 1e-12));
        // Per-bin mean: < 1e-6 by Welford convergence. Both sides
        // recompute mean from the same totals though, so we expect
        // bit-exact too.
        expect(folded.short!.meanLPer100km,
            closeTo(reference.short!.meanLPer100km, 1e-6));
      }
      expect(folded!.medium!.tripCount, reference.medium!.tripCount);
      expect(folded.medium!.totalDistanceKm,
          closeTo(reference.medium!.totalDistanceKm, 1e-12));
      expect(folded.medium!.totalLitres,
          closeTo(reference.medium!.totalLitres, 1e-12));
      expect(folded.medium!.meanLPer100km,
          closeTo(reference.medium!.meanLPer100km, 1e-6));

      expect(folded.long!.tripCount, reference.long!.tripCount);
      expect(folded.long!.totalDistanceKm,
          closeTo(reference.long!.totalDistanceKm, 1e-12));
      expect(folded.long!.totalLitres,
          closeTo(reference.long!.totalLitres, 1e-12));
      expect(folded.long!.meanLPer100km,
          closeTo(reference.long!.meanLPer100km, 1e-6));
    });

    test('null prior + one trip → seeds the matching bucket only', () {
      final result = foldTripLengthIncremental(
        null,
        _trip(id: '1', vehicleId: 'v', km: 12, litres: 1.0),
      );
      expect(result.short, isNotNull);
      expect(result.short!.tripCount, 1);
      expect(result.medium, isNull);
      expect(result.long, isNull);
    });
  });

  group('foldSpeedConsumptionIncremental (#1193 phase 2 — Welford)', () {
    test(
        'fold-by-fold matches a full recompute on per-band counts and '
        'time shares (exact above threshold); per-bin means within 1e-6 '
        '— the docstring caveat about across-threshold lossiness is '
        'covered by feeding pass 1 enough samples that every band that '
        'will eventually clear threshold already does so', () {
      // Pass 1 must seed every band above [kMinSamplesPerSpeedBand] = 50
      // for the prior to round-trip losslessly. Pass 2 then adds more
      // samples on top.
      final pass1 = <TripSample>[
        for (var i = 0; i < 60; i++) _sample(speedKmh: 20, fuelRateLPerHour: 1.0),
        for (var i = 0; i < 60; i++) _sample(speedKmh: 40, fuelRateLPerHour: 2.0),
        for (var i = 0; i < 60; i++) _sample(speedKmh: 65, fuelRateLPerHour: 3.0),
      ];
      final pass2 = <TripSample>[
        for (var i = 0; i < 20; i++) _sample(speedKmh: 20, fuelRateLPerHour: 1.0),
        for (var i = 0; i < 30; i++) _sample(speedKmh: 40, fuelRateLPerHour: 2.0),
        for (var i = 0; i < 40; i++) _sample(speedKmh: 65, fuelRateLPerHour: 3.0),
      ];
      final reference = aggregateSpeedConsumption([...pass1, ...pass2]);

      // Fold-in path.
      SpeedConsumptionHistogram? folded;
      folded = foldSpeedConsumptionIncremental(folded, pass1);
      folded = foldSpeedConsumptionIncremental(folded, pass2);

      expect(folded.bands, hasLength(reference.bands.length));
      for (final refBand in reference.bands) {
        final foldedBand = folded.bands.firstWhere(
          (b) => b.minKmh == refBand.minKmh,
        );
        expect(foldedBand.sampleCount, refBand.sampleCount);
        expect(foldedBand.timeShareFraction,
            closeTo(refBand.timeShareFraction, 1e-9));
        // Welford per-bin mean: tolerance < 1e-6 documents the
        // approximation. In practice the totals come from the same
        // sources so we tend to match exactly — the looser tolerance
        // is an honest contract bound for callers.
        expect(foldedBand.meanLPer100km,
            closeTo(refBand.meanLPer100km, 1e-6));
      }
    });

    test(
        'across-threshold fold is lossy (documented) — a band that was '
        'sub-threshold in the prior loses its old samples on the next fold', () {
      // Pass 1: 80 samples in band (0,30), 20 in (30,50). Only (0,30)
      // clears the 50-sample threshold; (30,50) is dropped from the
      // prior's `bands` list.
      final pass1 = <TripSample>[
        for (var i = 0; i < 80; i++) _sample(speedKmh: 20, fuelRateLPerHour: 1.0),
        for (var i = 0; i < 20; i++) _sample(speedKmh: 40, fuelRateLPerHour: 2.0),
      ];
      // Pass 2: 40 more in (30,50) — now 60 across both passes, but
      // the fold can only see the 40 in pass 2 because the 20 from
      // pass 1 were dropped from the prior.
      final pass2 = <TripSample>[
        for (var i = 0; i < 40; i++) _sample(speedKmh: 40, fuelRateLPerHour: 2.0),
      ];

      SpeedConsumptionHistogram? folded;
      folded = foldSpeedConsumptionIncremental(folded, pass1);
      folded = foldSpeedConsumptionIncremental(folded, pass2);

      // Folded (30,50): only 40 samples — below threshold, so the
      // band is omitted from the output. The full recompute would
      // include it (60 ≥ 50). Documented limitation.
      final hasMid = folded.bands.any((b) => b.minKmh == 30);
      expect(hasMid, isFalse);

      // Full recompute: (30,50) has 60 samples, makes the cut.
      final ref = aggregateSpeedConsumption([...pass1, ...pass2]);
      expect(ref.bands.any((b) => b.minKmh == 30), isTrue);
    });
  });

  group('VehicleAggregateUpdater.updateForVehicle (#1193 phase 2)', () {
    late _FakeSettings storage;
    late VehicleProfileRepository vehicleRepo;
    late _FakeTripHistory tripRepo;
    late VehicleAggregateUpdater updater;
    late _FakeTraceRecorder recorder;

    setUp(() {
      storage = _FakeSettings();
      vehicleRepo = VehicleProfileRepository(storage);
      tripRepo = _FakeTripHistory();
      updater = VehicleAggregateUpdater(
        vehicleRepo: vehicleRepo,
        tripRepoLookup: () => tripRepo,
        now: () => DateTime(2026, 4, 27, 12, 0, 0),
      );
      // The runForVehicle path routes errors through errorLogger.log,
      // which would otherwise fall through to IsolateErrorSpool and
      // open a Hive box (not initialised in this unit test). Inject a
      // capture-only recorder via the documented test seam.
      errorLogger.resetForTest();
      recorder = _FakeTraceRecorder();
      errorLogger.testRecorderOverride = recorder;
    });

    tearDown(() {
      errorLogger.resetForTest();
    });

    test(
        'below-threshold guard — vehicle with < 5 trips ends up with all '
        'aggregate fields null on the persisted profile', () async {
      await vehicleRepo.save(
        const VehicleProfile(id: 'v1', name: 'Test'),
      );
      tripRepo.entries = <TripHistoryEntry>[
        _trip(id: '1', vehicleId: 'v1', km: 10, litres: 0.7),
        _trip(id: '2', vehicleId: 'v1', km: 12, litres: 0.9),
        _trip(id: '3', vehicleId: 'v1', km: 30, litres: 2.0),
        _trip(id: '4', vehicleId: 'v1', km: 60, litres: 4.0),
      ];

      await updater.updateForVehicle('v1');

      final profile = vehicleRepo.getById('v1')!;
      expect(profile.tripLengthAggregates, isNull);
      expect(profile.speedConsumptionAggregates, isNull);
      expect(profile.aggregatesTripCount, 4);
      expect(profile.aggregatesUpdatedAt, isNotNull);
    });

    test(
        'updateForVehicle persists aggregates and stamps the profile with '
        'aggregatesUpdatedAt + aggregatesTripCount', () async {
      await vehicleRepo.save(
        const VehicleProfile(id: 'v1', name: 'Test'),
      );
      // 5 trips clears the visibility threshold; bucket fills will be
      // partial (we only need the metadata fields to be set here).
      tripRepo.entries = <TripHistoryEntry>[
        _trip(id: '1', vehicleId: 'v1', km: 5, litres: 0.5),
        _trip(id: '2', vehicleId: 'v1', km: 8, litres: 0.7),
        _trip(id: '3', vehicleId: 'v1', km: 12, litres: 1.0),
        _trip(id: '4', vehicleId: 'v1', km: 20, litres: 1.5),
        _trip(id: '5', vehicleId: 'v1', km: 30, litres: 2.4),
      ];

      await updater.updateForVehicle('v1');

      final profile = vehicleRepo.getById('v1')!;
      expect(profile.aggregatesUpdatedAt, DateTime(2026, 4, 27, 12, 0, 0));
      expect(profile.aggregatesTripCount, 5);
      expect(profile.tripLengthAggregates, isNotNull);
      expect(profile.tripLengthAggregates!.short, isNotNull);
      expect(profile.tripLengthAggregates!.short!.tripCount, 3);
      // Speed histogram is empty (no samples in the test trips), but
      // the field itself should be populated as an empty histogram —
      // the cold-start signal documented on the value object.
      expect(profile.speedConsumptionAggregates, isNotNull);
    });

    test(
        'orphan trips (other vehicleId) are filtered out before counting '
        'against the threshold', () async {
      await vehicleRepo.save(const VehicleProfile(id: 'v1', name: 'Test'));
      tripRepo.entries = <TripHistoryEntry>[
        // 5 belong to v1
        _trip(id: '1', vehicleId: 'v1', km: 5, litres: 0.5),
        _trip(id: '2', vehicleId: 'v1', km: 8, litres: 0.7),
        _trip(id: '3', vehicleId: 'v1', km: 12, litres: 1.0),
        _trip(id: '4', vehicleId: 'v1', km: 20, litres: 1.5),
        _trip(id: '5', vehicleId: 'v1', km: 30, litres: 2.4),
        // 3 belong to v2 — should be ignored when updating v1
        _trip(id: '6', vehicleId: 'v2', km: 100, litres: 7.0),
        _trip(id: '7', vehicleId: 'v2', km: 100, litres: 7.0),
        _trip(id: '8', vehicleId: 'v2', km: 100, litres: 7.0),
      ];

      await updater.updateForVehicle('v1');

      final profile = vehicleRepo.getById('v1')!;
      expect(profile.aggregatesTripCount, 5);
    });

    test('no-op when vehicle is not found', () async {
      // No profile saved → updater should silently skip.
      tripRepo.entries = <TripHistoryEntry>[
        _trip(id: '1', vehicleId: 'ghost', km: 5, litres: 0.5),
      ];
      await updater.updateForVehicle('ghost');
      // Nothing to assert other than "did not throw".
      expect(vehicleRepo.getAll(), isEmpty);
    });

    test(
        'runForVehicle never throws even when updater hits an error — '
        'the failure routes through errorLogger.log (background layer)',
        () async {
      // Throwing trip repo lookup simulates a corrupted Hive state.
      final throwingUpdater = VehicleAggregateUpdater(
        vehicleRepo: vehicleRepo,
        tripRepoLookup: () => throw StateError('hive corrupt'),
      );
      await vehicleRepo.save(const VehicleProfile(id: 'v1', name: 'Test'));

      // Should NOT throw — the wrapper logs via errorLogger.log.
      await expectLater(throwingUpdater.runForVehicle('v1'), completes);

      // The error MUST land in the recorder so observability picks it
      // up; a silent swallow would violate the no-silent-catch rule.
      expect(recorder.calls, hasLength(1));
      final recorded = recorder.calls.single.error.toString();
      expect(recorded, contains('[background]'));
      expect(recorded, contains('hive corrupt'));
      expect(recorded, contains('vehicleId'));
      expect(recorded, contains('v1'));
    });
  });
}

/// In-memory fake of [TripHistoryRepository] for the updater tests.
/// Returning the same shape as the real repo without standing up a
/// Hive box keeps the test fast and avoids the platform-channel setup
/// the real repo requires.
class _FakeTripHistory implements TripHistoryRepository {
  List<TripHistoryEntry> entries = <TripHistoryEntry>[];

  @override
  List<TripHistoryEntry> loadAll() {
    final sorted = [...entries];
    sorted.sort((a, b) {
      final ax = a.summary.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bx = b.summary.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bx.compareTo(ax);
    });
    return sorted;
  }

  @override
  Future<void> save(TripHistoryEntry entry) async {
    entries.add(entry);
  }

  @override
  Future<void> delete(String id) async {
    entries.removeWhere((e) => e.id == id);
  }

  @override
  void Function(String vehicleId)? onSavedHook;

  @override
  int get cap => 100;

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
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

/// Capture-only TraceRecorder for the [errorLogger.testRecorderOverride]
/// seam. Mirrors the fake in `test/core/logging/error_logger_test.dart`
/// — same shape, same noSuchMethod fallback for the rest of the
/// recorder surface.
class _FakeTraceRecorder implements TraceRecorder {
  final calls = <_RecordedCall>[];

  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async {
    calls.add(_RecordedCall(error, stackTrace));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class _RecordedCall {
  final Object error;
  final StackTrace stackTrace;
  _RecordedCall(this.error, this.stackTrace);
}
