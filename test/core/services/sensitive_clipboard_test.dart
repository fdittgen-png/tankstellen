// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/sensitive_clipboard.dart';

void main() {
  // Every write the fake platform clipboard received, in order.
  final writes = <String?>[];
  // What a read-back returns; a `_ThrowingRead` sentinel makes it throw.
  ClipboardData? readBack;
  var readThrows = false;
  var writeThrows = false;

  setUp(() {
    writes.clear();
    readBack = null;
    readThrows = false;
    writeThrows = false;
    SensitiveClipboard.writer = (data) async {
      if (writeThrows) throw PlatformException(code: 'copy-fail');
      writes.add(data.text);
    };
    SensitiveClipboard.reader = () async {
      if (readThrows) throw PlatformException(code: 'read-fail');
      return readBack;
    };
  });

  tearDown(SensitiveClipboard.resetForTesting);

  group('SensitiveClipboard (#3611)', () {
    test('copy writes the payload and schedules the 60 s clear', () {
      fakeAsync((fake) {
        unawaited(SensitiveClipboard.copy('DE89370400440532013000'));
        fake.flushMicrotasks();

        expect(writes, ['DE89370400440532013000']);
        expect(SensitiveClipboard.hasPendingClear, isTrue);

        // One second before the deadline nothing has been cleared.
        fake.elapse(SensitiveClipboard.clearDelay -
            const Duration(seconds: 1));
        expect(writes, hasLength(1));

        // Clipboard still holds our payload at the deadline → cleared.
        readBack = const ClipboardData(text: 'DE89370400440532013000');
        fake.elapse(const Duration(seconds: 1));
        fake.flushMicrotasks();
        expect(writes, ['DE89370400440532013000', '']);
        expect(SensitiveClipboard.hasPendingClear, isFalse);
      });
    });

    test('does NOT clear when the user has since copied something else', () {
      fakeAsync((fake) {
        unawaited(SensitiveClipboard.copy('IBAN: DE89'));
        fake.flushMicrotasks();

        readBack = const ClipboardData(text: 'a grocery list');
        fake.elapse(SensitiveClipboard.clearDelay);
        fake.flushMicrotasks();

        expect(writes, ['IBAN: DE89'],
            reason: 'someone else\'s clipboard content must be left alone');
      });
    });

    test('clears unconditionally when the read-back returns null', () {
      fakeAsync((fake) {
        unawaited(SensitiveClipboard.copy('secret'));
        fake.flushMicrotasks();

        readBack = null; // platform gave us nothing to compare against
        fake.elapse(SensitiveClipboard.clearDelay);
        fake.flushMicrotasks();

        expect(writes, ['secret', '']);
      });
    });

    test('clears unconditionally when the read-back throws (Android 10+ '
        'background restriction)', () {
      fakeAsync((fake) {
        unawaited(SensitiveClipboard.copy('secret'));
        fake.flushMicrotasks();

        readThrows = true;
        fake.elapse(SensitiveClipboard.clearDelay);
        fake.flushMicrotasks();

        expect(writes, ['secret', '']);
      });
    });

    test('a newer copy cancels the older pending clear — only one clear '
        'fires', () {
      fakeAsync((fake) {
        unawaited(SensitiveClipboard.copy('first'));
        fake.flushMicrotasks();
        fake.elapse(const Duration(seconds: 30));

        unawaited(SensitiveClipboard.copy('second'));
        fake.flushMicrotasks();

        // 31 s after the FIRST copy: its timer must NOT fire.
        readBack = const ClipboardData(text: 'second');
        fake.elapse(const Duration(seconds: 31));
        fake.flushMicrotasks();
        expect(writes, ['first', 'second']);

        // 60 s after the second copy → exactly one clear.
        fake.elapse(const Duration(seconds: 29));
        fake.flushMicrotasks();
        expect(writes, ['first', 'second', '']);
      });
    });

    test('fault injection — a clear-time writer failure is swallowed '
        '(never-throws contract)', () {
      fakeAsync((fake) {
        unawaited(SensitiveClipboard.copy('secret'));
        fake.flushMicrotasks();

        // The deferred clear's own write blows up: the timer callback
        // must swallow it (nobody is awaiting it).
        writeThrows = true;
        readBack = const ClipboardData(text: 'secret');
        expect(
          () {
            fake.elapse(SensitiveClipboard.clearDelay);
            fake.flushMicrotasks();
          },
          returnsNormally,
        );
      });
    });

    test('the copy itself surfaces write failures to the caller (call '
        'sites keep their existing error handling)', () async {
      writeThrows = true;
      await expectLater(
        SensitiveClipboard.copy('secret'),
        throwsA(isA<PlatformException>()),
      );
      expect(SensitiveClipboard.hasPendingClear, isFalse,
          reason: 'no clear should be scheduled for a failed write');
    });
  });
}
