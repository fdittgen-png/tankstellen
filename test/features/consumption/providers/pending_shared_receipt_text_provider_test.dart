// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/receipt_parser.dart';
import 'package:tankstellen/features/consumption/providers/'
    'pending_shared_receipt_text_provider.dart';

/// #2838 — the one-shot stash for a parsed e-receipt TEXT result the share
/// handler writes and the AddFillUpScreen reads. Mirrors the path-stash
/// lifecycle test, focusing on the build-phase-safe `consumeDeferred`.
void main() {
  group('PendingSharedReceiptText', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    const result = ReceiptParseResult(liters: 30, totalCost: 54);

    test('starts empty (null)', () {
      expect(container.read(pendingSharedReceiptTextProvider), isNull);
    });

    test('set(result) stores it; subsequent read returns it', () {
      container.read(pendingSharedReceiptTextProvider.notifier).set(result);
      expect(container.read(pendingSharedReceiptTextProvider), same(result));
    });

    test('consumeDeferred() returns the result now, clears on a microtask',
        () async {
      container.read(pendingSharedReceiptTextProvider.notifier).set(result);
      final returned = container
          .read(pendingSharedReceiptTextProvider.notifier)
          .consumeDeferred();
      expect(returned, same(result),
          reason: 'the result is returned synchronously for the screen to '
              'apply in the same frame');
      expect(container.read(pendingSharedReceiptTextProvider), same(result),
          reason: 'the clear is deferred to avoid the build-phase write assert');
      await Future<void>.value();
      expect(container.read(pendingSharedReceiptTextProvider), isNull,
          reason: 'the microtask clears the stash');
    });

    test('consumeDeferred() on an empty stash is a no-op (returns null)', () {
      final returned = container
          .read(pendingSharedReceiptTextProvider.notifier)
          .consumeDeferred();
      expect(returned, isNull);
      expect(container.read(pendingSharedReceiptTextProvider), isNull);
    });

    test('set(null) clears an existing stash', () {
      container.read(pendingSharedReceiptTextProvider.notifier).set(result);
      container.read(pendingSharedReceiptTextProvider.notifier).set(null);
      expect(container.read(pendingSharedReceiptTextProvider), isNull);
    });
  });
}
