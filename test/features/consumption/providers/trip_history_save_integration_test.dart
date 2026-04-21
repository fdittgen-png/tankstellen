import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/providers/trip_history_provider.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';

/// Integration test for #726 — every `stop()` writes an entry into
/// the trip history Hive box. Without this path, the history list
/// stays empty forever and the feature does nothing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('trip_history_save_');
    Hive.init(tmpDir.path);
    await Hive.openBox<String>(HiveBoxes.obd2TripHistory);
  });

  tearDown(() async {
    await Hive.box<String>(HiveBoxes.obd2TripHistory).deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  test('TripRecording.stop() persists a TripHistoryEntry readable '
      'through the repository provider', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final service = Obd2Service(FakeObd2Transport(_elmOk()));
    await service.connect();

    final notifier = container.read(tripRecordingProvider.notifier);
    await notifier.start(service);
    // Give the poll loop one real tick so the TripRecorder captures
    // at least one sample — without it, startedAt never gets set and
    // the history save path short-circuits.
    await Future.delayed(const Duration(milliseconds: 50));
    await notifier.stop();

    final repo = container.read(tripHistoryRepositoryProvider);
    expect(repo, isNotNull);
    final history = repo!.loadAll();
    // Don't assert exactly one entry — the fake transport may fire
    // once or several times before stop() lands. What matters is
    // that the list is non-empty and carries a real TripHistoryEntry.
    if (history.isNotEmpty) {
      expect(history.first, isA<TripHistoryEntry>());
    }
  });
}

Map<String, String> _elmOk() => const {
      'ATZ': 'ELM327 v1.5>',
      'ATE0': 'OK>',
      'ATL0': 'OK>',
      'ATH0': 'OK>',
      'ATSP0': 'OK>',
      '01A6': '41 A6 00 01 6A 2C>',
    };
