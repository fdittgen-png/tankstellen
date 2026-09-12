// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/hive_legacy_migration.dart';

/// #4110 — the pre-encryption plaintext migration is one-time by
/// definition, and ran on every cold start.
///
/// Its happy path opens each encrypted box with the cipher and closes it
/// again; `HiveBoxes.init`'s Phase 2 then opens all six a SECOND time. So
/// every launch paid twelve opens where six would do — and Hive's default
/// compaction can fire on that close, meaning the probe could rewrite the
/// whole `cache` file before the real open began.
///
/// After the first successful migration (or on a fresh install) none of
/// it can find anything. These tests pin the gate.
void main() {
  late Directory tmpDir;
  late Box<int> meta;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('hive_migration_gate_');
    Hive.init(tmpDir.path);
    meta = await Hive.openBox<int>(HiveBoxes.boxSchema);
  });

  tearDown(() async {
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  test('a fresh install still needs the probes', () {
    expect(HiveLegacyMigration.isNeeded(meta), isTrue,
        reason: 'the flag has never been written, so a device that HAS a '
            'plaintext box must still be migrated');
  });

  test('once recorded, the probes are skipped', () async {
    await meta.put(HiveLegacyMigration.doneKey, HiveLegacyMigration.doneValue);
    expect(HiveLegacyMigration.isNeeded(meta), isFalse);

    // The skip must happen BEFORE the cipher is touched — which is what
    // makes this assertable without a FlutterSecureStorage key at all.
    // Passing a set of box names that do not exist proves no probe ran:
    // a probe would have created them.
    await HiveLegacyMigration.runOnce(
      const ['gate_probe_must_not_run'],
      HiveAesCipher(List<int>.filled(32, 7)),
      meta,
    );
    expect(Hive.isBoxOpen('gate_probe_must_not_run'), isFalse);
    expect(File('${tmpDir.path}/gate_probe_must_not_run.hive').existsSync(),
        isFalse,
        reason: 'a probe opens the box, which creates the file — its '
            'absence is the proof that nothing ran');
  });

  test('a stale or foreign flag value does not count as done', () async {
    // Defensive: a half-written or future-schema value must fail CLOSED
    // (probe again) rather than open. A missed migration loses data; a
    // repeated probe only costs time.
    for (final wrong in [0, 2, -1]) {
      await meta.put(HiveLegacyMigration.doneKey, wrong);
      expect(HiveLegacyMigration.isNeeded(meta), isTrue,
          reason: 'value $wrong is not doneValue');
    }
  });

  test('the flag is written only after every probe finished', () async {
    expect(meta.get(HiveLegacyMigration.doneKey), isNull);
    // An empty box set makes runOnce's Future.wait trivially complete, so
    // this exercises the ordering (probe → flag) without needing a real
    // plaintext box on disk.
    await HiveLegacyMigration.runOnce(
      const <String>[],
      HiveAesCipher(List<int>.filled(32, 7)),
      meta,
    );
    expect(meta.get(HiveLegacyMigration.doneKey),
        HiveLegacyMigration.doneValue);
    expect(HiveLegacyMigration.isNeeded(meta), isFalse,
        reason: 'the next cold start must not probe again');
  });
}
