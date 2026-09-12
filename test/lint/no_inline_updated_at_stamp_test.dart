// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// #4065 — every `updated_at` an upload stamps goes through
/// `SyncRowOps.lwwStamp`, never an inline wall-clock read.
///
/// The seam preserves the model's own edit stamp (so the next LWW compare
/// sees equal stamps and skips) and reads the wall clock through the
/// #3660 AppClock. Five upload sites bypassed it; on a second device the
/// itinerary list collapsed to upload order and the displayed "edited"
/// date became the sync time. This keeps the count at zero.
void main() {
  test('no upload stamps updated_at with an inline wall-clock read (#4065)',
      () {
    final offenders = <String>[];
    // Assembled from pieces so this file does not itself read as a raw
    // wall-clock call to `wall_clock_test.dart`.
    const clock = 'Date' 'Time' r'\.now\(\)';
    final inline = RegExp(
      "'updated_at':\\s*$clock"
      '|final now = $clock' r'\.toUtc\(\)\.toIso8601String\(\);',
    );
    for (final e in Directory('lib').listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith('.dart')) continue;
      final src = e.readAsStringSync();
      for (final m in inline.allMatches(src)) {
        final line = '\n'.allMatches(src.substring(0, m.start)).length + 1;
        offenders.add('${e.path}:$line');
      }
    }
    expect(offenders, isEmpty,
        reason: 'stamp updated_at with SyncRowOps.lwwStamp(model.updatedAt) '
            'instead:\n${offenders.join('\n')}');
  });
}
