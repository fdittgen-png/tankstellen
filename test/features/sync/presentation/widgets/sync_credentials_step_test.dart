import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/features/sync/presentation/widgets/sync_credentials_step.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('SyncCredentialsStep', () {
    testWidgets('shows QR button for joinExisting mode', (tester) async {
      await pumpApp(
        tester,
        SyncCredentialsStep(
          selectedMode: SyncMode.joinExisting,
          urlController: TextEditingController(),
          keyController: TextEditingController(),
          showKey: false,
          onToggleKeyVisibility: () {},
          onScanQr: () {},
          onContinue: null,
          onChanged: () {},
        ),
      );

      expect(find.text('Scan QR Code'), findsOneWidget);
      expect(find.text('or enter manually'), findsOneWidget);
    });

    testWidgets('shows instruction text for private mode', (tester) async {
      await pumpApp(
        tester,
        SyncCredentialsStep(
          selectedMode: SyncMode.private,
          urlController: TextEditingController(),
          keyController: TextEditingController(),
          showKey: false,
          onToggleKeyVisibility: () {},
          onScanQr: () {},
          onContinue: null,
          onChanged: () {},
        ),
      );

      expect(find.textContaining('Supabase project credentials'), findsOneWidget);
      expect(find.text('Database URL'), findsOneWidget);
      expect(find.text('Access Key'), findsOneWidget);
    });

    testWidgets('Continue button is disabled when fields empty', (tester) async {
      await pumpApp(
        tester,
        SyncCredentialsStep(
          selectedMode: SyncMode.private,
          urlController: TextEditingController(),
          keyController: TextEditingController(),
          showKey: false,
          onToggleKeyVisibility: () {},
          onScanQr: () {},
          onContinue: null,
          onChanged: () {},
        ),
      );

      final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'));
      expect(button.onPressed, isNull);
    });
  });
}
