import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late Box<String> box;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('trip_history_test_');
    Hive.init(tmpDir.path);
    box = await Hive.openBox<String>(
      'test_${DateTime.now().microsecondsSinceEpoch}',
    );
  });

  tearDown(() async {
    await box.deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  TripSummary mkSummary({required DateTime startedAt, double km = 10}) {
    return TripSummary(
      distanceKm: km,
      maxRpm: 2800,
      highRpmSeconds: 12,
      idleSeconds: 30,
      harshBrakes: 1,
      harshAccelerations: 2,
      avgLPer100Km: 6.5,
      fuelLitersConsumed: km * 6.5 / 100,
      startedAt: startedAt,
      endedAt: startedAt.add(const Duration(minutes: 20)),
    );
  }

  group('TripHistoryRepository (#726)', () {
    test('save + loadAll round-trips all summary fields', () async {
      final repo = TripHistoryRepository(box: box);
      final start = DateTime(2026, 4, 21, 12, 0);
      await repo.save(TripHistoryEntry(
        id: start.toIso8601String(),
        vehicleId: 'car-a',
        summary: mkSummary(startedAt: start),
      ));

      final all = repo.loadAll();
      expect(all, hasLength(1));
      expect(all.first.vehicleId, 'car-a');
      expect(all.first.summary.distanceKm, 10);
      expect(all.first.summary.avgLPer100Km, 6.5);
      expect(all.first.summary.harshBrakes, 1);
      expect(all.first.summary.harshAccelerations, 2);
      expect(all.first.summary.startedAt, start);
    });

    test('loadAll sorts newest-first — most recent trip is what the '
        'user scans first', () async {
      final repo = TripHistoryRepository(box: box);
      final earlier = DateTime(2026, 4, 20, 9);
      final later = DateTime(2026, 4, 21, 18);
      await repo.save(TripHistoryEntry(
        id: earlier.toIso8601String(),
        vehicleId: null,
        summary: mkSummary(startedAt: earlier, km: 5),
      ));
      await repo.save(TripHistoryEntry(
        id: later.toIso8601String(),
        vehicleId: null,
        summary: mkSummary(startedAt: later, km: 20),
      ));

      final all = repo.loadAll();
      expect(all.first.summary.startedAt, later);
      expect(all[1].summary.startedAt, earlier);
    });

    test('cap drops oldest entries — trip history is a rolling log, '
        'not an archive', () async {
      final repo = TripHistoryRepository(box: box, cap: 3);
      for (var i = 0; i < 5; i++) {
        final start = DateTime(2026, 4, 1 + i);
        await repo.save(TripHistoryEntry(
          id: start.toIso8601String(),
          vehicleId: null,
          summary: mkSummary(startedAt: start),
        ));
      }
      final all = repo.loadAll();
      expect(all, hasLength(3));
      expect(all.first.summary.startedAt, DateTime(2026, 4, 5));
      expect(all.last.summary.startedAt, DateTime(2026, 4, 3));
    });

    test('corrupt JSON entry is silently skipped so the rest of the '
        'log stays readable', () async {
      await box.put('broken', 'this is not JSON');
      final repo = TripHistoryRepository(box: box);
      final good = DateTime(2026, 4, 21);
      await repo.save(TripHistoryEntry(
        id: good.toIso8601String(),
        vehicleId: null,
        summary: mkSummary(startedAt: good),
      ));
      final all = repo.loadAll();
      expect(all, hasLength(1));
      expect(all.first.summary.startedAt, good);
    });

    test('delete removes only the targeted entry', () async {
      final repo = TripHistoryRepository(box: box);
      final a = DateTime(2026, 4, 20);
      final b = DateTime(2026, 4, 21);
      await repo.save(TripHistoryEntry(
        id: a.toIso8601String(),
        vehicleId: null,
        summary: mkSummary(startedAt: a),
      ));
      await repo.save(TripHistoryEntry(
        id: b.toIso8601String(),
        vehicleId: null,
        summary: mkSummary(startedAt: b),
      ));
      await repo.delete(a.toIso8601String());
      final all = repo.loadAll();
      expect(all, hasLength(1));
      expect(all.first.summary.startedAt, b);
    });

    test('nullable fields (no fuel rate, no end time) survive '
        'round-trip without throwing', () async {
      final repo = TripHistoryRepository(box: box);
      final start = DateTime(2026, 4, 21);
      final noFuel = TripSummary(
        distanceKm: 8,
        maxRpm: 2000,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        startedAt: start,
        // avgLPer100Km, fuelLitersConsumed, endedAt all null
      );
      await repo.save(TripHistoryEntry(
        id: start.toIso8601String(),
        vehicleId: null,
        summary: noFuel,
      ));
      final all = repo.loadAll();
      expect(all.first.summary.avgLPer100Km, isNull);
      expect(all.first.summary.fuelLitersConsumed, isNull);
      expect(all.first.summary.endedAt, isNull);
    });
  });

  group('TripHistoryRepository.onSavedHook (#1193 phase 2)', () {
    test(
        'save() invokes onSavedHook with the saved entry vehicleId', () async {
      final hookCalls = <String>[];
      final repo = TripHistoryRepository(
        box: box,
        onSavedHook: hookCalls.add,
      );
      final start = DateTime(2026, 4, 21);
      await repo.save(TripHistoryEntry(
        id: start.toIso8601String(),
        vehicleId: 'car-a',
        summary: mkSummary(startedAt: start),
      ));
      expect(hookCalls, ['car-a']);
    });

    test(
        'save() does NOT invoke onSavedHook when vehicleId is null '
        '— orphan trips are out of scope for the aggregator', () async {
      final hookCalls = <String>[];
      final repo = TripHistoryRepository(
        box: box,
        onSavedHook: hookCalls.add,
      );
      final start = DateTime(2026, 4, 21);
      await repo.save(TripHistoryEntry(
        id: start.toIso8601String(),
        vehicleId: null,
        summary: mkSummary(startedAt: start),
      ));
      expect(hookCalls, isEmpty);
    });

    test(
        'a throwing onSavedHook does NOT make save() rethrow — the trip '
        'has already persisted, the aggregator failure must not derail '
        'the trip-stop flow', () async {
      final repo = TripHistoryRepository(
        box: box,
        onSavedHook: (_) => throw StateError('aggregator boom'),
      );
      final start = DateTime(2026, 4, 21);
      // Must complete without throwing.
      await expectLater(
        repo.save(TripHistoryEntry(
          id: start.toIso8601String(),
          vehicleId: 'car-a',
          summary: mkSummary(startedAt: start),
        )),
        completes,
      );
      // And the trip must still be persisted — the hook fires AFTER
      // the put, so a hook throw doesn't roll back the storage write.
      expect(repo.loadAll(), hasLength(1));
    });

    test('onSavedHook is mutable post-construction (production wiring path)',
        () async {
      final repo = TripHistoryRepository(box: box);
      final hookCalls = <String>[];
      repo.onSavedHook = hookCalls.add;

      final start = DateTime(2026, 4, 21);
      await repo.save(TripHistoryEntry(
        id: start.toIso8601String(),
        vehicleId: 'car-b',
        summary: mkSummary(startedAt: start),
      ));
      expect(hookCalls, ['car-b']);
    });
  });

  group('TripSample throttle persistence (#1261)', () {
    test('sample with throttle round-trips through save / loadAll', () async {
      final repo = TripHistoryRepository(box: box);
      final start = DateTime(2026, 4, 21);
      final ts = start.add(const Duration(seconds: 5));
      await repo.save(TripHistoryEntry(
        id: start.toIso8601String(),
        vehicleId: null,
        summary: mkSummary(startedAt: start),
        samples: [
          TripSample(
            timestamp: ts,
            speedKmh: 55,
            rpm: 1800,
            fuelRateLPerHour: 4.2,
            throttlePercent: 37.5,
          ),
        ],
      ));

      final loaded = repo.loadAll();
      expect(loaded, hasLength(1));
      expect(loaded.first.samples, hasLength(1));
      expect(loaded.first.samples.first.throttlePercent, 37.5);
      // And the other compact-key fields still round-trip cleanly.
      expect(loaded.first.samples.first.speedKmh, 55);
      expect(loaded.first.samples.first.rpm, 1800);
      expect(loaded.first.samples.first.fuelRateLPerHour, 4.2);
    });

    test(
        'sample with null throttle does NOT include the "th" key in stored '
        'JSON — matches the parsimony rule the "f" key already follows',
        () async {
      final repo = TripHistoryRepository(box: box);
      final start = DateTime(2026, 4, 21);
      final ts = start.add(const Duration(seconds: 5));
      await repo.save(TripHistoryEntry(
        id: start.toIso8601String(),
        vehicleId: null,
        summary: mkSummary(startedAt: start),
        samples: [
          TripSample(
            timestamp: ts,
            speedKmh: 55,
            rpm: 1800,
            // throttlePercent and fuelRateLPerHour both null
          ),
        ],
      ));

      // Read the raw stored JSON and inspect the sample's keys.
      final raw = box.get(start.toIso8601String())!;
      final decoded = (jsonDecode(raw) as Map).cast<String, dynamic>();
      final samples = (decoded['samples'] as List).cast<Map>();
      expect(samples.first.containsKey('th'), isFalse);
      expect(samples.first.containsKey('f'), isFalse);
    });

    test(
        'legacy JSON (pre-#1261) without the "th" key deserialises with '
        'throttlePercent: null — backward compat for trips on disk',
        () async {
      final start = DateTime(2026, 4, 21);
      final ts = start.add(const Duration(seconds: 5));
      // Hand-craft a JSON payload as a pre-#1261 build would have
      // written it: every compact key EXCEPT 'th' is present.
      final legacyJson = jsonEncode({
        'id': start.toIso8601String(),
        'vehicleId': null,
        'summary': {
          'distanceKm': 10.0,
          'maxRpm': 2800.0,
          'highRpmSeconds': 0.0,
          'idleSeconds': 0.0,
          'harshBrakes': 0,
          'harshAccelerations': 0,
          'startedAt': start.toIso8601String(),
        },
        'samples': [
          {
            't': ts.millisecondsSinceEpoch,
            's': 55.0,
            'r': 1800.0,
            'f': 4.2,
          },
        ],
      });
      await box.put(start.toIso8601String(), legacyJson);

      final repo = TripHistoryRepository(box: box);
      final loaded = repo.loadAll();
      expect(loaded, hasLength(1));
      expect(loaded.first.samples, hasLength(1));
      expect(loaded.first.samples.first.throttlePercent, isNull);
      // Other fields still parse normally.
      expect(loaded.first.samples.first.speedKmh, 55);
      expect(loaded.first.samples.first.fuelRateLPerHour, 4.2);
    });
  });

  group('TripSummary.coldStartSurcharge persistence (#1262 phase 2)', () {
    test(
        'summary with coldStartSurcharge true round-trips through save / '
        'loadAll', () async {
      final repo = TripHistoryRepository(box: box);
      final start = DateTime(2026, 4, 21, 12);
      final cold = TripSummary(
        distanceKm: 4,
        maxRpm: 1800,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        startedAt: start,
        endedAt: start.add(const Duration(minutes: 5)),
        coldStartSurcharge: true,
      );
      await repo.save(TripHistoryEntry(
        id: start.toIso8601String(),
        vehicleId: null,
        summary: cold,
      ));

      final loaded = repo.loadAll();
      expect(loaded, hasLength(1));
      expect(loaded.first.summary.coldStartSurcharge, isTrue);
    });

    test(
        'summary with coldStartSurcharge false round-trips and the stored '
        'JSON carries an explicit "cs": false (no parsimony rule for '
        'this key — every trip persists it)', () async {
      final repo = TripHistoryRepository(box: box);
      final start = DateTime(2026, 4, 21, 12);
      final warm = TripSummary(
        distanceKm: 30,
        maxRpm: 2800,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        startedAt: start,
        endedAt: start.add(const Duration(minutes: 30)),
        // coldStartSurcharge defaults false
      );
      await repo.save(TripHistoryEntry(
        id: start.toIso8601String(),
        vehicleId: null,
        summary: warm,
      ));

      final raw = box.get(start.toIso8601String())!;
      final decoded = (jsonDecode(raw) as Map).cast<String, dynamic>();
      final summaryJson = (decoded['summary'] as Map).cast<String, dynamic>();
      expect(summaryJson['cs'], isFalse);

      final loaded = repo.loadAll();
      expect(loaded.first.summary.coldStartSurcharge, isFalse);
    });

    test(
        'legacy JSON (pre-#1262 phase 2) without the "cs" key '
        'deserialises with coldStartSurcharge: false — older trips '
        'were written before the heuristic landed', () async {
      final start = DateTime(2026, 4, 21, 12);
      final legacyJson = jsonEncode({
        'id': start.toIso8601String(),
        'vehicleId': null,
        'summary': {
          'distanceKm': 10.0,
          'maxRpm': 2800.0,
          'highRpmSeconds': 0.0,
          'idleSeconds': 0.0,
          'harshBrakes': 0,
          'harshAccelerations': 0,
          'startedAt': start.toIso8601String(),
          // 'cs' deliberately absent
        },
      });
      await box.put(start.toIso8601String(), legacyJson);

      final repo = TripHistoryRepository(box: box);
      final loaded = repo.loadAll();
      expect(loaded, hasLength(1));
      expect(loaded.first.summary.coldStartSurcharge, isFalse);
    });
  });

  group('TripSummary.secondsBelowOptimalGear persistence (#1263 phase 2)', () {
    test(
        'summary with secondsBelowOptimalGear populated round-trips through '
        'save / loadAll', () async {
      final repo = TripHistoryRepository(box: box);
      final start = DateTime(2026, 4, 21, 12);
      final geared = TripSummary(
        distanceKm: 25,
        maxRpm: 3200,
        highRpmSeconds: 18,
        idleSeconds: 12,
        harshBrakes: 0,
        harshAccelerations: 0,
        startedAt: start,
        endedAt: start.add(const Duration(minutes: 25)),
        secondsBelowOptimalGear: 120.5,
      );
      await repo.save(TripHistoryEntry(
        id: start.toIso8601String(),
        vehicleId: null,
        summary: geared,
      ));

      final loaded = repo.loadAll();
      expect(loaded, hasLength(1));
      expect(loaded.first.summary.secondsBelowOptimalGear, 120.5);
    });

    test(
        'summary with secondsBelowOptimalGear null does NOT include the '
        '"sblog" key in stored JSON — matches the parsimony rule the '
        '"f" / "th" / "el" / "ct" keys already follow', () async {
      final repo = TripHistoryRepository(box: box);
      final start = DateTime(2026, 4, 21, 12);
      final noGear = TripSummary(
        distanceKm: 12,
        maxRpm: 2400,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        startedAt: start,
        endedAt: start.add(const Duration(minutes: 14)),
        // secondsBelowOptimalGear defaults null
      );
      await repo.save(TripHistoryEntry(
        id: start.toIso8601String(),
        vehicleId: null,
        summary: noGear,
      ));

      final raw = box.get(start.toIso8601String())!;
      final decoded = (jsonDecode(raw) as Map).cast<String, dynamic>();
      final summaryJson = (decoded['summary'] as Map).cast<String, dynamic>();
      expect(summaryJson.containsKey('sblog'), isFalse);

      final loaded = repo.loadAll();
      expect(loaded.first.summary.secondsBelowOptimalGear, isNull);
    });

    test(
        'legacy JSON (pre-#1263 phase 2) without the "sblog" key '
        'deserialises with secondsBelowOptimalGear: null — older trips '
        'were written before the gear-inference metric landed', () async {
      final start = DateTime(2026, 4, 21, 12);
      final legacyJson = jsonEncode({
        'id': start.toIso8601String(),
        'vehicleId': null,
        'summary': {
          'distanceKm': 18.0,
          'maxRpm': 3000.0,
          'highRpmSeconds': 0.0,
          'idleSeconds': 0.0,
          'harshBrakes': 0,
          'harshAccelerations': 0,
          'startedAt': start.toIso8601String(),
          // 'sblog' deliberately absent
        },
      });
      await box.put(start.toIso8601String(), legacyJson);

      final repo = TripHistoryRepository(box: box);
      final loaded = repo.loadAll();
      expect(loaded, hasLength(1));
      expect(loaded.first.summary.secondsBelowOptimalGear, isNull);
    });
  });

  group('TripSample engineLoad + coolantTemp persistence (#1262 phase 1)', () {
    test(
        'sample with engineLoadPercent and coolantTempC round-trips through '
        'save / loadAll', () async {
      final repo = TripHistoryRepository(box: box);
      final start = DateTime(2026, 4, 21);
      final ts = start.add(const Duration(seconds: 5));
      await repo.save(TripHistoryEntry(
        id: start.toIso8601String(),
        vehicleId: null,
        summary: mkSummary(startedAt: start),
        samples: [
          TripSample(
            timestamp: ts,
            speedKmh: 55,
            rpm: 1800,
            fuelRateLPerHour: 4.2,
            throttlePercent: 37.5,
            engineLoadPercent: 42.5,
            coolantTempC: 82.0,
          ),
        ],
      ));

      final loaded = repo.loadAll();
      expect(loaded, hasLength(1));
      expect(loaded.first.samples, hasLength(1));
      final s = loaded.first.samples.first;
      expect(s.engineLoadPercent, 42.5);
      expect(s.coolantTempC, 82.0);
      // Throttle still survives — the new keys don't displace the old.
      expect(s.throttlePercent, 37.5);
    });

    test(
        'sample with null engineLoadPercent / coolantTempC does NOT include '
        '"el" / "ct" keys in stored JSON — matches the parsimony rule the '
        '"f" / "th" keys already follow', () async {
      final repo = TripHistoryRepository(box: box);
      final start = DateTime(2026, 4, 21);
      final ts = start.add(const Duration(seconds: 5));
      await repo.save(TripHistoryEntry(
        id: start.toIso8601String(),
        vehicleId: null,
        summary: mkSummary(startedAt: start),
        samples: [
          TripSample(
            timestamp: ts,
            speedKmh: 55,
            rpm: 1800,
            // engineLoadPercent / coolantTempC both null
          ),
        ],
      ));

      final raw = box.get(start.toIso8601String())!;
      final decoded = (jsonDecode(raw) as Map).cast<String, dynamic>();
      final samples = (decoded['samples'] as List).cast<Map>();
      expect(samples.first.containsKey('el'), isFalse);
      expect(samples.first.containsKey('ct'), isFalse);
    });

    test(
        'legacy JSON (pre-#1262) without "el" / "ct" keys deserialises with '
        'engineLoadPercent: null AND coolantTempC: null — backward compat',
        () async {
      final start = DateTime(2026, 4, 21);
      final ts = start.add(const Duration(seconds: 5));
      // Legacy sample JSON: 't','s','r','f','th' present, but no
      // 'el' / 'ct' (the trip was recorded before #1262 phase 1).
      final legacyJson = jsonEncode({
        'id': start.toIso8601String(),
        'vehicleId': null,
        'summary': {
          'distanceKm': 10.0,
          'maxRpm': 2800.0,
          'highRpmSeconds': 0.0,
          'idleSeconds': 0.0,
          'harshBrakes': 0,
          'harshAccelerations': 0,
          'startedAt': start.toIso8601String(),
        },
        'samples': [
          {
            't': ts.millisecondsSinceEpoch,
            's': 55.0,
            'r': 1800.0,
            'f': 4.2,
            'th': 30.0,
          },
        ],
      });
      await box.put(start.toIso8601String(), legacyJson);

      final repo = TripHistoryRepository(box: box);
      final loaded = repo.loadAll();
      expect(loaded, hasLength(1));
      expect(loaded.first.samples, hasLength(1));
      final s = loaded.first.samples.first;
      expect(s.engineLoadPercent, isNull);
      expect(s.coolantTempC, isNull);
      // Existing fields still parse — backward compat means "we add to
      // the schema, we don't break what the old schema persisted."
      expect(s.throttlePercent, 30.0);
      expect(s.fuelRateLPerHour, 4.2);
    });
  });
}
