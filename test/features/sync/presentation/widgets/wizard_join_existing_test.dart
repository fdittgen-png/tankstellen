import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/sync/presentation/widgets/wizard_join_existing.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('WizardJoinExisting', () {
    testWidgets('renders localized QR, manual-entry, and Continue strings',
        (tester) async {
      await pumpApp(
        tester,
        WizardJoinExisting(
          urlController: TextEditingController(),
          keyController: TextEditingController(),
          keyField: const SizedBox.shrink(),
          onScanQr: () {},
          onContinue: null,
        ),
      );

      expect(find.text('Join an existing database'), findsOneWidget);
      expect(find.text('Scan QR Code'), findsOneWidget);
      expect(find.text('Enter manually'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('scan QR button invokes callback', (tester) async {
      var scanned = false;
      await pumpApp(
        tester,
        WizardJoinExisting(
          urlController: TextEditingController(),
          keyController: TextEditingController(),
          keyField: const SizedBox.shrink(),
          onScanQr: () => scanned = true,
          onContinue: null,
        ),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Scan QR Code'));
      await tester.pumpAndSettle();
      expect(scanned, isTrue);
    });
  });
}
