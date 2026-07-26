// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3614 — unit tests for the shared clock/duration format helpers.
// The expectations pin the exact output of the byte-identical local
// copies these replaced (trip recording stopwatch, date pads).
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/time_formatter.dart';

void main() {
  group('twoDigits', () {
    test('pads single digits with a leading zero', () {
      expect(twoDigits(0), '00');
      expect(twoDigits(7), '07');
    });

    test('leaves two-digit values untouched', () {
      expect(twoDigits(10), '10');
      expect(twoDigits(59), '59');
    });
  });

  group('formatMinutesSeconds', () {
    test('zero duration', () {
      expect(formatMinutesSeconds(Duration.zero), '0:00');
    });

    test('seconds are always two digits', () {
      expect(formatMinutesSeconds(const Duration(seconds: 5)), '0:05');
      expect(
        formatMinutesSeconds(const Duration(minutes: 9, seconds: 7)),
        '9:07',
      );
    });

    test('minutes are unbounded (no hour rollover)', () {
      expect(
        formatMinutesSeconds(const Duration(hours: 1, minutes: 15, seconds: 30)),
        '75:30',
      );
    });
  });
}
