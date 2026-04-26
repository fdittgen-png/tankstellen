import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/feedback/auto_record_badge_provider.dart';
import 'package:tankstellen/core/feedback/auto_record_badge_service.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/providers/trip_history_provider.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';

/// Tests for the public `automatic` flag plumbing through the trip
/// recording provider (#1004 phase 2a).
///
/// The flag piggy-backs on the existing `_saveToHistory(automatic:)`
/// path. Asserting it lands in the persisted [TripHistoryEntry] *and*
/// triggers a badge increment proves both halves of the plumbing —
/// the manual call sites that omit the flag must keep their old
/// behaviour, and the new `stopAndSaveAutomatic` wrapper must reach
/// the same code path as `stop(automatic: true)`.
///
/// We drive a real [TripRecording] notifier with a [FakeObd2Transport]
/// and inject a handful of samples via `debugController.debugInjectSample`
/// so the recorder sets `startedAt` and accumulates non-zero distance
/// — without that the empty-trip early-return inside `_saveToHistory`
/// would skip the badge bump entirely, and we'd be testing nothing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('trip_auto_flag_test_');
    Hive.init(tmpDir.path);
    await Hive.openBox<String>(HiveBoxes.obd2TripHistory);
  });

  tearDown(() async {
    await Hive.box<String>(HiveBoxes.obd2TripHistory).deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  Future<TripHistoryEntry> runOnce(
    ProviderContainer container, {
    required Future<void> Function(TripRecording notifier) stopper,
  }) async {
    final service = Obd2Service(FakeObd2Transport(_elmOk()));
    await service.connect();

    final notifier = container.read(tripRecordingProvider.notifier);
    await notifier.start(service);
    final ctl = notifier.debugController;
    expect(ctl, isNotNull,
        reason: 'provider must own a controller while recording');
    final start = DateTime.now();
    // Inject 5 deterministic samples so the summary has startedAt set
    // and the distance accumulator clears the 0.01 km early-return
    // floor in `_saveToHistory`. Without this the badge path is never
    // reached and we'd assert against a no-op.
    for (int i = 0; i < 5; i++) {
      ctl!.debugInjectSample(
        speedKmh: 50 + i.toDouble(),
        rpm: 2000 + i * 10,
        at: start.add(Duration(seconds: i)),
        fuelRateLPerHour: 6.0,
      );
    }
    await stopper(notifier);

    final repo = container.read(tripHistoryRepositoryProvider);
    expect(repo, isNotNull);
    final history = repo!.loadAll();
    expect(history, isNotEmpty,
        reason: 'stop() must have persisted a TripHistoryEntry — the '
            'sample-injection above guarantees a non-empty summary');
    return history.first;
  }

  test(
    'stop(automatic: true) marks the persisted entry as auto-recorded '
    'and increments the badge',
    () async {
      final fakeBadge = _FakeAutoRecordBadgeService();
      final container = ProviderContainer(overrides: [
        autoRecordBadgeServiceProvider.overrideWith((ref) async => fakeBadge),
      ]);
      addTearDown(container.dispose);

      final entry = await runOnce(
        container,
        stopper: (n) => n.stop(automatic: true),
      );

      expect(entry.automatic, isTrue,
          reason: 'stop(automatic: true) must persist '
              'TripHistoryEntry.automatic = true so the trip-detail '
              'screen knows to decrement the badge on view');
      expect(fakeBadge.incrementCalls, 1,
          reason: 'auto-recorded saves bump the launcher-icon badge');
    },
  );

  test(
    'stopAndSaveAutomatic() is the same path as stop(automatic: true)',
    () async {
      final fakeBadge = _FakeAutoRecordBadgeService();
      final container = ProviderContainer(overrides: [
        autoRecordBadgeServiceProvider.overrideWith((ref) async => fakeBadge),
      ]);
      addTearDown(container.dispose);

      final entry = await runOnce(
        container,
        stopper: (n) => n.stopAndSaveAutomatic(),
      );

      expect(entry.automatic, isTrue,
          reason: 'stopAndSaveAutomatic must reach _saveToHistory '
              'with automatic: true');
      expect(fakeBadge.incrementCalls, 1,
          reason: 'stopAndSaveAutomatic must increment the badge once');
    },
  );

  test(
    'stop() with no automatic flag stays manual — no badge increment',
    () async {
      final fakeBadge = _FakeAutoRecordBadgeService();
      final container = ProviderContainer(overrides: [
        autoRecordBadgeServiceProvider.overrideWith((ref) async => fakeBadge),
      ]);
      addTearDown(container.dispose);

      final entry = await runOnce(
        container,
        stopper: (n) => n.stop(),
      );

      expect(entry.automatic, isFalse,
          reason: 'manual stop() must NOT mark the entry as automatic');
      expect(fakeBadge.incrementCalls, 0,
          reason: 'manual stops must not bump the badge — that\'s the '
              'whole reason the flag exists');
    },
  );
}

/// Fake badge service that records `increment` calls so the test can
/// assert the auto-record path bumped it without standing up a real
/// SharedPreferences mock.
class _FakeAutoRecordBadgeService implements AutoRecordBadgeService {
  int _count = 0;
  int incrementCalls = 0;
  int decrementCalls = 0;
  int markAllCalls = 0;

  @override
  int get count => _count;

  @override
  Future<void> increment() async {
    incrementCalls++;
    _count++;
  }

  @override
  Future<void> decrement() async {
    decrementCalls++;
    if (_count > 0) _count--;
  }

  @override
  Future<void> markAllAsRead() async {
    markAllCalls++;
    _count = 0;
  }
}

Map<String, String> _elmOk() => const {
      'ATZ': 'ELM327 v1.5>',
      'ATE0': 'OK>',
      'ATL0': 'OK>',
      'ATH0': 'OK>',
      'ATSP0': 'OK>',
      '01A6': '41 A6 00 01 6A 2C>',
    };
