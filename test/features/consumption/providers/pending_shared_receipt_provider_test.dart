// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/providers/'
    'pending_shared_receipt_provider.dart';

/// #2735 — cover the one-shot stash contract for the inbound-share
/// receipt path the router redirect + AddFillUpScreen both read. Mirrors
/// the `PendingWidgetUri` lifecycle test it was modelled on.
void main() {
  group('PendingSharedReceipt', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    test('starts empty (null)', () {
      expect(container.read(pendingSharedReceiptProvider), isNull);
    });

    test('set(path) stores the path; subsequent read returns it', () {
      container
          .read(pendingSharedReceiptProvider.notifier)
          .set('/tmp/receipt.jpg');
      expect(container.read(pendingSharedReceiptProvider), '/tmp/receipt.jpg');
    });

    test('consume() returns the stored path and clears the stash', () {
      container
          .read(pendingSharedReceiptProvider.notifier)
          .set('/tmp/receipt.jpg');
      final first =
          container.read(pendingSharedReceiptProvider.notifier).consume();
      expect(first, '/tmp/receipt.jpg',
          reason: 'first consume must return the stashed path');
      final second =
          container.read(pendingSharedReceiptProvider.notifier).consume();
      expect(second, isNull,
          reason: 'second consume must be null — stash is one-shot');
      expect(container.read(pendingSharedReceiptProvider), isNull,
          reason: 'underlying state must also be cleared');
    });

    test('consume() on an empty stash is a no-op (returns null)', () {
      final result =
          container.read(pendingSharedReceiptProvider.notifier).consume();
      expect(result, isNull);
      expect(container.read(pendingSharedReceiptProvider), isNull);
    });

    test('consumeDeferred() returns the path now, clears on a microtask',
        () async {
      container
          .read(pendingSharedReceiptProvider.notifier)
          .set('/tmp/receipt.jpg');
      final returned = container
          .read(pendingSharedReceiptProvider.notifier)
          .consumeDeferred();
      expect(returned, '/tmp/receipt.jpg',
          reason: 'the path is returned synchronously so the redirect can '
              'route in the same tick');
      // The clear is scheduled as a microtask — still present this tick.
      expect(container.read(pendingSharedReceiptProvider), '/tmp/receipt.jpg',
          reason: 'state mutation is deferred to avoid the Riverpod '
              'build-phase write assertion');
      await Future<void>.value();
      expect(container.read(pendingSharedReceiptProvider), isNull,
          reason: 'the microtask clears the stash after the redirect returns');
    });

    test('set(null) clears an existing stash', () {
      container
          .read(pendingSharedReceiptProvider.notifier)
          .set('/tmp/receipt.jpg');
      container.read(pendingSharedReceiptProvider.notifier).set(null);
      expect(container.read(pendingSharedReceiptProvider), isNull);
    });
  });
}
