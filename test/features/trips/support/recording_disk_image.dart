// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/app/startup/trip_recovery_phase.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/telemetry/process_death_context.dart';
import 'package:tankstellen/features/obd2/data/active_trip_repository.dart';
import 'package:tankstellen/features/obd2/data/active_trip_sample_wal.dart';
import 'package:tankstellen/features/obd2/data/paused_trip_repository.dart';
import 'package:tankstellen/features/trips/data/trip_history_repository.dart';

/// What a process kill leaves behind (#4162): the three recording boxes
/// and the append-only sample WAL, byte for byte, at one instant.
class RecordingDiskImage {
  const RecordingDiskImage({
    required this.active,
    required this.paused,
    required this.history,
    required this.walBytes,
  });

  final Map<dynamic, String> active;
  final Map<dynamic, String> paused;
  final Map<dynamic, String> history;

  /// Null when no sample WAL file existed.
  final List<int>? walBytes;

  RecordingDiskImage copyWith({
    Map<dynamic, String>? active,
    Map<dynamic, String>? paused,
    List<int>? walBytes,
    bool dropWal = false,
  }) =>
      RecordingDiskImage(
        active: active ?? this.active,
        paused: paused ?? this.paused,
        history: history,
        walBytes: dropWal ? null : (walBytes ?? this.walBytes),
      );
}

/// The recording's disk, as production opens it (#4162): real Hive boxes
/// under their production names — so every resolver in the recording path
/// finds them exactly as it does on a phone — and the append-only sample
/// WAL in a temporary app-support directory.
///
/// A kill test is three moves:
///
/// 1. [capture] the disk at the instant the kill lands;
/// 2. quiesce the old "process" any way that works (its writes after the
///    capture never happened, as far as the disk image is concerned);
/// 3. [relaunch] from the image: restore it, mint a new process identity,
///    and run the production launch recovery passes, in production order.
class RecordingDisk {
  RecordingDisk._(this._dir, this.activeBox, this.pausedBox, this.historyBox);

  final Directory _dir;
  final Box<String> activeBox;
  final Box<String> pausedBox;
  final Box<String> historyBox;

  static const MethodChannel _pathProvider =
      MethodChannel('plugins.flutter.io/path_provider');

  /// Open a fresh disk. Call from `setUp`; pair with [close].
  static Future<RecordingDisk> open() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = Directory.systemTemp.createTempSync('recording_disk_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProvider, (call) async => dir.path);
    Hive.init(dir.path);
    return RecordingDisk._(
      dir,
      await Hive.openBox<String>(HiveBoxes.obd2ActiveTrip),
      await Hive.openBox<String>(HiveBoxes.obd2PausedTrips),
      await Hive.openBox<String>(HiveBoxes.obd2TripHistory),
    );
  }

  File get walFile => File('${_dir.path}/${ActiveTripSampleWal.fileName}');

  ActiveTripRepository get activeRepo => ActiveTripRepository(
      box: activeBox, sampleWal: ActiveTripSampleWal.instance);
  PausedTripRepository get pausedRepo => PausedTripRepository(box: pausedBox);
  TripHistoryRepository get historyRepo =>
      TripHistoryRepository(box: historyBox);

  /// The disk as a kill would find it now. Lets pending fire-and-forget
  /// writes land first and drains the WAL sink to the file.
  Future<RecordingDiskImage> capture() async {
    await settle();
    await ActiveTripSampleWal.instance.readAll(); // flushes the sink
    final wal = walFile;
    return RecordingDiskImage(
      active: Map.of(activeBox.toMap()),
      paused: Map.of(pausedBox.toMap()),
      history: Map.of(historyBox.toMap()),
      walBytes: wal.existsSync() ? wal.readAsBytesSync() : null,
    );
  }

  /// Put [image] back on disk, replacing whatever the old process wrote
  /// after the capture.
  Future<void> restore(RecordingDiskImage image) async {
    await ActiveTripSampleWal.instance.close();
    for (final (box, rows) in [
      (activeBox, image.active),
      (pausedBox, image.paused),
      (historyBox, image.history),
    ]) {
      await box.clear();
      await box.putAll(rows);
    }
    final wal = walFile;
    final bytes = image.walBytes;
    if (bytes == null) {
      if (wal.existsSync()) wal.deleteSync();
    } else {
      wal.writeAsBytesSync(bytes, flush: true);
    }
  }

  /// A new process starting on [image]: a fresh container, a new process
  /// identity (unless [sameProcess]), and the production recovery passes —
  /// the paused-trip sweep, then the active-trip restore.
  Future<ProviderContainer> relaunch(
    RecordingDiskImage image, {
    DateTime Function()? now,
    List<Override> overrides = const [],
    bool sameProcess = false,
  }) async {
    await restore(image);
    if (!sameProcess) ProcessDeathContext.resetForTest();
    final container = ProviderContainer(overrides: overrides);
    await TripRecoveryPhase.recoverPausedTripsFromOpenBoxes(container,
        now: now);
    await TripRecoveryPhase.restoreActiveTripFromOpenBoxes(container,
        now: now);
    await settle();
    return container;
  }

  /// Let fire-and-forget writes (Hive puts, WAL appends) land.
  static Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 60));

  Future<void> close() async {
    await ActiveTripSampleWal.instance.clear();
    await Hive.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProvider, null);
    if (_dir.existsSync()) _dir.deleteSync(recursive: true);
  }
}
