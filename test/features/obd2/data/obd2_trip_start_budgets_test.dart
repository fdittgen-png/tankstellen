// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_trip_start_budgets.dart';

/// #3382 — [boundedStartRead] is the primitive that keeps a slow/silent
/// adapter from hanging the trajet trip-start: the best-effort odometer / VIN
/// reads are wrapped in it so a stall DEGRADES TO NULL (a normal degraded
/// start) instead of leaving the recording stuck in "initializing" forever.
void main() {
  group('boundedStartRead (#3382)', () {
    test('a stalled read degrades to null at the budget — never hangs', () async {
      final neverLands = Completer<int?>(); // the "silent adapter" read
      final result = await boundedStartRead<int>(
        neverLands.future,
        const Duration(milliseconds: 20),
      ).timeout(
        const Duration(seconds: 2),
        onTimeout: () => fail('boundedStartRead hung — the budget did not fire'),
      );

      expect(result, isNull,
          reason: 'a timed-out start read degrades to null so the trip still '
              'starts in a degraded state');
      neverLands.complete(null); // release the dangling read
    });

    test('a read that lands within the budget returns its value untouched',
        () async {
      expect(
        await boundedStartRead<int>(Future.value(42), const Duration(seconds: 1)),
        42,
      );
    });

    test('a null in-time result is passed through (genuine "unknown")',
        () async {
      expect(
        await boundedStartRead<String>(
            Future.value(null), const Duration(seconds: 1)),
        isNull,
      );
    });
  });
}
