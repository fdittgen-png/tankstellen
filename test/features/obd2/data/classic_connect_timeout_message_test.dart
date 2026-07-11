// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/classic_connect_timeout_message.dart';

/// #3558 — the whole-ladder timeout wording must tell a genuine platform
/// wedge (the timer fired on schedule with no native answer) apart from a
/// background-frozen isolate (the timer fired MINUTES late because Android
/// suspended the process — field traces showed 10–25 min "wedges" that
/// were nothing of the kind).
void main() {
  const deadline = Duration(seconds: 23);

  test('an on-schedule fire keeps the #3421 wedge wording', () {
    final msg = classicConnectTimeoutMessage(
      budgetMs: 20000,
      deadline: deadline,
      actualElapsed: const Duration(seconds: 23, milliseconds: 400),
    );
    expect(msg, contains('platform thread wedged (#3421)'));
    expect(msg, isNot(contains('suspended')));
  });

  test('a fire minutes late is phrased as app-suspended, not a wedge', () {
    final msg = classicConnectTimeoutMessage(
      budgetMs: 20000,
      deadline: deadline,
      actualElapsed: const Duration(minutes: 24, seconds: 59),
    );
    expect(msg, contains('suspended in background'));
    expect(msg, contains('(#3558)'));
    expect(msg, isNot(contains('wedged')));
  });

  test('small jitter under the 5 s threshold stays a wedge verdict', () {
    final msg = classicConnectTimeoutMessage(
      budgetMs: 20000,
      deadline: deadline,
      actualElapsed: const Duration(seconds: 27),
    );
    expect(msg, contains('#3421'));
  });
}
