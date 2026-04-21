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
}
