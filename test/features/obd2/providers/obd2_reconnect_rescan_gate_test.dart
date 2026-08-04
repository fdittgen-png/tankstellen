// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/providers/obd2_reconnect_provider.dart';

/// #3671 — the reconnect dial skips its re-scan fallback while the app
/// is genuinely backgrounded: with the phone parked away from the car
/// the scan ground for tens of minutes per attempt on the main looper
/// until the OS killed the process for excessive background CPU. The
/// direct by-MAC dials are unaffected — auto-record still recovers the
/// moment the adapter answers.
void main() {
  test('paused / hidden / detached skip the rescan', () {
    expect(shouldSkipRescanWhenBackgrounded(AppLifecycleState.paused), isTrue);
    expect(shouldSkipRescanWhenBackgrounded(AppLifecycleState.hidden), isTrue);
    expect(
        shouldSkipRescanWhenBackgrounded(AppLifecycleState.detached), isTrue);
  });

  test('resumed / inactive / unknown keep the full dial — a transient '
      'overlay or an unreported lifecycle must not degrade the rescue', () {
    expect(
        shouldSkipRescanWhenBackgrounded(AppLifecycleState.resumed), isFalse);
    expect(
        shouldSkipRescanWhenBackgrounded(AppLifecycleState.inactive), isFalse);
    expect(shouldSkipRescanWhenBackgrounded(null), isFalse);
  });
}
