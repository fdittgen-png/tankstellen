import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/consumption/data/maintenance_snooze_repository.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/entities/maintenance_suggestion.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/providers/maintenance_provider.dart';
import 'package:tankstellen/features/consumption/providers/trip_history_provider.dart';

/// Provider-layer coverage for the predictive-maintenance pipeline
/// (#1124).
///
/// We pump a real Hive `settings` box into a temporary directory so
/// the [MaintenanceSnoozeRepository] talks to actual storage —
/// matches the pattern used by `velocity_alert_cooldown_test.dart`
/// where the same box is exercised end-to-end. The trip-history list
/// is stubbed via the standard Riverpod `overrideWith` factory so we
/// can hand-build trip fixtures without standing up the trip-history
/// Hive box.
///
/// Two scenarios:
///   1. A snoozed signal disappears from the suggestions list while
///      the snooze timestamp is in the future and reappears once we
///      clear the snooze.
///   2. The controller's `snoozeForDefault` writes the canonical
///      snooze key, and a follow-up `ref.read(suggestionsProvider)`
///      no longer returns the snoozed signal.
void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir =
        await Directory.systemTemp.createTemp('hive_maintenance_provider_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    if (Hive.isBoxOpen(HiveBoxes.settings)) {
      await Hive.box(HiveBoxes.settings).close();
    }
    await Hive.openBox(HiveBoxes.settings);
    await Hive.box(HiveBoxes.settings).clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('maintenanceSuggestionsProvider', () {
    test(
        'filters out signals whose snooze timestamp is in the future, '
        'and lets them reappear once the snooze clears', () async {
      final trips = _idleCreepTrips();

      final container = ProviderContainer(
        overrides: [
          tripHistoryListProvider
              .overrideWith(() => _FixedTripHistoryList(trips)),
        ],
      );
      addTearDown(container.dispose);

      // Baseline: with no snooze, the idle-creep signal is visible.
      var visible = container.read(maintenanceSuggestionsProvider);
      expect(
        visible.map((s) => s.signal),
        contains(MaintenanceSignal.idleRpmCreep),
        reason: 'Idle-creep heuristic should fire on the seeded trips',
      );

      // Snooze idle creep for 30 days.
      final repo = container.read(maintenanceSnoozeRepositoryProvider);
      await repo.snoozeForDefault(
        signal: MaintenanceSignal.idleRpmCreep,
        now: DateTime.now(),
      );
      // Force the derived provider to recompute against the (now)
      // populated snooze repo.
      container.invalidate(maintenanceSuggestionsProvider);

      visible = container.read(maintenanceSuggestionsProvider);
      expect(
        visible.map((s) => s.signal),
        isNot(contains(MaintenanceSignal.idleRpmCreep)),
        reason: 'Snoozed signal must not appear in the suggestion list',
      );

      // Clear the snooze; the signal must reappear.
      await repo.clear(MaintenanceSignal.idleRpmCreep);
      container.invalidate(maintenanceSuggestionsProvider);

      visible = container.read(maintenanceSuggestionsProvider);
      expect(
        visible.map((s) => s.signal),
        contains(MaintenanceSignal.idleRpmCreep),
        reason: 'Cleared snooze must un-hide the signal',
      );
    });

    test(
        'controller.snoozeForDefault writes the canonical key and the '
        'subsequent read drops the signal from the list', () async {
      final trips = _idleCreepTrips();

      final container = ProviderContainer(
        overrides: [
          tripHistoryListProvider
              .overrideWith(() => _FixedTripHistoryList(trips)),
        ],
      );
      addTearDown(container.dispose);

      final controller = container
          .read(maintenanceSuggestionsControllerProvider.notifier);
      await controller.snoozeForDefault(MaintenanceSignal.idleRpmCreep);

      final box = Hive.box(HiveBoxes.settings);
      final stored = box.get(
        '${MaintenanceSnoozeRepository.keyPrefix}'
        '${MaintenanceSignal.idleRpmCreep.name}',
      );
      expect(
        stored,
        isNotNull,
        reason:
            'snoozeForDefault must persist a key in the settings box',
      );

      final visible = container.read(maintenanceSuggestionsProvider);
      expect(
        visible.map((s) => s.signal),
        isNot(contains(MaintenanceSignal.idleRpmCreep)),
        reason: 'Snoozed signal must not be visible after snoozeForDefault',
      );
    });
  });
}

/// Build a 30-day window of trips with a clear idle-RPM creep — first
/// half medians at 800 RPM, second half at 900 RPM (12.5 % rise, well
/// above the 8 % trigger).
List<TripHistoryEntry> _idleCreepTrips() {
  final now = DateTime.now();
  final trips = <TripHistoryEntry>[];
  for (int i = 0; i < 4; i++) {
    final startedAt = now.subtract(Duration(days: 25 - i));
    trips.add(
      _idleTrip(id: 'old-$i', startedAt: startedAt, idleRpm: 800.0),
    );
  }
  for (int i = 0; i < 4; i++) {
    final startedAt = now.subtract(Duration(days: 5 - i));
    trips.add(
      _idleTrip(id: 'new-$i', startedAt: startedAt, idleRpm: 900.0),
    );
  }
  return trips;
}

TripHistoryEntry _idleTrip({
  required String id,
  required DateTime startedAt,
  required double idleRpm,
}) {
  final samples = <TripSample>[];
  for (int j = 0; j < 8; j++) {
    samples.add(
      TripSample(
        timestamp: startedAt.add(Duration(seconds: j)),
        speedKmh: 0,
        rpm: idleRpm,
      ),
    );
  }
  return TripHistoryEntry(
    id: id,
    vehicleId: 'v1',
    summary: TripSummary(
      distanceKm: 5,
      maxRpm: 2500,
      highRpmSeconds: 0,
      idleSeconds: 8,
      harshBrakes: 0,
      harshAccelerations: 0,
      startedAt: startedAt,
      endedAt: startedAt.add(const Duration(minutes: 5)),
    ),
    samples: samples,
  );
}

/// Test-only override for [tripHistoryListProvider] — lets us seed an
/// arbitrary trip list without standing up a Hive trip-history box.
class _FixedTripHistoryList extends TripHistoryList {
  _FixedTripHistoryList(this._value);
  final List<TripHistoryEntry> _value;

  @override
  List<TripHistoryEntry> build() => _value;
}
