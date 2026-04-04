import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/sync/presentation/widgets/wizard_auth_step.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('WizardAuthStep', () {
    testWidgets('renders anonymous and email options', (tester) async {
      await pumpApp(
        tester,
        WizardAuthStep(
          useEmail: false,
          isSignUp: true,
          testing: false,
          connecting: false,
          testResult: null,
          testSuccess: false,
          emailController: TextEditingController(),
          passwordController: TextEditingController(),
          onUseEmailChanged: (_) {},
          onToggleSignUp: () {},
          onTestConnection: () {},
          onConnect: () {},
        ),
      );

      expect(find.text('Anonymous'), findsOneWidget);
      expect(find.text('Email Account'), findsOneWidget);
      expect(find.text('Test Connection'), findsOneWidget);
      expect(find.text('Connect'), findsOneWidget);
    });

    testWidgets('shows email fields when useEmail is true', (tester) async {
      await pumpApp(
        tester,
        WizardAuthStep(
          useEmail: true,
          isSignUp: true,
          testing: false,
          connecting: false,
          testResult: null,
          testSuccess: false,
          emailController: TextEditingController(),
          passwordController: TextEditingController(),
          onUseEmailChanged: (_) {},
          onToggleSignUp: () {},
          onTestConnection: () {},
          onConnect: () {},
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('shows test result when provided', (tester) async {
      await pumpApp(
        tester,
        WizardAuthStep(
          useEmail: false,
          isSignUp: true,
          testing: false,
          connecting: false,
          testResult: 'Connection successful!',
          testSuccess: true,
          emailController: TextEditingController(),
          passwordController: TextEditingController(),
          onUseEmailChanged: (_) {},
          onToggleSignUp: () {},
          onTestConnection: () {},
          onConnect: () {},
        ),
      );

      expect(find.text('Connection successful!'), findsOneWidget);
    });
  });
}
