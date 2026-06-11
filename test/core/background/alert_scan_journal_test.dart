// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/background/alert_scan_journal.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';

/// #3147 — rolling journal of background alert-scan runs, persisted in
/// the alerts box alongside the dedup rows so "why didn't I get an
/// alert?" is answerable from the error-log export.
void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_scan_journal_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    if (!Hive.isBoxOpen(HiveBoxes.alerts)) {
      await Hive.openBox(HiveBoxes.alerts);
    }
    await Hive.box(HiveBoxes.alerts).clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  final t0 = DateTime.utc(2026, 6, 10, 8);

  group('append + entries', () {
    test('a completed scan row round-trips with its counts', () async {
      final journal = AlertScanJournal();
      await journal.append(
        at: t0,
        trigger: 'workmanager_periodic',
        stationsScanned: 12,
        alertsFired: 2,
      );

      final rows = journal.entries();
      expect(rows, hasLength(1));
      expect(rows.single['at'], t0.toIso8601String());
      expect(rows.single['trigger'], 'workmanager_periodic');
      expect(rows.single['stations'], 12);
      expect(rows.single['alertsFired'], 2);
      expect(rows.single.containsKey('skipped'), isFalse);
      expect(rows.single.containsKey('error'), isFalse);
    });

    test('skipped and failed rows record why a scan did not complete',
        () async {
      final journal = AlertScanJournal();
      await journal.append(
          at: t0, trigger: 'android_widget', skippedReason: 'cooldown');
      await journal.append(
          at: t0.add(const Duration(hours: 1)),
          trigger: 'ios_bg_refresh',
          error: 'TimeoutException');

      final rows = journal.entries();
      expect(rows[0]['skipped'], 'cooldown');
      expect(rows[1]['error'], 'TimeoutException');
    });

    test('rotation keeps only the newest maxEntries rows', () async {
      final journal = AlertScanJournal();
      for (var i = 0; i < AlertScanJournal.maxEntries + 5; i++) {
        await journal.append(
          at: t0.add(Duration(minutes: i)),
          trigger: 'workmanager_periodic',
          stationsScanned: i,
          alertsFired: 0,
        );
      }

      final rows = journal.entries();
      expect(rows, hasLength(AlertScanJournal.maxEntries));
      expect(rows.first['stations'], 5,
          reason: 'the 5 oldest rows must have been rotated out');
      expect(rows.last['stations'], AlertScanJournal.maxEntries + 4);
    });

    test(
        'the #3169 mitigation triggers round-trip so the SLA is '
        'field-verifiable per wake source', () async {
      // bgProcessing / slcWake / opportunistic are the new iOS lanes; the
      // journal must persist their tags verbatim so one export shows which
      // wake source actually delivered scans in the field.
      final journal = AlertScanJournal();
      await journal.append(
          at: t0, trigger: 'bgProcessing', stationsScanned: 4, alertsFired: 1);
      await journal.append(
          at: t0.add(const Duration(minutes: 5)),
          trigger: 'slcWake',
          skippedReason: 'cooldown');
      await journal.append(
          at: t0.add(const Duration(minutes: 30)),
          trigger: 'opportunistic',
          stationsScanned: 4,
          alertsFired: 0);

      final rows = journal.entries();
      expect(rows.map((r) => r['trigger']),
          ['bgProcessing', 'slcWake', 'opportunistic']);
      expect(rows[0]['alertsFired'], 1);
      expect(rows[1]['skipped'], 'cooldown');
    });

    test('exportSection returns the rows newest-first', () async {
      final journal = AlertScanJournal();
      await journal.append(
          at: t0, trigger: 'workmanager_periodic', stationsScanned: 1);
      await journal.append(
          at: t0.add(const Duration(hours: 6)),
          trigger: 'android_widget',
          skippedReason: 'cooldown');

      final section = AlertScanJournal.exportSection();
      expect(section, hasLength(2));
      expect(section.first['trigger'], 'android_widget',
          reason: 'the most recent scan must lead the export payload');
    });
  });

  group('never-throws contract (fault injection)', () {
    test('append/entries degrade to a no-op when the alerts box is closed',
        () async {
      await Hive.box(HiveBoxes.alerts).close();
      final journal = AlertScanJournal();

      await expectLater(
        journal.append(at: t0, trigger: 'workmanager_periodic'),
        completes,
      );
      expect(journal.entries, returnsNormally);
      expect(journal.entries(), isEmpty);
      expect(AlertScanJournal.exportSection, returnsNormally);

      await Hive.openBox(HiveBoxes.alerts); // restore for the next test
    });

    test('a malformed persisted value is ignored, then overwritten',
        () async {
      final box = Hive.box(HiveBoxes.alerts);
      await box.put(AlertScanJournal.journalKey, 'not-a-list');
      final journal = AlertScanJournal();

      expect(journal.entries(), isEmpty);
      await expectLater(
        journal.append(at: t0, trigger: 'workmanager_periodic'),
        completes,
      );
      expect(journal.entries(), hasLength(1));
    });
  });
}
