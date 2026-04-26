import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/providers/trip_history_provider.dart';

/// Unit tests for the two providers in `trip_history_provider.dart`
/// (Refs #561). The repository accessor swallows a closed Hive box
/// instead of throwing — widget tests rely on that, so we pin both the
/// closed-box and open-box branches. The notifier is then exercised
/// against a real Hive temp box so refresh / delete behave like the
/// production wiring.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;

  TripSummary mkSummary({required DateTime startedAt, double km = 12}) {
    return TripSummary(
      distanceKm: km,
      maxRpm: 3000,
      highRpmSeconds: 8,
      idleSeconds: 25,
      harshBrakes: 1,
      harshAccelerations: 1,
      avgLPer100Km: 5.8,
      fuelLitersConsumed: km * 5.8 / 100,
      startedAt: startedAt,
      endedAt: startedAt.add(const Duration(minutes: 18)),
    );
  }

  TripHistoryEntry mkEntry({required DateTime startedAt, double km = 12}) {
    return TripHistoryEntry(
      id: startedAt.toIso8601String(),
      vehicleId: 'car-a',
      summary: mkSummary(startedAt: startedAt, km: km),
    );
  }

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('trip_history_provider_');
    Hive.init(tmpDir.path);
  });

  tearDown(() async {
    if (Hive.isBoxOpen(HiveBoxes.obd2TripHistory)) {
      await Hive.box<String>(HiveBoxes.obd2TripHistory).deleteFromDisk();
    }
    await Hive.close();
    if (tmpDir.existsSync()) {
      tmpDir.deleteSync(recursive: true);
    }
  });

  group('tripHistoryRepositoryProvider (#726)', () {
    test('returns null when the obd2TripHistory box is not open — '
        'widget tests skip Hive init and must not crash', () {
      // Sanity: the box is genuinely closed at this point.
      expect(Hive.isBoxOpen(HiveBoxes.obd2TripHistory), isFalse);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(tripHistoryRepositoryProvider), isNull);
    });

    test('returns a repository wrapping the open Hive box once init '
        'has run', () async {
      final box = await Hive.openBox<String>(HiveBoxes.obd2TripHistory);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(tripHistoryRepositoryProvider);
      expect(repo, isNotNull);

      // Round-trip through the repo to prove it's wired to *this* box.
      final start = DateTime(2026, 4, 21, 9);
      await repo!.save(mkEntry(startedAt: start));
      expect(box.containsKey(start.toIso8601String()), isTrue);
    });
  });

  group('TripHistoryList (#726)', () {
    test('build returns [] when the repo provider is null '
        '(box not open)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(tripHistoryListProvider), isEmpty);
    });

    test('build returns whatever loadAll() yields once the box is '
        'open and populated', () async {
      await Hive.openBox<String>(HiveBoxes.obd2TripHistory);

      // Populate via the real repo so we use the same JSON encoding
      // production writes — hand-crafting Hive payloads couples the
      // test to the wire format.
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repo = container.read(tripHistoryRepositoryProvider)!;
      final earlier = DateTime(2026, 4, 20, 8);
      final later = DateTime(2026, 4, 21, 19);
      await repo.save(mkEntry(startedAt: earlier, km: 7));
      await repo.save(mkEntry(startedAt: later, km: 22));

      final list = container.read(tripHistoryListProvider);
      // Newest-first ordering is the repo's contract; verifying it
      // here shields the UI from an accidental sort regression.
      expect(list, hasLength(2));
      expect(list.first.summary.startedAt, later);
      expect(list.last.summary.startedAt, earlier);
    });

    test('refresh re-reads the box after a direct write — UI picks up '
        'a new entry without rebuilding the provider tree', () async {
      await Hive.openBox<String>(HiveBoxes.obd2TripHistory);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repo = container.read(tripHistoryRepositoryProvider)!;
      final initial = DateTime(2026, 4, 20);
      await repo.save(mkEntry(startedAt: initial));

      // Read once to materialise initial state.
      expect(container.read(tripHistoryListProvider), hasLength(1));

      // Add a second trip *without* invalidating the provider —
      // refresh() is the only path that should pick it up.
      final added = DateTime(2026, 4, 21);
      await repo.save(mkEntry(startedAt: added, km: 30));

      container.read(tripHistoryListProvider.notifier).refresh();
      final after = container.read(tripHistoryListProvider);
      expect(after, hasLength(2));
      expect(after.first.summary.startedAt, added);
    });

    test('delete drops the targeted entry and pushes the new list '
        'into state', () async {
      await Hive.openBox<String>(HiveBoxes.obd2TripHistory);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repo = container.read(tripHistoryRepositoryProvider)!;
      final keep = DateTime(2026, 4, 20);
      final drop = DateTime(2026, 4, 21);
      await repo.save(mkEntry(startedAt: keep, km: 5));
      await repo.save(mkEntry(startedAt: drop, km: 40));

      // Materialise initial state.
      expect(container.read(tripHistoryListProvider), hasLength(2));

      await container
          .read(tripHistoryListProvider.notifier)
          .delete(drop.toIso8601String());

      final after = container.read(tripHistoryListProvider);
      expect(after, hasLength(1));
      expect(after.first.summary.startedAt, keep);
    });

    test('delete is a silent no-op when the repo provider is null — '
        'matches the early-return in production', () async {
      // Box is intentionally NOT opened here.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initial state is empty (repo null branch in build).
      expect(container.read(tripHistoryListProvider), isEmpty);

      // Should not throw, should not change state.
      await container
          .read(tripHistoryListProvider.notifier)
          .delete('does-not-matter');

      expect(container.read(tripHistoryListProvider), isEmpty);
    });
  });
}
