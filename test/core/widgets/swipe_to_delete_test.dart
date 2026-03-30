import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/swipe_to_delete.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('SwipeToDelete', () {
    testWidgets('renders child widget', (tester) async {
      await pumpApp(
        tester,
        SwipeToDelete(
          dismissKey: const ValueKey('test-1'),
          onDismissed: () {},
          child: const ListTile(title: Text('Test Item')),
        ),
      );

      expect(find.text('Test Item'), findsOneWidget);
    });

    testWidgets('wraps child in Dismissible', (tester) async {
      await pumpApp(
        tester,
        SwipeToDelete(
          dismissKey: const ValueKey('test-2'),
          onDismissed: () {},
          child: const ListTile(title: Text('Dismissible Test')),
        ),
      );

      expect(find.byType(Dismissible), findsOneWidget);
    });

    testWidgets('calls onDismissed when swiped', (tester) async {
      var dismissed = false;
      await pumpApp(
        tester,
        SwipeToDelete(
          dismissKey: const ValueKey('test-3'),
          onDismissed: () => dismissed = true,
          child: const SizedBox(width: 200, height: 50, child: Text('Swipe me')),
        ),
      );

      // Swipe right to left
      await tester.drag(find.text('Swipe me'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(dismissed, true);
    });

    testWidgets('shows red background with delete icon on swipe', (tester) async {
      await pumpApp(
        tester,
        SwipeToDelete(
          dismissKey: const ValueKey('test-4'),
          onDismissed: () {},
          child: const SizedBox(width: 200, height: 50, child: Text('Swipe')),
        ),
      );

      // Start swiping to reveal background
      await tester.drag(find.text('Swipe'), const Offset(-100, 0));
      await tester.pump();

      expect(find.byIcon(Icons.delete), findsOneWidget);
    });
  });
}
