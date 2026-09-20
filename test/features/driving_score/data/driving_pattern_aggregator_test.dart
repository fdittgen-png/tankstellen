// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4366 — the acceptance boxes of the driving-pattern comparison.
// Synthetic evidence throughout: these pin the RULES, not any real car's
// behaviour. Totals are injected rather than decoded, which is itself
// part of the contract — the aggregator never reaches for samples.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/comparison_eligibility.dart';
import 'package:tankstellen/features/driving_score/data/driving_pattern_aggregator.dart';
import 'package:tankstellen/features/driving_score/domain/driving_pattern_comparison.dart';
import 'package:tankstellen/features/trips/api.dart';

final _asOf = DateTime.utc(2026, 9, 20, 12);

TripHistoryEntry _trip(
  String id,
  String? vehicleId, {
  double km = 100,
  bool cold = false,
  bool coolant = false,
  bool virtual = false,
  double? engineRunningSeconds,
  int day = 5,
}) =>
    TripHistoryEntry(
      id: id,
      vehicleId: vehicleId,
      sampleCount: 600,
      columnsPresent: {'s', if (coolant) 'ct'},
      summary: TripSummary(
        distanceKm: km,
        maxRpm: 3000,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        coldStartSurcharge: cold,
        isVirtual: virtual,
        engineRunningSeconds: engineRunningSeconds,
        startedAt: DateTime.utc(2026, 9, day, 8),
        endedAt: DateTime.utc(2026, 9, day, 9),
      ),
    );

DrivingPatternTotals _totals({
  Map<DrivingEventCounter, int> events = const {},
  Map<DrivingDurationCounter, double> seconds = const {},
  Map<DrivingExposureBasis, double> exposure = const {},
}) =>
    DrivingPatternTotals(
        events: events, seconds: seconds, exposure: exposure);

Future<DrivingPatternComparison> _run(
  List<String> ids,
  List<TripHistoryEntry> trips,
  Map<String, DrivingPatternTotals> byTripId, {
  void Function(String id)? onLoad,
}) =>
    aggregateDrivingPatterns(
      selectedVehicleIds: ids,
      summaries: trips,
      asOf: _asOf,
      loadTotals: (entry) {
        onLoad?.call(entry.id);
        return byTripId[entry.id];
      },
    );

/// Every key name anywhere in a decoded read model.
Set<String> _jsonKeys(Object? node) {
  if (node is Map) {
    return {
      for (final e in node.entries) ...{
        e.key.toString(),
        ..._jsonKeys(e.value),
      },
    };
  }
  if (node is Iterable) {
    return {for (final v in node) ..._jsonKeys(v)};
  }
  return const {};
}

void main() {
  // ── Acceptance 1 ───────────────────────────────────────────────────
  test('10 events over 100 km and 100 over 1000 km state the same rate '
      'with visibly different exposure', () async {
    final trips = [_trip('a1', 'a', km: 100), _trip('b1', 'b', km: 1000)];
    final result = await _run(['a', 'b'], trips, {
      'a1': _totals(
          events: {DrivingEventCounter.hardAccelEvents: 10},
          exposure: {DrivingExposureBasis.movingDistanceKm: 100}),
      'b1': _totals(
          events: {DrivingEventCounter.hardAccelEvents: 100},
          exposure: {DrivingExposureBasis.movingDistanceKm: 1000}),
    });

    final a = result.subjects[0].measure(DrivingMeasureId.hardAccelRate)!;
    final b = result.subjects[1].measure(DrivingMeasureId.hardAccelRate)!;
    expect(a.metric.valueOrNull, 10.0);
    expect(b.metric.valueOrNull, 10.0);
    expect(a.exposure, 100);
    expect(b.exposure, 1000);
    expect(a.metric.qualifications, isNotEmpty,
        reason: 'no figure here is ever shown bare');
    expect(result.differences, isEmpty,
        reason: 'the same rate is not a difference');
  });

  test('every stated measure carries its typed numerator and its eligible '
      'denominator', () async {
    final trips = [_trip('a1', 'a', km: 100), _trip('b1', 'b', km: 100)];
    final totals = _totals(
      events: {DrivingEventCounter.hardAccelEvents: 10},
      seconds: {DrivingDurationCounter.fullThrottleSeconds: 90},
      exposure: {
        DrivingExposureBasis.movingDistanceKm: 100,
        DrivingExposureBasis.pedalKnownSeconds: 900,
      },
    );
    final result =
        await _run(['a', 'b'], trips, {'a1': totals, 'b1': totals});
    final subject = result.subjects.first;

    final rate = subject.measure(DrivingMeasureId.hardAccelRate)!;
    expect(rate.eventNumerator, 10);
    expect(rate.durationSeconds, isNull);
    expect(rate.metric.valueOrNull, rate.eventNumerator! / rate.exposure * 100);

    final share = subject.measure(DrivingMeasureId.fullThrottleShare)!;
    expect(share.eventNumerator, isNull);
    expect(share.durationSeconds, 90);
    expect(share.metric.valueOrNull, 90 / 900);
    expect(share.spec.exposureBasis, DrivingExposureBasis.pedalKnownSeconds);
    expect(subject.totals.exposureOf(DrivingExposureBasis.pedalKnownSeconds),
        share.exposure,
        reason: 'the denominator traces back to the summed totals');
  });

  // ── Acceptance 2 ───────────────────────────────────────────────────
  test('equivalent behaviour in flat and hilly context is not a '
      'worse-driving verdict', () async {
    final trips = [_trip('a1', 'a', km: 100), _trip('b1', 'b', km: 100)];
    // Both drivers use full throttle for a tenth of their climbing and a
    // tenth of their flat running. B simply climbed ten times as much.
    DrivingPatternTotals terrain(double climbSec) => _totals(
          seconds: {
            DrivingDurationCounter.climbFullThrottleSeconds: climbSec * 0.1,
            DrivingDurationCounter.flatFullThrottleSeconds: 30,
          },
          exposure: {
            DrivingExposureBasis.movingDistanceKm: 100,
            DrivingExposureBasis.confidentClimbSeconds: climbSec,
            DrivingExposureBasis.confidentFlatSeconds: 300,
          },
        );
    final result = await _run(['a', 'b'], trips,
        {'a1': terrain(300), 'b1': terrain(3000)});

    final a = result.subjects[0].measure(
        DrivingMeasureId.climbFullThrottleShare)!;
    final b = result.subjects[1].measure(
        DrivingMeasureId.climbFullThrottleShare)!;
    expect(a.metric.valueOrNull, closeTo(0.1, 1e-9));
    expect(b.metric.valueOrNull, closeTo(0.1, 1e-9));
    expect(b.exposure, 3000, reason: 'the hilly history is still visible');
    expect(result.differences, isEmpty,
        reason: 'more climbing alone must produce no difference at all');
    expect(a.spec.contextDependent, isTrue,
        reason: 'and the surface must say a climb is not a penalty');
  });

  // ── Acceptance 3 ───────────────────────────────────────────────────
  test('short cold trips against long warm trips are qualified, never an '
      'efficiency verdict', () async {
    final trips = [
      _trip('a1', 'a', km: 3, cold: true, coolant: true),
      _trip('a2', 'a', km: 4, cold: true, coolant: true),
      _trip('b1', 'b', km: 300, coolant: true),
      _trip('b2', 'b', km: 400, coolant: true),
    ];
    final totals = _totals(
        events: {DrivingEventCounter.hardAccelEvents: 5},
        exposure: {DrivingExposureBasis.movingDistanceKm: 50});
    final result = await _run(['a', 'b'], trips,
        {for (final t in trips) t.id: totals});

    expect(result.matching.isMatched, isFalse,
        reason: 'a 3 km cold errand and a 400 km warm run share no cohort');
    expect(result.matching.unmatchedTripCount, 4);
    final measure =
        result.subjects.first.measure(DrivingMeasureId.hardAccelRate)!;
    expect(measure.metric.eligibility, MetricEligibility.qualified);
    expect(measure.metric.qualifications,
        contains(ComparisonQualification.uncontrolledConditions));
    // And nothing in the read model even has a FIELD a consumption or
    // money claim could be carried in.
    for (final key in _jsonKeys(result.toJson())) {
      for (final banned in [
        'consumption',
        'litre',
        'liter',
        'cost',
        'spend',
        'money',
        'saving',
      ]) {
        expect(key.toLowerCase().contains(banned), isFalse,
            reason: '$key must not exist: a behaviour observation is not a '
                'fuel or money figure');
      }
    }
  });

  test('a shared cohort produces a matched subset and states the criteria',
      () async {
    final trips = [
      _trip('a1', 'a', km: 10, coolant: true),
      _trip('a2', 'a', km: 300, coolant: true),
      _trip('b1', 'b', km: 12, coolant: true),
    ];
    final totals = _totals(
        events: {DrivingEventCounter.hardAccelEvents: 2},
        exposure: {DrivingExposureBasis.movingDistanceKm: 20});
    final result = await _run(['a', 'b'], trips,
        {for (final t in trips) t.id: totals});

    expect(result.matching.isMatched, isTrue);
    expect(result.matching.cohorts, [
      const DrivingPatternCohort(
          distanceBand: TripDistanceBand.medium,
          coldStart: ColdStartEvidence.warmObserved),
    ]);
    expect(result.matching.matchedTripCount, 2);
    expect(result.matching.unmatchedTripCount, 1,
        reason: 'the 300 km trip has no counterpart and is reported');
    expect(result.subjects.first.analysedTripCount, 1);
  });

  // ── Acceptance 4 ───────────────────────────────────────────────────
  test('a GPS-only history acquires no zero idle or engine-speed figure',
      () async {
    final trips = [_trip('a1', 'a', km: 100), _trip('b1', 'b', km: 100)];
    final result = await _run(['a', 'b'], trips, {
      // GPS only: distance and moving time, no engine exposure at all.
      'a1': _totals(exposure: {
        DrivingExposureBasis.movingDistanceKm: 100,
        DrivingExposureBasis.movingSeconds: 3600,
      }),
      // OBD equipped, and it idled.
      'b1': _totals(
          seconds: {DrivingDurationCounter.longIdleSeconds: 300},
          exposure: {
            DrivingExposureBasis.movingDistanceKm: 100,
            DrivingExposureBasis.movingSeconds: 3600,
            DrivingExposureBasis.engineKnownSeconds: 3600,
            DrivingExposureBasis.rpmKnownMovingSeconds: 3600,
          }),
    });

    for (final id in [
      DrivingMeasureId.engineIdleShare,
      DrivingMeasureId.highRpmShare,
    ]) {
      final gps = result.subjects[0].measure(id)!;
      expect(gps.metric.eligibility, MetricEligibility.unavailable,
          reason: id.name);
      expect(gps.metric.valueOrNull, isNull, reason: id.name);
      expect(gps.metric.reason, ComparisonUnavailableReason.noEvidence);
    }
    expect(result.subjects[1].measure(DrivingMeasureId.engineIdleShare)!
        .metric.valueOrNull, closeTo(300 / 3600, 1e-9));
    expect(
        result.differences.any((d) => d.id == DrivingMeasureId.engineIdleShare),
        isFalse,
        reason: 'an unavailable side cannot be out-ranked by the other');
  });

  // ── Acceptance 5 ───────────────────────────────────────────────────
  test('no expected consumption blocks the adjusted ranking while the '
      'descriptive measures survive', () async {
    final trips = [_trip('a1', 'a', km: 100), _trip('b1', 'b', km: 100)];
    final result = await _run(['a', 'b'], trips, {
      'a1': _totals(
          events: {DrivingEventCounter.hardAccelEvents: 4},
          exposure: {DrivingExposureBasis.movingDistanceKm: 100}),
      'b1': _totals(
          events: {DrivingEventCounter.hardAccelEvents: 12},
          exposure: {DrivingExposureBasis.movingDistanceKm: 100}),
    });

    expect(result.conditionAdjustedRanking.eligibility,
        MetricEligibility.unavailable);
    expect(result.conditionAdjustedRanking.reason,
        ComparisonUnavailableReason.noExpectedConsumption);
    expect(result.conditionAdjustedRanking.valueOrNull, isNull);
    expect(result.subjects[1].measure(DrivingMeasureId.hardAccelRate)!
        .metric.valueOrNull, 12.0,
        reason: 'the descriptive observation is kept');
    expect(result.subjects.first.coverage.conditionCoverage, 0,
        reason: 'no drive has its full condition context evaluated');
  });

  test('a warm start is distinguished from missing coolant evidence', () {
    expect(coldStartEvidenceOf(_trip('c', 'a', cold: true, coolant: true)),
        ColdStartEvidence.coldObserved);
    expect(coldStartEvidenceOf(_trip('w', 'a', coolant: true)),
        ColdStartEvidence.warmObserved);
    // coldStartSurcharge defaults to false with no coolant telemetry at
    // all — false alone may not certify a warm start.
    expect(coldStartEvidenceOf(_trip('u', 'a')), ColdStartEvidence.unknown);
  });

  test('a cold cohort and an unknown-start cohort never merge', () async {
    final trips = [
      _trip('a1', 'a', km: 10, cold: true, coolant: true),
      _trip('b1', 'b', km: 10),
    ];
    final totals = _totals(
        events: {DrivingEventCounter.hardAccelEvents: 1},
        exposure: {DrivingExposureBasis.movingDistanceKm: 10});
    final result = await _run(['a', 'b'], trips,
        {for (final t in trips) t.id: totals});
    expect(result.matching.isMatched, isFalse,
        reason: 'same distance band, but one start is simply not known');
  });

  // ── Acceptance 6 ───────────────────────────────────────────────────
  test('unassigned and virtual trips count for no vehicle and are reported',
      () async {
    final trips = [
      _trip('a1', 'a', km: 100),
      _trip('b1', 'b', km: 100),
      _trip('legacy', null, km: 500),
      _trip('synthetic', 'a', km: 200, virtual: true),
      _trip('towed', 'a', km: 80, engineRunningSeconds: 10),
    ];
    final loaded = <String>[];
    final totals = _totals(
        events: {DrivingEventCounter.hardAccelEvents: 5},
        exposure: {DrivingExposureBasis.movingDistanceKm: 100});
    final result = await _run(['a', 'b'], trips,
        {for (final t in trips) t.id: totals}, onLoad: loaded.add);

    expect(result.unassignedTripCount, 1);
    expect(loaded, isNot(contains('legacy')));
    expect(loaded, isNot(contains('synthetic')));
    expect(loaded, isNot(contains('towed')));
    final exclusions = result.subjects.first.coverage.exclusions;
    expect(exclusions[ComparisonExclusion.unassignedVehicle], 1);
    expect(exclusions[ComparisonExclusion.virtualRecord], 1);
    expect(exclusions[ComparisonExclusion.engineOffTransport], 1);
    expect(result.subjects.first.coverage.coveredKm, 100,
        reason: 'no excluded distance leaked into the total');
    expect(result.subjects[1].coverage.exclusions[
        ComparisonExclusion.unassignedVehicle], 1,
        reason: 'the same legacy trip is reported, never credited twice');
  });

  // ── Acceptance 8 ───────────────────────────────────────────────────
  group('bounded aggregation', () {
    test('a large history decodes nothing before the first await, and only '
        'for eligible trips', () async {
      final trips = <TripHistoryEntry>[
        for (var i = 0; i < 2400; i++) _trip('u$i', null, km: 30),
        for (var i = 0; i < 2400; i++) _trip('x$i', 'other', km: 30),
        for (var i = 0; i < 25; i++) _trip('a$i', 'a', km: 30),
        for (var i = 0; i < 25; i++) _trip('b$i', 'b', km: 30),
      ];
      var loads = 0;
      final future = aggregateDrivingPatterns(
        selectedVehicleIds: const ['a', 'b'],
        summaries: trips,
        asOf: _asOf,
        chunkSize: 10,
        loadTotals: (entry) {
          loads++;
          return _totals(
              events: {DrivingEventCounter.hardAccelEvents: 1},
              exposure: {DrivingExposureBasis.movingDistanceKm: 30});
        },
      );
      expect(loads, 0,
          reason: 'a synchronous decode here is a decode inside build()');
      final result = await future;
      expect(loads, 50,
          reason: '4800 ineligible trips were settled on summaries alone');
      expect(result.subjects.first.analysedTripCount, 25);
    });

    test('the period filter is applied before any decode', () async {
      final trips = [
        _trip('a1', 'a', km: 100, day: 5),
        _trip('a2', 'a', km: 100, day: 19),
        _trip('b1', 'b', km: 100, day: 19),
      ];
      final loaded = <String>[];
      final result = await aggregateDrivingPatterns(
        selectedVehicleIds: const ['a', 'b'],
        summaries: trips,
        asOf: _asOf,
        periodStart: DateTime.utc(2026, 9, 15),
        loadTotals: (entry) {
          loaded.add(entry.id);
          return _totals(
              events: {DrivingEventCounter.hardAccelEvents: 1},
              exposure: {DrivingExposureBasis.movingDistanceKm: 100});
        },
      );
      expect(loaded, ['a2', 'b1']);
      expect(result.periodStart, DateTime.utc(2026, 9, 15));
      expect(result.periodEnd, _asOf,
          reason: 'the injected clock stamps the open end, never a wall read');
    });
  });

  test('the widest supported difference is reported with both figures',
      () async {
    final trips = [_trip('a1', 'a', km: 100), _trip('b1', 'b', km: 100)];
    final result = await _run(['a', 'b'], trips, {
      'a1': _totals(
          events: {DrivingEventCounter.hardAccelEvents: 2},
          exposure: {DrivingExposureBasis.movingDistanceKm: 100}),
      'b1': _totals(
          events: {DrivingEventCounter.hardAccelEvents: 20},
          exposure: {DrivingExposureBasis.movingDistanceKm: 100}),
    });
    expect(result.differences, hasLength(1));
    final d = result.differences.single;
    expect(d.id, DrivingMeasureId.hardAccelRate);
    expect(d.higherVehicleId, 'b');
    expect(d.lowerVehicleId, 'a');
    expect(d.higher, 20.0);
    expect(d.lower, 2.0);
    expect(d.contextDependent, isFalse);
    expect(result.subjects[1]
        .measure(DrivingMeasureId.hardAccelRate)!
        .representativeTripId, 'b1');
  });
}
