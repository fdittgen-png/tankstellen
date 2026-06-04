// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/app/router.dart';
import 'package:tankstellen/features/consumption/data/ocr/'
    'receipt_pdf_rasterizer.dart';
import 'package:tankstellen/features/consumption/data/share/'
    'shared_receipt_intent.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/'
    'share_receipt_handler.dart';
import 'package:tankstellen/features/consumption/providers/'
    'pending_shared_receipt_provider.dart';
import 'package:tankstellen/features/consumption/providers/'
    'pending_shared_receipt_text_provider.dart';
import 'package:tankstellen/features/feature_management/application/'
    'feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import '../../../../helpers/silence_error_logger.dart';

/// A real [GoRouter] with `/` and `/consumption/add` routes so the handler's
/// `push` resolves exactly as production does (the same fake-router-by-real-
/// route pattern as `notification_launch_listener_test.dart`).
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

SharedReceiptIntent _imageIntent(String path) =>
    SharedReceiptIntent(items: [SharedReceiptItem.image(path)]);

SharedReceiptIntent _pdfIntent(String path) =>
    SharedReceiptIntent(items: [SharedReceiptItem.pdf(path)]);

SharedReceiptIntent _fileIntent(String path) =>
    SharedReceiptIntent(items: [SharedReceiptItem.file(path)]);

SharedReceiptIntent _textIntent(String text, {String? country}) =>
    SharedReceiptIntent(
      items: [SharedReceiptItem.text(text)],
      countryCode: country,
    );

/// Test double for the on-device PDF rasteriser (#2737) — the native
/// PdfRenderer is unavailable under `flutter test`, so the PDF branch is
/// driven with an injected fake that records the path and returns a canned
/// result.
class _FakeRasterizer extends ReceiptPdfRasterizer {
  _FakeRasterizer(this._result);
  final String? _result;
  String? receivedPdfPath;

  @override
  Future<String?> rasterize(String path) async {
    receivedPdfPath = path;
    return _result;
  }
}

String _fixture(String name) => File(
      'test/features/consumption/data/ereceipt/fixtures/$name',
    ).readAsStringSync();

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

  group('ShareReceiptHandler.handle — image', () {
    testWidgets('stashes a shared image path and routes to /consumption/add',
        (tester) async {
      final router = _router();
      final container = await pump(tester, router: router, enabled: featureOn);

      container
          .read(shareReceiptHandlerProvider)
          .handle(_imageIntent('/tmp/receipt.jpg'));
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
          .handle(_imageIntent('/tmp/receipt.jpg'));
      await tester.pumpAndSettle();

      expect(container.read(pendingSharedReceiptProvider), isNull,
          reason: 'a disabled feature must never stash or route');
      expect(find.text('home'), findsOneWidget);
    });
  });

  group('ShareReceiptHandler.handle — PDF (#2737)', () {
    testWidgets(
        'a shared PDF is rasterised, then takes the SAME stash+route path '
        'as an image', (tester) async {
      final router = _router();
      final fake = _FakeRasterizer('/tmp/receipt.pdf.page1.jpg');
      final container = await pump(tester,
          router: router, enabled: featureOn, rasterizer: fake);

      container
          .read(shareReceiptHandlerProvider)
          .handle(_pdfIntent('/tmp/receipt.pdf'));
      await tester.pumpAndSettle();

      expect(fake.receivedPdfPath, '/tmp/receipt.pdf');
      expect(container.read(pendingSharedReceiptProvider),
          '/tmp/receipt.pdf.page1.jpg',
          reason: 'the rasterised JPEG must be stashed for the SAME OCR path');
      expect(find.text('add-fill-up'), findsOneWidget);
    });

    testWidgets('a PDF whose rasterisation fails does NOT stash or route',
        (tester) async {
      final router = _router();
      final fake = _FakeRasterizer(null);
      final container = await pump(tester,
          router: router, enabled: featureOn, rasterizer: fake);

      container
          .read(shareReceiptHandlerProvider)
          .handle(_pdfIntent('/tmp/corrupt.pdf'));
      await tester.pumpAndSettle();

      expect(fake.receivedPdfPath, '/tmp/corrupt.pdf');
      expect(container.read(pendingSharedReceiptProvider), isNull,
          reason: 'a failed rasterisation must fall back gracefully');
      expect(find.text('home'), findsOneWidget);
    });
  });

  group('ShareReceiptHandler.handle — text (#2838)', () {
    testWidgets(
        'a shared e-receipt text body is parsed by the REAL parser and the '
        'result stashed + routed', (tester) async {
      final router = _router();
      final container = await pump(tester, router: router, enabled: featureOn);

      container.read(shareReceiptHandlerProvider).handle(
            _textIntent(_fixture('eni_milano_2026-05-12.txt'), country: 'IT'),
          );
      await tester.pumpAndSettle();

      final result = container.read(pendingSharedReceiptTextProvider);
      expect(result, isNotNull,
          reason: 'the parsed text result must be stashed for the form');
      expect(result!.liters, closeTo(42.18, 0.01));
      expect(result.totalCost, closeTo(75.46, 0.01));
      expect(result.fuelType, FuelType.diesel);
      // The path stash stays empty — a text share has no file to OCR.
      expect(container.read(pendingSharedReceiptProvider), isNull);
      expect(find.text('add-fill-up'), findsOneWidget,
          reason: 'a parseable text receipt routes to the Add-fill-up form');
    });

    testWidgets('a text body with no parseable receipt does NOT stash or route',
        (tester) async {
      final router = _router();
      final container = await pump(tester, router: router, enabled: featureOn);

      container
          .read(shareReceiptHandlerProvider)
          .handle(_textIntent('Hi! Your order ships tomorrow.', country: 'DE'));
      await tester.pumpAndSettle();

      expect(container.read(pendingSharedReceiptTextProvider), isNull,
          reason: 'non-receipt text must not route to a blank form');
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('text share is also gated by the opt-in feature flag',
        (tester) async {
      final router = _router();
      final container = await pump(tester, router: router, enabled: const {});

      container.read(shareReceiptHandlerProvider).handle(
            _textIntent(_fixture('eni_milano_2026-05-12.txt'), country: 'IT'),
          );
      await tester.pumpAndSettle();

      expect(container.read(pendingSharedReceiptTextProvider), isNull);
      expect(find.text('home'), findsOneWidget);
    });
  });

  group('ShareReceiptHandler.handle — unsupported / empty', () {
    testWidgets('a non-PDF file is never sent to the rasteriser (unsupported)',
        (tester) async {
      final router = _router();
      final fake = _FakeRasterizer('/should/not/be/used.jpg');
      final container = await pump(tester,
          router: router, enabled: featureOn, rasterizer: fake);

      container
          .read(shareReceiptHandlerProvider)
          .handle(_fileIntent('/tmp/statement.docx'));
      await tester.pumpAndSettle();

      expect(fake.receivedPdfPath, isNull);
      expect(container.read(pendingSharedReceiptProvider), isNull);
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('null / empty intent is a no-op', (tester) async {
      final router = _router();
      final container = await pump(tester, router: router, enabled: featureOn);

      container.read(shareReceiptHandlerProvider).handle(null);
      container
          .read(shareReceiptHandlerProvider)
          .handle(const SharedReceiptIntent(items: []));
      await tester.pumpAndSettle();

      expect(container.read(pendingSharedReceiptProvider), isNull);
      expect(container.read(pendingSharedReceiptTextProvider), isNull);
      expect(find.text('home'), findsOneWidget);
    });
  });

  group('ShareReceiptHandler — never throws (#2349 fault injection)', () {
    testWidgets('returns normally when a downstream read throws',
        (tester) async {
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
            .handle(_imageIntent('/tmp/receipt.jpg')),
        returnsNormally,
        reason: 'a thrown downstream dependency must be caught + logged, '
            'never propagated (#2349)',
      );
      expect(container.read(pendingSharedReceiptProvider), isNull);
      expect(find.text('home'), findsOneWidget);
    });
  });
}
