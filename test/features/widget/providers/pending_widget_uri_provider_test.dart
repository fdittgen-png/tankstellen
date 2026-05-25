// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/widget/providers/pending_widget_uri_provider.dart';

/// #widget-deeplink — cover the lifecycle contract of the
/// one-shot URI stash that the router's redirect chain consumes on
/// cold start.
void main() {
  group('PendingWidgetUri', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    test('starts empty (null)', () {
      expect(container.read(pendingWidgetUriProvider), isNull);
    });

    test('set(uri) stores the URI; subsequent read returns it', () {
      final uri = Uri.parse('tankstellenwidget://station?id=fr-12345');
      container.read(pendingWidgetUriProvider.notifier).set(uri);
      expect(container.read(pendingWidgetUriProvider), uri);
    });

    test('consume() returns the stored URI and clears the stash', () {
      final uri = Uri.parse('tankstellenwidget://station?id=fr-12345');
      container.read(pendingWidgetUriProvider.notifier).set(uri);
      final first = container
          .read(pendingWidgetUriProvider.notifier)
          .consume();
      expect(first, uri,
          reason: 'first consume must return the stashed URI');
      final second = container
          .read(pendingWidgetUriProvider.notifier)
          .consume();
      expect(second, isNull,
          reason: 'second consume must be null — stash is one-shot');
      expect(container.read(pendingWidgetUriProvider), isNull,
          reason: 'underlying state must also be cleared');
    });

    test('consume() on an empty stash is a no-op (returns null)', () {
      final result =
          container.read(pendingWidgetUriProvider.notifier).consume();
      expect(result, isNull);
      expect(container.read(pendingWidgetUriProvider), isNull);
    });

    test('set(null) clears an existing stash', () {
      final uri = Uri.parse('tankstellenwidget://station?id=de-99');
      container.read(pendingWidgetUriProvider.notifier).set(uri);
      container.read(pendingWidgetUriProvider.notifier).set(null);
      expect(container.read(pendingWidgetUriProvider), isNull);
    });
  });
}
