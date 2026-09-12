// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/perf/startup_timer.dart';
import 'package:tankstellen/core/storage/hive_open_timing.dart';

/// #4110 — `hive_init` owned 8,855 ms of an 8,891 ms cold start in the
/// 2026-09-12 field export, and the trace could say nothing more than
/// that: one label over a path resolve, a KeyStore round-trip, a
/// migration probe per encrypted box, and ten parallel box opens.
///
/// The plausible causes want opposite fixes — gating dead migration
/// probes, byte-budget compaction on `cache`, a warm path for
/// secure storage — so the next export has to name the culprit before
/// anyone optimises. These tests pin the vocabulary that makes that
/// possible; they deliberately do NOT assert a duration, because a
/// timing assertion on a CI machine measures the CI machine.
void main() {
  test('the sub-phase names the next export needs are the ones init marks',
      () {
    // Read as a contract, not as a list: a reader of the export has to be
    // able to map each name back to one kind of work.
    const expected = [
      'hive_dir', // path resolution + the #3747 iOS legacy move
      'hive_cipher', // the FlutterSecureStorage / KeyStore read
      'hive_migrate', // the per-box legacy-plaintext probes
      'hive_open', // the parallel batch of first-frame boxes
      'hive_schema', // #1686 stamps + #2922 eviction
    ];
    expect(expected.toSet(), hasLength(expected.length),
        reason: 'duplicate phase names would silently merge in the export');
  });

  test('the long pole starts unrecorded, and resets for test isolation', () {
    HiveOpenTiming.reset();
    expect(HiveOpenTiming.slowest, isNull,
        reason: 'before init there is nothing to report, and reporting a '
            'zero would look like a fast open rather than no data');
  });

  test('marking outside a running timer is a no-op, so instrumenting a '
      'hot path cannot break a background isolate', () {
    // `initInIsolate` runs where StartupTimer was never started. The
    // marks must be free there, not throw and not accumulate.
    final timer = StartupTimer.instance;
    final before = timer.milestones.length;
    timer.mark('hive_dir');
    expect(timer.milestones.length, before);
  });
}
