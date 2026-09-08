// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/sync/providers/link_device_provider.dart';

void main() {
  ProviderContainer makeContainer() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  group('LinkDeviceState', () {
    test('default is idle with no outcome', () {
      const s = LinkDeviceState();
      expect(s.isLinking, isFalse);
      expect(s.hasResult, isFalse);
      expect(s.isError, isFalse);
    });

    // #3988 — the outcome IS the state. It used to be inferred from the
    // user-visible sentence (`result.startsWith('Link failed')`), which made
    // the wording load-bearing and untranslatable.
    test('every non-linked outcome is an error', () {
      for (final o in LinkDeviceOutcome.values) {
        final s = LinkDeviceState(outcome: o);
        expect(s.isError, o != LinkDeviceOutcome.linked, reason: '$o');
        expect(s.hasResult, isTrue);
      }
    });

    test('a failure carries the reason as detail, not as the message', () {
      const s = LinkDeviceState(
          outcome: LinkDeviceOutcome.failed, errorDetail: 'boom');
      expect(s.isError, isTrue);
      expect(s.errorDetail, 'boom');
    });

    test('a link carries what it imported', () {
      const s = LinkDeviceState(
        outcome: LinkDeviceOutcome.linked,
        counts: (favorites: 2, alerts: 1, vehicles: 3, fillUps: 4),
      );
      expect(s.isError, isFalse);
      expect(s.counts!.vehicles, 3);
    });

    test('copyWith preserves fields, clearResult wipes the outcome', () {
      const s = LinkDeviceState(
          isLinking: true, outcome: LinkDeviceOutcome.failed);
      final cleared = s.copyWith(clearResult: true);
      expect(cleared.isLinking, isTrue);
      expect(cleared.hasResult, isFalse);
    });
  });

  group('LinkDeviceController', () {
    test('initial state is idle', () {
      final c = makeContainer();
      expect(c.read(linkDeviceControllerProvider).isLinking, isFalse);
      expect(c.read(linkDeviceControllerProvider).hasResult, isFalse);
    });

    test('linkDevice with empty code sets validation error', () async {
      final c = makeContainer();
      await c.read(linkDeviceControllerProvider.notifier).linkDevice('');
      final s = c.read(linkDeviceControllerProvider);
      expect(s.outcome, LinkDeviceOutcome.invalidCode);
      expect(s.isLinking, isFalse);
    });

    test('linkDevice with too-short code sets validation error', () async {
      final c = makeContainer();
      await c.read(linkDeviceControllerProvider.notifier).linkDevice('short');
      expect(
        c.read(linkDeviceControllerProvider).outcome,
        LinkDeviceOutcome.invalidCode,
      );
    });
  });
}
