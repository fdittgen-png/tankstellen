// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm_byte_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_comm_diagnostics.dart';

/// Encode an ASCII reply to the raw byte chunk an ELM327 channel would
/// surface to [noteObd2Framing].
List<int> _bytes(String s) => s.codeUnits;

void main() {
  // The framing tee writes into the process-wide singleton (mirrors the
  // other comm-diagnostics tees). Reset around every test so counters
  // never leak between cases.
  setUp(Obd2CommDiagnostics.instance.reset);
  tearDown(() {
    Obd2CommDiagnostics.instance.enabled = false;
    Obd2CommDiagnostics.instance.reset();
  });

  group('noteObd2Framing → Obd2CommDiagnostics (#2467)', () {
    test('debugMode ON: a clean terminated reply records NO framing anomaly',
        () {
      Obd2CommDiagnostics.instance
        ..enabled = true
        ..beginSession();

      // A well-framed positive-response line with its trailing prompt.
      noteObd2Framing(_bytes('41 0D 3C\r>'));

      final f = Obd2CommDiagnostics.instance.snapshot().framing;
      expect(f.partialFrames, 0);
      expect(f.leftoverBytes, 0);
      expect(f.strayPrompts, 0);
      expect(f.garbageReads, 0);
    });

    test('a frame with no terminating prompt → partial frame', () {
      Obd2CommDiagnostics.instance
        ..enabled = true
        ..beginSession();

      // Mid-frame chunk: data but no `>` yet.
      noteObd2Framing(_bytes('41 0D 3'));

      expect(
        Obd2CommDiagnostics.instance.snapshot().framing.partialFrames,
        1,
      );
    });

    test('payload bytes after the prompt → leftover buffer', () {
      Obd2CommDiagnostics.instance
        ..enabled = true
        ..beginSession();

      // The previous reply leaked into this read: a terminated frame
      // followed by the start of the next one.
      noteObd2Framing(_bytes('41 0D 3C\r>41 0C'));

      expect(
        Obd2CommDiagnostics.instance.snapshot().framing.leftoverBytes,
        1,
      );
    });

    test('a chunk that is only a > prompt → stray prompt', () {
      Obd2CommDiagnostics.instance
        ..enabled = true
        ..beginSession();

      noteObd2Framing(_bytes('>'));
      noteObd2Framing(_bytes('\r>\r'));

      expect(
        Obd2CommDiagnostics.instance.snapshot().framing.strayPrompts,
        2,
      );
    });

    test('BUFFER FULL routes through the classifier → garbage read', () {
      Obd2CommDiagnostics.instance
        ..enabled = true
        ..beginSession();

      noteObd2Framing(_bytes('BUFFER FULL\r>'));

      expect(
        Obd2CommDiagnostics.instance.snapshot().framing.garbageReads,
        1,
      );
    });

    test(
        'the rest of the ELM error vocabulary (CAN ERROR / UNABLE TO '
        'CONNECT / STOPPED) all bin as garbage', () {
      Obd2CommDiagnostics.instance
        ..enabled = true
        ..beginSession();

      noteObd2Framing(_bytes('CAN ERROR\r>'));
      noteObd2Framing(_bytes('UNABLE TO CONNECT\r>'));
      noteObd2Framing(_bytes('STOPPED\r>'));

      expect(
        Obd2CommDiagnostics.instance.snapshot().framing.garbageReads,
        3,
      );
    });

    test('a non-ASCII (binary) byte → garbage read', () {
      Obd2CommDiagnostics.instance
        ..enabled = true
        ..beginSession();

      // 0xFF is outside printable ASCII — a noisy wire / binary leak.
      noteObd2Framing(<int>[0x41, 0xFF, 0x0D]);

      expect(
        Obd2CommDiagnostics.instance.snapshot().framing.garbageReads,
        1,
      );
    });

    test('CR / LF terminators are structure, not garbage', () {
      Obd2CommDiagnostics.instance
        ..enabled = true
        ..beginSession();

      // A partial frame carrying CR + LF must NOT be counted as garbage.
      noteObd2Framing(<int>[0x34, 0x31, 0x0D, 0x0A]); // "41\r\n"

      final f = Obd2CommDiagnostics.instance.snapshot().framing;
      expect(f.garbageReads, 0);
      expect(f.partialFrames, 1);
    });

    test('debugMode OFF: a partial frame + BUFFER FULL + garbage are no-ops',
        () {
      // Gate stays off (default). Even with a session begun nothing is
      // recorded — `beginSession` itself is a no-op when disabled, so the
      // snapshot is the empty sentinel.
      expect(Obd2CommDiagnostics.instance.enabled, isFalse);
      Obd2CommDiagnostics.instance.beginSession();

      noteObd2Framing(_bytes('41 0D 3')); // partial
      noteObd2Framing(_bytes('BUFFER FULL\r>')); // garbage
      noteObd2Framing(<int>[0x41, 0xFF]); // non-ASCII garbage

      final f = Obd2CommDiagnostics.instance.snapshot().framing;
      expect(f.partialFrames, 0);
      expect(f.leftoverBytes, 0);
      expect(f.strayPrompts, 0);
      expect(f.garbageReads, 0);
    });
  });
}
