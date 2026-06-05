// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/app/router.dart';
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

/// #2736 — the iOS Share Extension seam. On iOS the share arrives as a
/// `pending_share.json` manifest the extension writes into the App Group
/// container; the host `ShareIntentBridge` (AppDelegate.swift) reads it with
/// `JSONSerialization`, returns the parsed map down `getInitialShare`, and the
/// Dart `_PlatformShareIntentChannel` feeds it to
/// `SharedReceiptIntent.fromPlatform`. iOS and Android emit the IDENTICAL
/// `{items, country}` shape — so these tests drive the REAL handler with a
/// payload built by serialising the EXACT manifest the Swift extension writes,
/// then JSON-decoding it (the round-trip the native bridge performs), proving
/// an iOS share routes into the same fill-up / parser flow as Android — with
/// no iOS-specific Dart code on the path.
void main() {
  silenceErrorLoggerSpool();

  const featureOn = {Feature.addFillUpShareIntentReceipt};

  /// Builds a `SharedReceiptIntent` the way the iOS path does: the Swift
  /// extension serialises `manifest` with `JSONSerialization`; the host bridge
  /// hands the JSON-decoded map to `fromPlatform`. We mirror that round-trip so
  /// a drift in the manifest shape would fail here, not silently on device.
  SharedReceiptIntent decodeIosManifest(Map<String, Object?> manifest) {
    final roundTripped = jsonDecode(jsonEncode(manifest)) as Map<String, Object?>;
    final intent = SharedReceiptIntent.fromPlatform(roundTripped);
    expect(intent, isNotNull,
        reason: 'the iOS manifest must decode to a routable intent');
    return intent!;
  }

  GoRouter buildRouter() => GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Text('home')),
          GoRoute(
            path: '/consumption/add',
            builder: (_, _) => const Text('add-fill-up'),
          ),
        ],
      );

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    required GoRouter router,
    Set<Feature> enabled = featureOn,
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

  testWidgets(
      'an iOS-shared receipt IMAGE manifest stashes the path and routes to '
      '/consumption/add', (tester) async {
    final router = buildRouter();
    final container = await pump(tester, router: router);

    // The manifest the Swift extension writes for a shared photo: a single
    // image item with the App Group container path, plus the device region.
    final intent = decodeIosManifest({
      'items': [
        {
          'kind': 'image',
          'path': '/private/var/.../group.de.tankstellen.tankstellen/'
              'shared_receipt_1717000000000_0.jpg',
        },
      ],
      'country': 'DE',
    });

    container.read(shareReceiptHandlerProvider).handle(intent);
    await tester.pumpAndSettle();

    expect(
      container.read(pendingSharedReceiptProvider),
      '/private/var/.../group.de.tankstellen.tankstellen/'
          'shared_receipt_1717000000000_0.jpg',
      reason: 'the App-Group image path must be stashed for AddFillUpScreen '
          'to OCR — the same stash Android uses',
    );
    expect(find.text('add-fill-up'), findsOneWidget,
        reason: 'an iOS image share routes into the Add-fill-up form');
  });

  testWidgets(
      'an iOS-shared e-receipt TEXT manifest is parsed by the REAL parser and '
      'routed', (tester) async {
    final router = buildRouter();
    final container = await pump(tester, router: router);

    final receiptText = File(
      'test/features/consumption/data/ereceipt/fixtures/'
      'eni_milano_2026-05-12.txt',
    ).readAsStringSync();

    // The manifest for a shared text body (e-receipt e-mail / link): a single
    // text item, country resolved natively from Locale.current.regionCode.
    final intent = decodeIosManifest({
      'items': [
        {'kind': 'text', 'text': receiptText},
      ],
      'country': 'IT',
    });

    container.read(shareReceiptHandlerProvider).handle(intent);
    await tester.pumpAndSettle();

    final result = container.read(pendingSharedReceiptTextProvider);
    expect(result, isNotNull,
        reason: 'the iOS text e-receipt must be parsed and stashed');
    expect(result!.liters, closeTo(42.18, 0.01));
    expect(result.fuelType, FuelType.diesel);
    expect(find.text('add-fill-up'), findsOneWidget,
        reason: 'a parseable iOS text receipt routes into the form');
  });

  testWidgets(
      'a SEND-multiple iOS manifest (image + stray file) still prefills from '
      'the image', (tester) async {
    final router = buildRouter();
    final container = await pump(tester, router: router);

    // The extension can resolve more than one attachment; the handler picks
    // the first image and ignores the rest — same as Android.
    final intent = decodeIosManifest({
      'items': [
        {'kind': 'file', 'path': '/group/shared_receipt_1_0.bin'},
        {'kind': 'image', 'path': '/group/shared_receipt_1_1.jpg'},
      ],
      'country': 'FR',
    });

    container.read(shareReceiptHandlerProvider).handle(intent);
    await tester.pumpAndSettle();

    expect(container.read(pendingSharedReceiptProvider),
        '/group/shared_receipt_1_1.jpg',
        reason: 'the image wins over a non-image attachment in the same batch');
    expect(find.text('add-fill-up'), findsOneWidget);
  });

  testWidgets('an iOS share is gated by the opt-in feature flag', (tester) async {
    final router = buildRouter();
    final container = await pump(tester, router: router, enabled: const {});

    final intent = decodeIosManifest({
      'items': [
        {'kind': 'image', 'path': '/group/shared_receipt.jpg'},
      ],
      'country': 'DE',
    });

    container.read(shareReceiptHandlerProvider).handle(intent);
    await tester.pumpAndSettle();

    expect(container.read(pendingSharedReceiptProvider), isNull,
        reason: 'a disabled feature must never stash or route on iOS either');
    expect(find.text('home'), findsOneWidget);
  });
}
