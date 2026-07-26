// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3614 — unit tests for the shared trailing-edge Debouncer.
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/debouncer.dart';

void main() {
  group('Debouncer', () {
    test('runs the action once after the quiet window', () {
      fakeAsync((async) {
        final d = Debouncer(duration: const Duration(milliseconds: 500));
        var fired = 0;
        d(() => fired++);

        async.elapse(const Duration(milliseconds: 499));
        expect(fired, 0);
        expect(d.isPending, isTrue);

        async.elapse(const Duration(milliseconds: 1));
        expect(fired, 1);
        expect(d.isPending, isFalse);
      });
    });

    test('a burst of calls fires only the LAST action', () {
      fakeAsync((async) {
        final d = Debouncer(duration: const Duration(milliseconds: 250));
        final fired = <String>[];
        d(() => fired.add('a'));
        async.elapse(const Duration(milliseconds: 100));
        d(() => fired.add('b'));
        async.elapse(const Duration(milliseconds: 100));
        d(() => fired.add('c'));

        async.elapse(const Duration(milliseconds: 250));
        expect(fired, ['c']);

        // Nothing else ever fires.
        async.elapse(const Duration(seconds: 5));
        expect(fired, ['c']);
      });
    });

    test('cancel drops the pending action', () {
      fakeAsync((async) {
        final d = Debouncer(duration: const Duration(milliseconds: 300));
        var fired = 0;
        d(() => fired++);
        d.cancel();
        expect(d.isPending, isFalse);
        async.elapse(const Duration(seconds: 1));
        expect(fired, 0);
      });
    });

    test('dispose behaves like cancel and is idempotent', () {
      fakeAsync((async) {
        final d = Debouncer(duration: const Duration(milliseconds: 300));
        var fired = 0;
        d(() => fired++);
        d.dispose();
        d.dispose();
        async.elapse(const Duration(seconds: 1));
        expect(fired, 0);
      });
    });

    test('cancel/dispose with nothing pending is a no-op', () {
      final d = Debouncer(duration: const Duration(milliseconds: 100));
      expect(d.cancel, returnsNormally);
      expect(d.dispose, returnsNormally);
      expect(d.isPending, isFalse);
    });

    test('is reusable after firing', () {
      fakeAsync((async) {
        final d = Debouncer(duration: const Duration(milliseconds: 100));
        var fired = 0;
        d(() => fired++);
        async.elapse(const Duration(milliseconds: 100));
        d(() => fired++);
        async.elapse(const Duration(milliseconds: 100));
        expect(fired, 2);
      });
    });
  });
}
