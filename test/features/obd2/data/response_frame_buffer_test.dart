// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/response_frame_buffer.dart';

/// #3276 — the prompt-framing accumulator + hard size cap.
void main() {
  group('ResponseFrameBuffer', () {
    List<int> b(String s) => s.codeUnits;

    test('accumulates chunks until the prompt, then yields the body', () {
      final f = ResponseFrameBuffer();
      expect(f.add(b('41 0C ')), FrameOutcome.needMore);
      expect(f.add(b('1A F8')), FrameOutcome.needMore);
      expect(f.add(b('>')), FrameOutcome.complete);
      expect(f.body, '41 0C 1A F8');
    });

    test('keeps bytes after the prompt for the next frame', () {
      final f = ResponseFrameBuffer();
      expect(f.add(b('OK>41 0C')), FrameOutcome.complete);
      expect(f.body, 'OK');
      expect(f.add(b(' 00>')), FrameOutcome.complete);
      expect(f.body, '41 0C 00');
    });

    test('overflows (drops accumulation) when no prompt arrives past the cap',
        () {
      final f = ResponseFrameBuffer(maxChars: 64);
      expect(f.add(b('A' * 65)), FrameOutcome.overflow);
      // The buffer was cleared on overflow, so a fresh prompted frame works.
      expect(f.add(b('OK>')), FrameOutcome.complete);
      expect(f.body, 'OK');
    });

    test('clear() discards a partial accumulation', () {
      final f = ResponseFrameBuffer();
      f.add(b('partial'));
      f.clear();
      expect(f.add(b('OK>')), FrameOutcome.complete);
      expect(f.body, 'OK');
    });
  });
}
