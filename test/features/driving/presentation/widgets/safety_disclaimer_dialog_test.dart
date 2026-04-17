import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/driving/presentation/widgets/safety_disclaimer_dialog.dart';

import '../../../../helpers/pump_app.dart';

Future<bool?> _runAndAccept(WidgetTester tester) async {
  bool? result;
  await pumpApp(
    tester,
    Builder(
      builder: (context) => ElevatedButton(
        onPressed: () async {
          result = await SafetyDisclaimerDialog.show(context);
        },
        child: const Text('open'),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  group('SafetyDisclaimerDialog', () {
    testWidgets('renders title, body, cancel, accept',
        (tester) async {
      await _runAndAccept(tester);

      expect(find.text('Safety Notice'), findsOneWidget);
      expect(find.textContaining('Do not operate the app while driving'),
          findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('I understand'), findsOneWidget);
      // Warning icon anchors the dialog visually.
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('Accept returns true and closes the dialog',
        (tester) async {
      bool? returned;
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              returned = await SafetyDisclaimerDialog.show(context);
            },
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I understand'));
      await tester.pumpAndSettle();

      expect(returned, isTrue);
      expect(find.text('Safety Notice'), findsNothing);
    });

    testWidgets('Cancel returns false and closes the dialog',
        (tester) async {
      bool? returned;
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              returned = await SafetyDisclaimerDialog.show(context);
            },
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(returned, isFalse);
      expect(find.text('Safety Notice'), findsNothing);
    });

    testWidgets('barrier is non-dismissible — safety disclaimer must not be '
        'bypassed by tapping outside', (tester) async {
      bool? returned;
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              returned = await SafetyDisclaimerDialog.show(context);
            },
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Try to dismiss by tapping the corner. barrierDismissible: false
      // means the dialog should stay open.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(returned, isNull);
      expect(find.text('Safety Notice'), findsOneWidget);
    });
  });
}
