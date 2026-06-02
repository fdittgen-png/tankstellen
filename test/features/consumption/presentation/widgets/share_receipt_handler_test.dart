// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:share_handler/share_handler.dart';
import 'package:tankstellen/app/router.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/'
    'share_receipt_handler.dart';
import 'package:tankstellen/features/consumption/providers/'
    'pending_shared_receipt_provider.dart';
import 'package:tankstellen/features/feature_management/application/'
    'feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import '../../../../helpers/silence_error_logger.dart';

/// A real [GoRouter] with `/` and `/consumption/add` routes so the
/// handler's `push` resolves exactly as production does and the landed
/// route can be asserted (the same fake-router-by-real-route pattern as
/// `notification_launch_listener_test.dart`).
GoRouter _router({String? Function()? onAdd}) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const Text('home')),
      GoRoute(
        path: '/consumption/add',
        builder: (_, _) {
          onAdd?.call();
          return const Text('add-fill-up');
        },
      ),
    ],
  );
}

SharedMedia _imageMedia(String path) => SharedMedia(
      attachments: [
        SharedAttachment(path: path, type: SharedAttachmentType.image),
      ],
    );

SharedMedia _pdfMedia(String path) => SharedMedia(
      attachments: [
        SharedAttachment(path: path, type: SharedAttachmentType.file),
      ],
    );

void main() {
  silenceErrorLoggerSpool();

  const featureOn = {Feature.addFillUpShareIntentReceipt};

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    required GoRouter router,
    required Set<Feature> enabled,
  }) async {
    final container = ProviderContainer(
      overrides: [
        enabledFeaturesProvider.overrideWithValue(enabled),
        routerProvider.overrideWith((_) => router),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    return container;
  }

  group('ShareReceiptHandler.handle', () {
    testWidgets('stashes a shared image path and routes to /consumption/add',
        (tester) async {
      final router = _router();
      final container = await pump(tester, router: router, enabled: featureOn);

      container
          .read(shareReceiptHandlerProvider)
          .handle(_imageMedia('/tmp/receipt.jpg'));
      await tester.pumpAndSettle();

      expect(container.read(pendingSharedReceiptProvider), '/tmp/receipt.jpg',
          reason: 'the image path must be stashed for AddFillUpScreen to OCR');
      expect(find.text('add-fill-up'), findsOneWidget,
          reason: 'an image share routes the user to the Add-fill-up form');
    });

    testWidgets('does nothing when the feature is opt-OUT (#2735 gate)',
        (tester) async {
      final router = _router();
      final container = await pump(tester, router: router, enabled: const {});

      container
          .read(shareReceiptHandlerProvider)
          .handle(_imageMedia('/tmp/receipt.jpg'));
      await tester.pumpAndSettle();

      expect(container.read(pendingSharedReceiptProvider), isNull,
          reason: 'a disabled feature must never stash or route');
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('a shared PDF does not stash or route (unsupported format)',
        (tester) async {
      final router = _router();
      final container = await pump(tester, router: router, enabled: featureOn);

      container
          .read(shareReceiptHandlerProvider)
          .handle(_pdfMedia('/tmp/receipt.pdf'));
      await tester.pumpAndSettle();

      expect(container.read(pendingSharedReceiptProvider), isNull,
          reason: 'a PDF must not be stashed as an OCR-able image (#2737)');
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('null / empty media is a no-op', (tester) async {
      final router = _router();
      final container = await pump(tester, router: router, enabled: featureOn);

      container.read(shareReceiptHandlerProvider).handle(null);
      container
          .read(shareReceiptHandlerProvider)
          .handle(SharedMedia(attachments: const []));
      await tester.pumpAndSettle();

      expect(container.read(pendingSharedReceiptProvider), isNull);
      expect(find.text('home'), findsOneWidget);
    });
  });

  group('ShareReceiptHandler — never throws (#2349 fault injection)', () {
    testWidgets('returns normally when a downstream read throws',
        (tester) async {
      // Inject a feature-flags read that throws — the handler's gate
      // read is the first downstream dependency, and the #2349 contract
      // says a thrown dependency must be caught + logged, never
      // propagated out of the platform stream callback.
      final router = _router();
      final container = ProviderContainer(
        overrides: [
          enabledFeaturesProvider
              .overrideWith((_) => throw StateError('flags box closed')),
          routerProvider.overrideWith((_) => router),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      expect(
        () => container
            .read(shareReceiptHandlerProvider)
            .handle(_imageMedia('/tmp/receipt.jpg')),
        returnsNormally,
        reason: 'a thrown downstream dependency must be caught + logged, '
            'never propagated (#2349)',
      );
      // A failed gate read defaults to "disabled" → no stash, no route.
      expect(container.read(pendingSharedReceiptProvider), isNull);
      expect(find.text('home'), findsOneWidget);
    });
  });
}
