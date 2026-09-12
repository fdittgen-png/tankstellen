// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';

import 'ratchet_baseline.dart';

/// #4074 — the shared ratchet is exact in BOTH directions: a file may
/// neither grow past its entry nor silently drop below it.
void main() {
  test('equal → passes', () {
    expect(
      () => expectRatchet(
          measured: {'a.dart': 2}, baseline: {'a.dart': 2}, what: 'x', hint: 'h'),
      returnsNormally,
    );
  });

  test('growth fails and names the file', () {
    expect(
      () => expectRatchet(
          measured: {'a.dart': 3}, baseline: {'a.dart': 2}, what: 'x', hint: 'h'),
      throwsA(isA<TestFailure>()
          .having((f) => f.message, 'message', contains('a.dart: 3 > baseline 2'))),
    );
  });

  test('an unbaselined file counts as growth from zero', () {
    expect(
      () => expectRatchet(
          measured: {'new.dart': 1}, baseline: const {}, what: 'x', hint: 'h'),
      throwsA(isA<TestFailure>()),
    );
  });

  test('an improvement fails until the baseline is lowered', () {
    expect(
      () => expectRatchet(
          measured: {'a.dart': 1}, baseline: {'a.dart': 2}, what: 'x', hint: 'h'),
      throwsA(isA<TestFailure>()
          .having((f) => f.message, 'message', contains('Lock it in'))),
    );
  });

  test('a file that vanished from the measurement is an improvement too', () {
    expect(
      () => expectRatchet(
          measured: const {}, baseline: {'a.dart': 2}, what: 'x', hint: 'h'),
      throwsA(isA<TestFailure>()),
    );
  });
}
