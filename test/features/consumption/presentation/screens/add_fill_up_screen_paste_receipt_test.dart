// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/features/consumption/presentation/screens/add_fill_up_screen.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fill_up_numeric_field.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/silence_error_logger.dart';

/// #2687 — end-to-end widget coverage for the MANUAL "paste receipt text"
/// entry point (the autonomous, on-device slice of the e-receipt epic).
///
/// Unlike the share-intent test, nothing is stashed: the user taps the
/// "Paste text" button on the form, pastes a realistic French fuel-receipt
/// text into the dialog, and confirms. The pure-Dart `EReceiptTextParser`
/// runs in-process (no camera, no OCR, no network) and pre-fills the SAME
/// liters/total controllers the camera + share paths use — and the form is
/// NOT auto-saved (the user still has to tap Save). The pasted text is a
/// realistic receipt shape, not a string crafted to trivially pass.

const _stubVehicle = VehicleProfile(
  id: 'stub-vehicle',
  name: 'Stub Car',
  type: VehicleType.combustion,
);

class _StubVehicleList extends VehicleProfileList {
  @override
  List<VehicleProfile> build() => const [_stubVehicle];
}

/// Enables the on-device receipt-import capability so the paste affordance
/// renders (it rides the same gate as the camera receipt button).
class _ReceiptImportEnabled extends FeatureFlags {
  @override
  Set<Feature> build() => {Feature.addFillUpOcrReceipt};
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

Future<void> _pumpScreen(WidgetTester tester) async {
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
        featureFlagsProvider.overrideWith(() => _ReceiptImportEnabled()),
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
}

void main() {
  silenceErrorLoggerSpool();

  // A realistic French TotalEnergies e-receipt body: comma decimals, the
  // `QTY x CODE` item line, a 3-decimal EUR/L price and a TOTAL TTC. This is
  // the same shape as the parser-level FR fixture, not a pass-shaped string.
  const frReceipt = 'TotalEnergies\n'
      'STATION RELAIS PART-DIEU\n'
      '69003 LYON\n'
      'Date 15/05/2026 08:42\n'
      '38,72 X SP95-E10\n'
      'Prix 1,829 EUR/L\n'
      'TOTAL TTC 70,83 EUR\n';

  testWidgets(
      'tapping "Paste text", pasting a French receipt and confirming '
      'pre-fills liters + total (and does NOT auto-save)', (tester) async {
    await _pumpScreen(tester);

    // The paste affordance is visible and the form starts blank.
    expect(find.byKey(const Key('import_paste_receipt_button')), findsOneWidget);
    expect(_valueOf(tester, 'Liters'), isEmpty);

    await tester.tap(find.byKey(const Key('import_paste_receipt_button')));
    await tester.pumpAndSettle();

    // The dialog opened with its text field.
    expect(find.byKey(const Key('paste_receipt_text_field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('paste_receipt_text_field')),
      frReceipt,
    );
    await tester.tap(find.byKey(const Key('paste_receipt_confirm_button')));
    await tester.pumpAndSettle();

    // The on-device parser pre-filled the controllers (2-decimal format).
    expect(_valueOf(tester, 'Liters'), '38.72',
        reason: 'pasted receipt litres pre-filled');
    expect(_valueOf(tester, 'Total cost'), '70.83',
        reason: 'pasted receipt total pre-filled');

    // NOT auto-saved: we are still on the Add-Fill-up form (its title shows),
    // nothing was persisted behind the user's back.
    expect(find.text('Add fill-up'), findsOneWidget,
        reason: 'paste pre-fills only — the user still confirms with Save');
  });

  testWidgets(
      'pasting non-receipt text shows the no-data message and leaves the '
      'form blank (no fabricated values)', (tester) async {
    await _pumpScreen(tester);

    await tester.tap(find.byKey(const Key('import_paste_receipt_button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('paste_receipt_text_field')),
      'Hi! Thanks for your order. Your package ships tomorrow.',
    );
    await tester.tap(find.byKey(const Key('paste_receipt_confirm_button')));
    await tester.pumpAndSettle();

    expect(_valueOf(tester, 'Liters'), isEmpty,
        reason: 'no fuel data in the text → nothing pre-filled');
    expect(_valueOf(tester, 'Total cost'), isEmpty);
    // The no-data snackbar surfaced (English copy).
    expect(
      find.textContaining("Couldn't read any fuel data"),
      findsOneWidget,
    );
  });

  testWidgets('cancelling the paste dialog leaves the form untouched',
      (tester) async {
    await _pumpScreen(tester);

    await tester.tap(find.byKey(const Key('import_paste_receipt_button')));
    await tester.pumpAndSettle();

    // Dismiss via the Cancel action — the dialog closes, nothing changes.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('paste_receipt_text_field')), findsNothing);
    expect(_valueOf(tester, 'Liters'), isEmpty);
  });
}
