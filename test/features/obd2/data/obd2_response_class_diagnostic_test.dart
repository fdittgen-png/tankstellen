// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/protocol/obd2_response_class.dart';

/// #4550 — positive diagnostic-mode replies must never read as garbage
/// (two garbage replies in a row warm-start the adapter mid-trip).
void main() {
  test('zero-code, pending, permanent and multi-frame replies are positive',
      () {
    expect(isDiagnosticModePositiveReply('03', '43 00>'), isTrue);
    expect(isDiagnosticModePositiveReply('07', '47 01 03 01\r>'), isTrue);
    expect(isDiagnosticModePositiveReply('0A', '4A 00>'), isTrue);
    expect(
        isDiagnosticModePositiveReply(
            '0902', '014\r0: 49 02 01 56 46 33\r1: 31 32 33 34 35 36 37\r>'),
        isTrue);
    expect(isDiagnosticModePositiveReply('020200', '42 02 00 03 01>'), isTrue);
  });

  test('errors, wrong echoes and Mode 01 commands are not', () {
    expect(isDiagnosticModePositiveReply('03', 'NO DATA>'), isFalse);
    expect(isDiagnosticModePositiveReply('03', '?>'), isFalse);
    expect(isDiagnosticModePositiveReply('03', '47 00>'), isFalse);
    expect(isDiagnosticModePositiveReply('03', 'SEARCHING...\r43 00>'), isFalse);
    expect(isDiagnosticModePositiveReply('010C', '41 0C 1A F8>'), isFalse);
    expect(isDiagnosticModePositiveReply('ATRV', '12.4V>'), isFalse);
  });

  test('the classic classifier still calls a bare `43 00` garbage — the '
      'session consults the diagnostic check first', () {
    expect(classifyObd2Response('43 00>'), ResponseClass.garbage);
  });
}
