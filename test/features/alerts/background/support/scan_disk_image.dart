// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:hive/hive.dart';
import 'package:tankstellen/core/background/alert_scan_journal.dart';
import 'package:tankstellen/core/background/hive_isolate_lock.dart';
import 'package:tankstellen/core/background/scan_run_phase.dart';
import 'package:tankstellen/core/notifications/notification_service.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/alerts/background/background_alert_scan_coordinator.dart';
import 'package:tankstellen/features/alerts/background/background_scan_body.dart';

import '../../../../helpers/hive_temp_dir.dart';

/// What a process kill leaves of a background scan (#4162): the rows of
/// the boxes the scan writes, at one instant.
class ScanDiskImage {
  const ScanDiskImage(this.boxes);

  /// Box name → its rows.
  final Map<String, Map<dynamic, dynamic>> boxes;

  Map<dynamic, dynamic> operator [](String box) => boxes[box] ?? const {};

  /// The image with [box] gone — what a partial restore brings back.
  ScanDiskImage without(String box) =>
      ScanDiskImage({...boxes}..remove(box));
}

/// A background scan's disk, as production names it (#4162): real Hive
/// boxes under their production names in a temp directory — so every
/// store the scan touches (journal, cooldown, budget, feed) finds them
/// exactly as it does on a phone — plus the Hive lock file.
///
/// A kill test is three moves:
///
/// 1. [capture] at the instant the kill lands (synchronous, so it can run
///    inside a phase-sink callback);
/// 2. let the old run finish — whatever it wrote after the capture never
///    happened as far as the image is concerned;
/// 3. [restore] the image and start a new coordinator on it.
class ScanDisk {
  ScanDisk._(this.dir);

  final Directory dir;

  /// The boxes a scan reads and writes.
  static const List<String> boxNames = [
    HiveBoxes.alerts,
    HiveBoxes.settings,
    HiveBoxes.priceHistory,
  ];

  static Future<ScanDisk> open() async {
    final dir = Directory.systemTemp.createTempSync('scan_disk_');
    Hive.init(dir.path);
    for (final name in boxNames) {
      await Hive.openBox<dynamic>(name);
    }
    return ScanDisk._(dir);
  }

  File get lockFile => File('${dir.path}/hive_bg.lock');

  Box<dynamic> box(String name) => Hive.box<dynamic>(name);

  /// The disk as a kill would find it now.
  ScanDiskImage capture() => ScanDiskImage({
        for (final name in boxNames)
          if (Hive.isBoxOpen(name)) name: Map.of(box(name).toMap()),
      });

  /// Put [image] back, replacing whatever the old process wrote after the
  /// capture. A box absent from the image comes back empty.
  Future<void> restore(ScanDiskImage image) async {
    for (final name in boxNames) {
      if (!Hive.isBoxOpen(name)) await Hive.openBox<dynamic>(name);
      await box(name).clear();
      await box(name).putAll(image[name]);
    }
  }

  /// The journal rows on disk, oldest first.
  List<Map<String, Object?>> get journal => AlertScanJournal().entries();

  /// A coordinator on this disk: the lock is the temp lock file (measured
  /// against [lockClock] when given), the boxes are already open, and the
  /// body and notifier are the test's.
  ///
  /// [lock] replaces the lock file — a relaunch after a SUSPENDED run that
  /// never released uses a fresh one, because a new process does not
  /// inherit the dead one's in-memory claim.
  BackgroundAlertScanCoordinator coordinator({
    required ScanBody Function(HiveStorage storage, DateTime at) body,
    required NotificationService notifier,
    ScanPhaseSink? sink,
    DateTime Function()? lockClock,
    File? lock,
  }) =>
      BackgroundAlertScanCoordinator(
        lockFactory: () async => lockClock == null
            ? HiveIsolateLock.fromFile(lock ?? lockFile)
            : HiveIsolateLock.fromFile(lock ?? lockFile, clock: lockClock),
        openBoxes: () async {},
        closeBoxes: () async {},
        notifierFactory: () async => notifier,
        body: body,
        sink: sink,
      );

  Future<void> close() async {
    await closeHiveAndDeleteTemp(dir);
  }
}
