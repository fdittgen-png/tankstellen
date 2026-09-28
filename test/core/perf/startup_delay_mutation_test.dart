// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/perf/perf_budgets.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/hive_first_frame_boxes.dart';
import 'package:tankstellen/core/storage/hive_open_timing.dart';

import '../../helpers/hive_temp_dir.dart';

/// Epic #4316 — a controlled startup-delay MUTATION harness.
///
/// `startup_regression_gate_test.dart` proves the first-frame box set and
/// the pre-`runApp` await list cannot drift silently — it is a snapshot
/// gate. What it does not prove on its own is that the numbers those
/// snapshots feed (`kHiveOpenBudget`, `kColdStartBudget` in
/// `perf_budgets.dart`) would actually FLAG a real slowdown if one
/// landed. This file answers that narrower question: it deliberately
/// injects a synthetic delay into the real, executed
/// `HiveFirstFrameBoxes.openAll` critical path — the same box-open code
/// the #4140 gate exercises — and shows the budget check that reads it
/// flips from passing to failing.
///
/// **What this proves, and what it does not.** It proves the
/// measurement pipeline (`HiveOpenTiming` timing a real box open,
/// `kHiveOpenBudget` judging the result) has real detection power for a
/// regression of the #4110 shape (one box getting slower). It is a CI
/// runner timing a temp-directory Hive open, not a phone — it cannot
/// stand in for the on-device before/after run the epic's "Measured
/// validation checkpoint" section still asks for (see
/// `docs/guides/startup-kpi-measurement.md`). It is also kept in its own
/// file, separate from `startup_regression_gate_test.dart`'s
/// deterministic-ordering/box-set assertions, per that section's own
/// instruction not to blend the two.
///
/// The fault injection below is intentionally visible and confined to
/// this test file — it never touches `lib/`.
void main() {
  late Directory tmpDir;

  setUp(() {
    tmpDir = Directory.systemTemp.createTempSync('startup_delay_mutation_');
    Hive.init(tmpDir.path);
    HiveOpenTiming.reset();
  });

  tearDown(() async {
    await closeHiveAndDeleteTemp(tmpDir);
  });

  group('controlled startup-delay mutation harness', () {
    test(
        'sanity: the real, unmutated first-frame open is comfortably '
        'within the Hive-open budget', () async {
      final stopwatch = Stopwatch()..start();
      await HiveFirstFrameBoxes.openAll(null);
      stopwatch.stop();

      final baselineMs = stopwatch.elapsedMilliseconds;
      expect(_withinHiveOpenBudget(baselineMs), isTrue,
          reason: 'unmutated, this must hold — it is the exact check the '
              'next test flips by injecting a fault, and a test that '
              'starts red proves nothing about detection');
    });

    test(
        'a synthetic delay wrapped around ONE first-frame box open trips '
        'the same budget check', () async {
      // TEST-ONLY FAULT INJECTION. `kHiveOpenBudget`'s own doc comment
      // names `cache` as the historical suspect (#4110 found the real
      // instance of this shape); this does not claim `cache` is slow
      // today, only that if a box like it ever got slow again, this
      // pipeline would notice.
      final injectedDelay =
          Duration(milliseconds: kHiveOpenBudget.limit!.toInt() + 250);

      final stopwatch = Stopwatch()..start();
      await _openAllWithInjectedDelay(
        null,
        targetBox: HiveBoxes.cache,
        extraDelay: injectedDelay,
      );
      stopwatch.stop();

      final mutatedMs = stopwatch.elapsedMilliseconds;
      expect(_withinHiveOpenBudget(mutatedMs), isFalse,
          reason: 'the SAME budget check that passed for the unmutated '
              'open above must fail once one box is made slower than '
              '${kHiveOpenBudget.limit} ${kHiveOpenBudget.unit} allows — '
              'this is the pipeline actually detecting a regression of '
              'the #4110 shape, not a restatement of the budget number');

      expect(HiveOpenTiming.slowest?.$1, HiveBoxes.cache,
          reason: 'the long-pole instrumentation (#4110) must name the '
              'box the delay was injected into, so a field export would '
              'point a reader at the right box, not just "startup is '
              'slow"');
      expect(HiveOpenTiming.slowest!.$2,
          greaterThanOrEqualTo(injectedDelay.inMilliseconds));

      // The mutation is purely a TIMING fault — the box-set gate in
      // startup_regression_gate_test.dart is a separate, unaffected
      // concern, and this confirms the two do not collapse into one.
      expect(HiveOpenTiming.openedBoxes.toSet(), HiveFirstFrameBoxes.names,
          reason: 'the injected delay must not change WHICH boxes '
              'opened, only how long one of them took');
    });
  });
}

/// Mirrors the check [kHiveOpenBudget] exists to support. There is no
/// production function of exactly this shape today because
/// `kHiveOpenBudget`, like every timing budget in `perf_budgets.dart`, is
/// reported in the field export rather than asserted in CI (a CI runner
/// is not a phone) — the KPI side has the equivalent for
/// `kColdStartBudget` in `StartupKpi.withinBudget`. This is that same
/// shape of check, written down so the fault injection above has
/// something concrete to flip from green to red.
bool _withinHiveOpenBudget(int elapsedMs) =>
    elapsedMs <= kHiveOpenBudget.limit!;

/// The production `HiveFirstFrameBoxes.openAll` batch, reproduced here
/// ONLY to add a single injected delay around [targetBox]'s open. Every
/// other line is the real production shape: the same
/// `HiveFirstFrameBoxes.contract` entries, opened through the same
/// `HiveOpenTiming.timed` wrapper `openAll` itself uses, so the timing
/// this produces is measuring the real machinery plus one deliberate
/// fault — not a stand-in computation.
Future<void> _openAllWithInjectedDelay(
  HiveAesCipher? cipher, {
  required String targetBox,
  required Duration extraDelay,
}) async {
  await Future.wait<Box<dynamic>>([
    for (final box in HiveFirstFrameBoxes.contract)
      HiveOpenTiming.timed(box.name, () async {
        if (box.name == targetBox) {
          // The fault: pretend this box took longer to open than it did.
          await Future<void>.delayed(extraDelay);
        }
        return box.open(cipher);
      }),
  ]);
}
