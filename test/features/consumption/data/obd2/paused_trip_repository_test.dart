import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/consumption/data/obd2/paused_trip_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

/// Direct unit tests for [PausedTripRepository] (Refs #561).
///
/// Covers the small CRUD-shaped surface the
/// [TripRecordingController] relies on for the BT-drop pause/resume
/// flow: `save`, `load`, `loadAll`, `delete`, the `boxName` constant,
/// JSON shape (omits null optional fields), and resilience to corrupt
/// payloads.
void main() {
  group('PausedTripRepository (#561)', () {
    late Directory tmpDir;
    late Box<String> box;
    late PausedTripRepository repo;

    setUp(() async {
      tmpDir = Directory.systemTemp.createTempSync('paused_trip_repo_test_');
      Hive.init(tmpDir.path);
      // Microsecond-suffixed box name avoids cross-test contamination on
      // Windows where deleteFromDisk can race the next setUp.
      box = await Hive.openBox<String>(
        'paused_${DateTime.now().microsecondsSinceEpoch}',
      );
      repo = PausedTripRepository(box: box);
    });

    tearDown(() async {
      await box.deleteFromDisk();
      await Hive.close();
      tmpDir.deleteSync(recursive: true);
    });

    // --- Helpers ---------------------------------------------------------

    /// Fully-populated [TripSummary] — every optional field set.
    TripSummary fullSummary() => TripSummary(
          distanceKm: 12.4,
          maxRpm: 4200,
          highRpmSeconds: 18.5,
          idleSeconds: 42,
          harshBrakes: 2,
          harshAccelerations: 1,
          avgLPer100Km: 6.7,
          fuelLitersConsumed: 0.83,
          startedAt: DateTime.utc(2026, 4, 27, 8, 30),
          endedAt: DateTime.utc(2026, 4, 27, 9, 15),
        );

    /// Minimal [TripSummary] — every optional field null. Note
    /// [TripSummary.distanceSource] is NOT part of the serialised
    /// payload, so we leave it at its default `'virtual'` to keep
    /// roundtrips equality-checkable on the fields the repo
    /// persists.
    TripSummary minimalSummary() => const TripSummary(
          distanceKm: 0,
          maxRpm: 0,
          highRpmSeconds: 0,
          idleSeconds: 0,
          harshBrakes: 0,
          harshAccelerations: 0,
        );

    PausedTripEntry fullEntry({String id = '2026-04-27T08:30:00.000Z'}) =>
        PausedTripEntry(
          id: id,
          vehicleId: 'veh-1',
          vin: 'WBA1234567890',
          summary: fullSummary(),
          odometerStartKm: 9271.6,
          odometerLatestKm: 9284.0,
          pausedAt: DateTime.utc(2026, 4, 27, 9, 15, 30),
        );

    PausedTripEntry minimalEntry({
      String id = '2026-04-27T10:00:00.000Z',
      DateTime? pausedAt,
    }) =>
        PausedTripEntry(
          id: id,
          vehicleId: null,
          vin: null,
          summary: minimalSummary(),
          odometerStartKm: null,
          odometerLatestKm: null,
          pausedAt: pausedAt ?? DateTime.utc(2026, 4, 27, 10, 5),
        );

    void expectSummaryEquals(TripSummary actual, TripSummary expected) {
      expect(actual.distanceKm, expected.distanceKm);
      expect(actual.maxRpm, expected.maxRpm);
      expect(actual.highRpmSeconds, expected.highRpmSeconds);
      expect(actual.idleSeconds, expected.idleSeconds);
      expect(actual.harshBrakes, expected.harshBrakes);
      expect(actual.harshAccelerations, expected.harshAccelerations);
      expect(actual.avgLPer100Km, expected.avgLPer100Km);
      expect(actual.fuelLitersConsumed, expected.fuelLitersConsumed);
      expect(actual.startedAt, expected.startedAt);
      expect(actual.endedAt, expected.endedAt);
    }

    void expectEntryEquals(PausedTripEntry actual, PausedTripEntry expected) {
      expect(actual.id, expected.id);
      expect(actual.vehicleId, expected.vehicleId);
      expect(actual.vin, expected.vin);
      expect(actual.odometerStartKm, expected.odometerStartKm);
      expect(actual.odometerLatestKm, expected.odometerLatestKm);
      expect(actual.pausedAt, expected.pausedAt);
      expectSummaryEquals(actual.summary, expected.summary);
    }

    // --- Tests -----------------------------------------------------------

    test('boxName constant equals "obd2_paused_trips"', () {
      expect(PausedTripRepository.boxName, 'obd2_paused_trips');
    });

    test('save then load round-trips an entry with all optional fields '
        'populated', () async {
      final entry = fullEntry();
      await repo.save(entry);

      final loaded = repo.load(entry.id);

      expect(loaded, isNotNull);
      expectEntryEquals(loaded!, entry);
    });

    test('save then load round-trips an entry with all optional fields '
        'null', () async {
      final entry = minimalEntry();
      await repo.save(entry);

      final loaded = repo.load(entry.id);

      expect(loaded, isNotNull);
      expectEntryEquals(loaded!, entry);
      // Sanity: optionals really are null after roundtrip.
      expect(loaded.vehicleId, isNull);
      expect(loaded.vin, isNull);
      expect(loaded.odometerStartKm, isNull);
      expect(loaded.odometerLatestKm, isNull);
      expect(loaded.summary.avgLPer100Km, isNull);
      expect(loaded.summary.fuelLitersConsumed, isNull);
      expect(loaded.summary.startedAt, isNull);
      expect(loaded.summary.endedAt, isNull);
    });

    test('save then delete then load returns null', () async {
      final entry = fullEntry();
      await repo.save(entry);
      expect(repo.load(entry.id), isNotNull);

      await repo.delete(entry.id);

      expect(repo.load(entry.id), isNull);
    });

    test('load returns null for a key that was never saved', () {
      expect(repo.load('never-saved-id'), isNull);
    });

    test('load returns null for a corrupt JSON payload (and does not '
        'throw)', () async {
      const id = '2026-04-27T11:00:00.000Z';
      await box.put(id, 'not json');

      expect(() => repo.load(id), returnsNormally);
      expect(repo.load(id), isNull);
    });

    test('loadAll returns entries sorted newest-first by pausedAt, '
        'skipping interleaved corrupt rows', () async {
      final oldest = minimalEntry(
        id: 'a-oldest',
        pausedAt: DateTime.utc(2026, 4, 27, 8, 0),
      );
      final middle = minimalEntry(
        id: 'b-middle',
        pausedAt: DateTime.utc(2026, 4, 27, 9, 30),
      );
      final newest = minimalEntry(
        id: 'c-newest',
        pausedAt: DateTime.utc(2026, 4, 27, 11, 45),
      );

      // Save in mixed order to prove the sort, not insertion order.
      await repo.save(middle);
      await repo.save(newest);
      await repo.save(oldest);
      // Interleave two corrupt rows that loadAll() must silently skip.
      await box.put('corrupt-1', 'not json');
      await box.put('corrupt-2', '{"id": "missing required keys"}');

      final all = repo.loadAll();

      expect(all, hasLength(3));
      expect(
        all.map((e) => e.id).toList(),
        ['c-newest', 'b-middle', 'a-oldest'],
      );
    });

    test('loadAll on an empty box returns an empty list', () {
      expect(repo.loadAll(), isEmpty);
    });

    test('toJson omits null optional keys at both entry and summary '
        'levels', () {
      final entry = minimalEntry();
      final json = entry.toJson();

      // Entry-level optional keys absent.
      expect(json.containsKey('vehicleId'), isFalse);
      expect(json.containsKey('vin'), isFalse);
      expect(json.containsKey('odometerStartKm'), isFalse);
      expect(json.containsKey('odometerLatestKm'), isFalse);
      // Required keys present.
      expect(json['id'], entry.id);
      expect(json['pausedAt'], entry.pausedAt.toIso8601String());
      expect(json['summary'], isA<Map>());

      // Summary-level optional keys absent.
      final summaryJson = (json['summary'] as Map).cast<String, dynamic>();
      expect(summaryJson.containsKey('avgLPer100Km'), isFalse);
      expect(summaryJson.containsKey('fuelLitersConsumed'), isFalse);
      expect(summaryJson.containsKey('startedAt'), isFalse);
      expect(summaryJson.containsKey('endedAt'), isFalse);
      // Summary required keys present.
      expect(summaryJson['distanceKm'], 0);
      expect(summaryJson['maxRpm'], 0);
      expect(summaryJson['highRpmSeconds'], 0);
      expect(summaryJson['idleSeconds'], 0);
      expect(summaryJson['harshBrakes'], 0);
      expect(summaryJson['harshAccelerations'], 0);
    });

    test('PausedTripEntry.fromJson(toJson(entry)) round-trips for both '
        'fully-populated and fully-minimal entries', () {
      final full = fullEntry();
      final fullRound = PausedTripEntry.fromJson(full.toJson());
      expectEntryEquals(fullRound, full);

      final minimal = minimalEntry();
      final minimalRound = PausedTripEntry.fromJson(minimal.toJson());
      expectEntryEquals(minimalRound, minimal);
    });
  });
}
