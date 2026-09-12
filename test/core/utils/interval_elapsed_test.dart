// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/interval_elapsed.dart';

/// #4073 — one direction for "has the interval passed". The recording
/// controller carried three shapes; one was written inverted.
void main() {
  final now = DateTime(2026, 3, 11, 14, 30);
  const interval = Duration(seconds: 10);

  test('nothing has happened yet → elapsed', () {
    expect(intervalElapsed(null, now, interval), isTrue);
  });
  test('exactly the interval → elapsed (inclusive)', () {
    expect(intervalElapsed(now.subtract(interval), now, interval), isTrue);
  });
  test('inside the interval → not elapsed', () {
    expect(intervalElapsed(now.subtract(const Duration(seconds: 9)), now, interval),
        isFalse);
  });
}
