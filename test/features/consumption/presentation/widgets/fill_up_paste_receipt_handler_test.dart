// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/ereceipt/ereceipt_text_parser.dart';
import 'package:tankstellen/features/consumption/data/receipt_parser/receipt_parse_result.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fill_up_paste_receipt_handler.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fill_up_scan_handlers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/silence_error_logger.dart';

/// Fault-path contract test for [runPasteReceiptText] (#2349 / #2687).
///
/// The handler documents a "never throws" contract: a parse fault must be
/// logged and surfaced as the no-data snackbar rather than crashing the
/// Add-Fill-up form. This test injects a throwing [EReceiptTextParser]
/// through the handler's `parser` seam, drives the real paste dialog, and
/// asserts the handler returns normally (no exception escapes) and the
/// no-data message is shown — exactly the degrade the docstring promises.
class _ThrowingParser extends EReceiptTextParser {
  const _ThrowingParser();

  @override
  ReceiptParseResult parse(String text, {String? countryCode}) =>
      throw StateError('injected parse fault');
}

FillUpScanHostState _host({
  required TextEditingController liters,
  required TextEditingController cost,
}) =>
    FillUpScanHostState(
      litersCtrl: liters,
      costCtrl: cost,
      vehicleId: null,
      readService: () => null,
      writeService: (_) {},
      setScanning: (_) {},
      setScanningPump: (_) {},
      setDate: (_) {},
      setFuelType: (_) {},
      setScannedPricePerLiter: (_) {},
      setLastScan: (_) {},
      isMounted: () => true,
      capturePumpImage: (BuildContext _) async => null,
      activeCountry: 'FR',
    );

void main() {
  silenceErrorLoggerSpool();

  testWidgets(
      'an injected parse fault is swallowed — the handler returns normally '
      'and shows the no-data snackbar (never throws, #2349)', (tester) async {
    final liters = TextEditingController();
    final cost = TextEditingController();
    addTearDown(liters.dispose);
    addTearDown(cost.dispose);
    final host = _host(liters: liters, cost: cost);

    // Capture the handler future so we can assert it COMPLETES (never throws)
    // despite the injected parse fault.
    late Future<void> handlerFuture;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              key: const Key('paste_btn'),
              onPressed: () => handlerFuture = runPasteReceiptText(
                context,
                host,
                parser: const _ThrowingParser(),
              ),
              child: const Text('paste'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('paste_btn')));
    await tester.pumpAndSettle();

    // Paste non-blank text so the handler proceeds into the (throwing) parse.
    await tester.enterText(
      find.byKey(const Key('paste_receipt_text_field')),
      'TotalEnergies 38,72 L SP95-E10 TOTAL 70,83 EUR',
    );
    await tester.tap(find.byKey(const Key('paste_receipt_confirm_button')));
    await tester.pumpAndSettle();

    // The throwing parser must NOT crash the form: the never-throws boundary's
    // future completes and no exception escapes.
    await expectLater(handlerFuture, completes);
    expect(tester.takeException(), isNull,
        reason: 'the injected parse fault is caught + logged, never rethrown');

    // The fault is surfaced to the user as the no-data snackbar, and nothing
    // is fabricated into the form.
    expect(find.textContaining("Couldn't read any fuel data"), findsOneWidget);
    expect(liters.text, isEmpty);
    expect(cost.text, isEmpty);
  });
}
