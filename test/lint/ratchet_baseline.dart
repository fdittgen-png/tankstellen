// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';

/// The one shape for a per-file ratchet (#4074): EXACT in both directions.
///
/// Five lints carried their own harness and had already drifted — three
/// were growth-only scalars, which cannot lock in an improvement (the
/// very thing #4033 fixed for file length): a scalar that only shrinks
/// silently lets one file grow while another shrinks. Per file, exact:
/// a regression names the file, and an improvement demands the baseline
/// be lowered in the same commit so it can never regress unseen.
void expectRatchet({
  required Map<String, int> measured,
  required Map<String, int> baseline,
  required String what,
  required String hint,
}) {
  final grew = <String>[];
  final shrank = <String>[];
  for (final e in measured.entries) {
    final b = baseline[e.key] ?? 0;
    if (e.value > b) grew.add('${e.key}: ${e.value} > baseline $b');
    if (e.value < b) shrank.add('${e.key}: now ${e.value}, baseline $b');
  }
  for (final e in baseline.entries) {
    if (!measured.containsKey(e.key) && e.value > 0) {
      shrank.add('${e.key}: now 0, baseline ${e.value}');
    }
  }
  expect(grew, isEmpty,
      reason: '$what increased.\n$hint\n${grew.join('\n')}');
  expect(shrank, isEmpty,
      reason: '$what dropped below its baseline — excellent. Lock it in by '
          'lowering (or deleting) the entry so it can never regress:\n'
          '${shrank.join('\n')}');
}
