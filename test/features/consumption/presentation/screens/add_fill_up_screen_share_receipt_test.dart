// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tankstellen/features/consumption/data/ereceipt/ereceipt_text_parser.dart';
import 'package:tankstellen/features/consumption/data/receipt_parser.dart';
import 'package:tankstellen/features/consumption/data/receipt_scan_service.dart';
import 'package:tankstellen/features/consumption/presentation/screens/add_fill_up_screen.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fill_up_numeric_field.dart';
import 'package:tankstellen/features/consumption/providers/pending_shared_receipt_provider.dart';
import 'package:tankstellen/features/consumption/providers/pending_shared_receipt_text_provider.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/silence_error_logger.dart';

/// #2735 — end-to-end widget coverage for the inbound OS share-intent
/// receipt prefill. A receipt image path stashed in
/// [pendingSharedReceiptProvider] (the router landed the user on
/// `/consumption/add`) must be OCR'd on open and prefill the form via the
/// SAME `runSharedReceiptScan` path the #2734 foundation shipped.
///
/// Reuse-fidelity: the REAL [ReceiptParser] runs inside a real
/// [ReceiptScanService], with only the OCR boundary faked — queued from
/// the shipped `super_u_pomerols` fixture's OCR text (never a request-
/// echoing fake, which would mask a parse-shape regression). The expected
/// values are exactly those the parser-level test pins for that fixture.

const _stubVehicle = VehicleProfile(
  id: 'stub-vehicle',
  name: 'Stub Car',
  type: VehicleType.combustion,
);

class _StubVehicleList extends VehicleProfileList {
  @override
  List<VehicleProfile> build() => const [_stubVehicle];
}

class _ShareIntentEnabled extends FeatureFlags {
  @override
  Set<Feature> build() => {Feature.addFillUpShareIntentReceipt};
}

/// Fake picker: never used on the share path (the photo is already on
/// disk), but the real [ReceiptScanService] constructor needs one.
class _NoopPicker extends ImagePicker {}

/// Recognizer that returns the queued OCR text — the only faked boundary.
class _FixtureRecognizer extends TextRecognizer {
  _FixtureRecognizer(this.text);
  final String text;

  @override
  Future<RecognizedText> processImage(InputImage input) async =>
      RecognizedText(text: text, blocks: const []);

  @override
  Future<void> close() async {}
}

String _fixture(String name) => File(
      'test/features/consumption/data/receipt_parser/fixtures/$name',
    ).readAsStringSync();

/// Writes a throwaway capture file (minimal JPEG bytes); the recognizer
/// ignores its contents in favour of the queued fixture text.
Future<({String path, Directory dir})> _tempCapture() async {
  final dir = await Directory.systemTemp.createTemp('share_receipt_screen_');
  final file = File('${dir.path}${Platform.pathSeparator}receipt.jpg');
  await file.writeAsBytes(<int>[0xFF, 0xD8, 0xFF, 0xD9]);
  return (path: file.path, dir: dir);
}

Finder _fieldByLabel(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byType(FillUpNumericField),
    );

String _valueOf(WidgetTester tester, String label) {
  final field = tester.widget<TextField>(
    find.descendant(
      of: _fieldByLabel(label),
      matching: find.byType(TextField),
    ),
  );
  return field.controller!.text;
}

void main() {
  silenceErrorLoggerSpool();

  testWidgets(
      'a stashed shared-receipt image prefills the form via the real parser',
      (tester) async {
    await tester.runAsync(() async {
      final capture = await _tempCapture();
      final scanService = ReceiptScanService(
        picker: _NoopPicker(),
        recognizer: _FixtureRecognizer(_fixture('super_u_pomerols_2026-04-19.txt')),
        parser: const ReceiptParser(),
      );

      final router = GoRouter(
        initialLocation: '/add',
        routes: [
          GoRoute(
            path: '/add',
            builder: (context, state) =>
                AddFillUpScreen(scanService: scanService),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vehicleProfileListProvider.overrideWith(() => _StubVehicleList()),
            featureFlagsProvider.overrideWith(() => _ShareIntentEnabled()),
            // The router redirect has already stashed the shared image
            // path; the screen consumes it on open.
            pendingSharedReceiptProvider.overrideWith(
              () => _SeededPendingSharedReceipt(capture.path),
            ),
          ],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            routerConfig: router,
          ),
        ),
      );

      // initState schedules the OCR on the next post-frame callback;
      // the real service then does file I/O (orientation bake) + the
      // parse on the real async zone. Interleave pumps (to fire the
      // post-frame callback + flush each setState) with real-zone yields
      // (to let the OCR/parse futures complete) until the controllers
      // carry the prefill — up to ~1 s, generous for the tiny fixture.
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 20));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        if (_valueOf(tester, 'Liters').isNotEmpty) break;
      }

      // The fixture parses to 5.24 L / €10.47 — same values the #2734
      // share-handler test and the parser-level test pin.
      expect(_valueOf(tester, 'Liters'), '5.24',
          reason: 'the shared receipt OCR prefilled litres');
      expect(_valueOf(tester, 'Total cost'), '10.47',
          reason: 'the shared receipt OCR prefilled the total');

      await capture.dir.delete(recursive: true);
    });
  });

  testWidgets(
      'a stashed shared-receipt TEXT result prefills the form via the real '
      'e-receipt parser (#2838)', (tester) async {
    // The share handler parses shared text at receive time; the screen
    // applies the stashed result through the same prefill body. Seed the
    // stash with the REAL EReceiptTextParser's output for a German e-receipt
    // fixture so this drives the actual parse→apply path end to end.
    final parsed = const EReceiptTextParser().parse(
      File('test/features/consumption/data/ereceipt/fixtures/'
              'aral_koeln_2026-05-28.txt')
          .readAsStringSync(),
      countryCode: 'DE',
    );
    expect(parsed.hasData, isTrue, reason: 'fixture must parse');

    final router = GoRouter(
      initialLocation: '/add',
      routes: [
        GoRoute(
          path: '/add',
          builder: (context, state) => const AddFillUpScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vehicleProfileListProvider.overrideWith(() => _StubVehicleList()),
          featureFlagsProvider.overrideWith(() => _ShareIntentEnabled()),
          pendingSharedReceiptTextProvider.overrideWith(
            () => _SeededPendingSharedReceiptText(parsed),
          ),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The Aral Köln fixture parses to 44.07 L / €77.52 — the apply body
    // formats them to 2 decimals into the controllers.
    expect(_valueOf(tester, 'Liters'), '44.07',
        reason: 'the shared text result prefilled litres');
    expect(_valueOf(tester, 'Total cost'), '77.52',
        reason: 'the shared text result prefilled the total');
  });

  testWidgets('no stashed path → the form opens blank (manual entry)',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/add',
      routes: [
        GoRoute(
          path: '/add',
          builder: (context, state) => const AddFillUpScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vehicleProfileListProvider.overrideWith(() => _StubVehicleList()),
          featureFlagsProvider.overrideWith(() => _ShareIntentEnabled()),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_valueOf(tester, 'Liters'), isEmpty,
        reason: 'no share → nothing prefilled');
  });
}

/// Seeds [pendingSharedReceiptProvider] with [_path] at build so the
/// screen consumes it on open, simulating the router having stashed the
/// shared image path before routing to `/consumption/add`.
class _SeededPendingSharedReceipt extends PendingSharedReceipt {
  _SeededPendingSharedReceipt(this._path);
  final String _path;

  @override
  String? build() => _path;
}

/// Seeds [pendingSharedReceiptTextProvider] with a parsed result at build so
/// the screen applies it on open, simulating the share handler having parsed
/// shared e-receipt text before routing to `/consumption/add` (#2838).
class _SeededPendingSharedReceiptText extends PendingSharedReceiptText {
  _SeededPendingSharedReceiptText(this._result);
  final ReceiptParseResult _result;

  @override
  ReceiptParseResult? build() => _result;
}
