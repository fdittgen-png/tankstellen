// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:share_handler/share_handler.dart';
import 'package:tankstellen/app/router.dart';
import 'package:tankstellen/features/consumption/data/ocr/'
    'receipt_pdf_rasterizer.dart';
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

/// A shared PDF arrives via `share_handler` as a `file` attachment (the
/// package has no `pdf` type and carries no MIME) — the handler keys off
/// the `.pdf` extension.
SharedMedia _pdfMedia(String path) => SharedMedia(
      attachments: [
        SharedAttachment(path: path, type: SharedAttachmentType.file),
      ],
    );

/// A genuinely-unsupported share (video, or a non-PDF arbitrary file).
SharedMedia _fileMedia(String path) => SharedMedia(
      attachments: [
        SharedAttachment(path: path, type: SharedAttachmentType.file),
      ],
    );

/// Test double for the on-device PDF rasteriser (#2737) — the native
/// PdfRenderer is unavailable under `flutter test`, so the PDF branch is
/// driven with an injected fake that records the path it was asked to
/// rasterise and returns a canned result.
class _FakeRasterizer extends ReceiptPdfRasterizer {
  _FakeRasterizer(this._result);

  /// The JPEG path the rasteriser "produced", or null to model failure.
  final String? _result;
  String? receivedPdfPath;

  @override
  Future<String?> rasterize(String path) async {
    receivedPdfPath = path;
    return _result;
  }
}

void main() {
  silenceErrorLoggerSpool();

  const featureOn = {Feature.addFillUpShareIntentReceipt};

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    required GoRouter router,
    required Set<Feature> enabled,
    ReceiptPdfRasterizer? rasterizer,
  }) async {
    final container = ProviderContainer(
      overrides: [
        enabledFeaturesProvider.overrideWithValue(enabled),
        routerProvider.overrideWith((_) => router),
        if (rasterizer != null)
          receiptPdfRasterizerProvider.overrideWithValue(rasterizer),
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

    testWidgets(
        'a shared PDF is rasterised, then takes the SAME stash+route '
        'path as an image (#2737)', (tester) async {
      final router = _router();
      final fake = _FakeRasterizer('/tmp/receipt.pdf.page1.jpg');
      final container = await pump(tester,
          router: router, enabled: featureOn, rasterizer: fake);

      container
          .read(shareReceiptHandlerProvider)
          .handle(_pdfMedia('/tmp/receipt.pdf'));
      await tester.pumpAndSettle();

      expect(fake.receivedPdfPath, '/tmp/receipt.pdf',
          reason: 'the PDF path must be handed to the rasteriser');
      expect(container.read(pendingSharedReceiptProvider),
          '/tmp/receipt.pdf.page1.jpg',
          reason: 'the rasterised JPEG must be stashed for the SAME OCR path '
              'an image share uses (#2737)');
      expect(find.text('add-fill-up'), findsOneWidget,
          reason: 'a rasterised PDF routes the user to the Add-fill-up form');
    });

    testWidgets(
        'a PDF whose rasterisation fails does NOT stash or route '
        '(graceful fallback)', (tester) async {
      final router = _router();
      // A null result models a corrupt PDF / absent native renderer.
      final fake = _FakeRasterizer(null);
      final container = await pump(tester,
          router: router, enabled: featureOn, rasterizer: fake);

      container
          .read(shareReceiptHandlerProvider)
          .handle(_pdfMedia('/tmp/corrupt.pdf'));
      await tester.pumpAndSettle();

      expect(fake.receivedPdfPath, '/tmp/corrupt.pdf');
      expect(container.read(pendingSharedReceiptProvider), isNull,
          reason: 'a failed rasterisation must fall back gracefully, not '
              'stash a non-existent bitmap');
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('a non-PDF file is never sent to the rasteriser (unsupported)',
        (tester) async {
      final router = _router();
      final fake = _FakeRasterizer('/should/not/be/used.jpg');
      final container = await pump(tester,
          router: router, enabled: featureOn, rasterizer: fake);

      container
          .read(shareReceiptHandlerProvider)
          .handle(_fileMedia('/tmp/statement.docx'));
      await tester.pumpAndSettle();

      expect(fake.receivedPdfPath, isNull,
          reason: 'only .pdf files are rasterised; other files are '
              'unsupported');
      expect(container.read(pendingSharedReceiptProvider), isNull);
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
