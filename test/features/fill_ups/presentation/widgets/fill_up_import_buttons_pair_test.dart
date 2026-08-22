// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/fill_up_import_buttons_pair.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #2110 — the widget became a `ConsumerWidget` that gates the receipt
/// button on `Feature.addFillUpOcrReceipt`. These tests assert the
/// rendered shape with the gate open — so we override
/// `featureFlagsProvider` with a receipt-enabled stub. (#3765 removed
/// the sibling pump-display button.)
class _ReceiptOcrEnabled extends FeatureFlags {
  @override
  Set<Feature> build() => {
        Feature.addFillUpOcrReceipt,
      };
}

class _NothingEnabled extends FeatureFlags {
  @override
  Set<Feature> build() => const {};
}

void main() {
  Widget buildPair({
    bool scanningReceipt = false,
    VoidCallback? onScanReceipt,
    FeatureFlags Function()? flags,
  }) {
    return ProviderScope(
      overrides: [
        featureFlagsProvider.overrideWith(flags ?? () => _ReceiptOcrEnabled()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: FillUpImportButtonsPair(
            scanningReceipt: scanningReceipt,
            onScanReceipt: onScanReceipt ?? () {},
          ),
        ),
      ),
    );
  }

  group('FillUpImportButtonsPair', () {
    testWidgets('renders the keyed receipt button', (tester) async {
      await tester.pumpWidget(buildPair());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('import_receipt_button')), findsOneWidget);
    });

    testWidgets('default state renders the receipt icon', (tester) async {
      await tester.pumpWidget(buildPair());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.document_scanner_outlined), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('default state shows the localized "Receipt" label',
        (tester) async {
      await tester.pumpWidget(buildPair());
      await tester.pumpAndSettle();

      expect(find.text('Receipt'), findsOneWidget);
    });

    testWidgets('scanningReceipt: true disables the receipt button',
        (tester) async {
      await tester.pumpWidget(buildPair(scanningReceipt: true));
      // CircularProgressIndicator animates forever; use pump() not
      // pumpAndSettle().
      await tester.pump();

      final receipt = tester.widget<OutlinedButton>(
        find.byKey(const Key('import_receipt_button')),
      );
      expect(receipt.onPressed, isNull);
    });

    testWidgets(
        'scanningReceipt: true replaces the receipt icon with a progress indicator',
        (tester) async {
      await tester.pumpWidget(buildPair(scanningReceipt: true));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.document_scanner_outlined), findsNothing);
    });

    testWidgets('tapping the enabled receipt button calls onScanReceipt',
        (tester) async {
      var receiptTaps = 0;
      await tester.pumpWidget(
        buildPair(onScanReceipt: () => receiptTaps++),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('import_receipt_button')));
      await tester.pump();

      expect(receiptTaps, 1);
    });

    testWidgets(
        'tapping the disabled receipt button (scanningReceipt: true) does NOT '
        'call onScanReceipt', (tester) async {
      var receiptTaps = 0;
      await tester.pumpWidget(
        buildPair(
          scanningReceipt: true,
          onScanReceipt: () => receiptTaps++,
        ),
      );
      await tester.pump();

      // Sanity-check disabled state.
      final receipt = tester.widget<OutlinedButton>(
        find.byKey(const Key('import_receipt_button')),
      );
      expect(receipt.onPressed, isNull);

      await tester.tap(
        find.byKey(const Key('import_receipt_button')),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(receiptTaps, 0);
    });

    testWidgets(
        'receipt gate closed → widget collapses to nothing (#2110)',
        (tester) async {
      await tester.pumpWidget(buildPair(flags: () => _NothingEnabled()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('import_receipt_button')), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    });
  });
}
