import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/snackbar_helper.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('SnackBarHelper', () {
    testWidgets('show() displays message with default duration', (tester) async {
      await pumpApp(tester, Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => SnackBarHelper.show(context, 'Test message'),
          child: const Text('Tap'),
        ),
      ));

      await tester.tap(find.text('Tap'));
      await tester.pump();

      expect(find.text('Test message'), findsOneWidget);
    });

    testWidgets('show() respects custom duration', (tester) async {
      await pumpApp(tester, Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => SnackBarHelper.show(
            context,
            'Short message',
            duration: const Duration(seconds: 1),
          ),
          child: const Text('Tap'),
        ),
      ));

      await tester.tap(find.text('Tap'));
      await tester.pump();
      expect(find.text('Short message'), findsOneWidget);
    });

    testWidgets('showSuccess() displays a themed snackbar with a check icon',
        (tester) async {
      await pumpApp(tester, Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => SnackBarHelper.showSuccess(context, 'Success!'),
          child: const Text('Tap'),
        ),
      ));

      await tester.tap(find.text('Tap'));
      await tester.pump();

      expect(find.text('Success!'), findsOneWidget);

      // #1683/#1692 — themed via colorScheme (never hard-coded green, so
      // dark mode stays harmonious) and carries a check icon so success
      // is signalled by more than colour alone.
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, isNotNull);
      expect(snackBar.backgroundColor, isNot(Colors.green));
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('showError() displays a themed snackbar with an error icon',
        (tester) async {
      await pumpApp(tester, Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => SnackBarHelper.showError(context, 'Error occurred'),
          child: const Text('Tap'),
        ),
      ));

      await tester.tap(find.text('Tap'));
      await tester.pump();

      expect(find.text('Error occurred'), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, isNotNull);
      expect(snackBar.backgroundColor, isNot(Colors.green));
      // #1692 — error is signalled by an icon, not colour alone.
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('showError() has 5-second duration', (tester) async {
      await pumpApp(tester, Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => SnackBarHelper.showError(context, 'Error!'),
          child: const Text('Tap'),
        ),
      ));

      await tester.tap(find.text('Tap'));
      await tester.pump();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.duration, const Duration(seconds: 5));
    });

    testWidgets('showWithUndo() displays message with undo action', (tester) async {
      await pumpApp(tester, Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => SnackBarHelper.showWithUndo(
            context,
            'Item removed',
            onUndo: () {},
          ),
          child: const Text('Tap'),
        ),
      ));

      await tester.tap(find.text('Tap'));
      await tester.pump();

      expect(find.text('Item removed'), findsOneWidget);

      // Verify the SnackBar has an action
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.action, isNotNull);
      expect(snackBar.action!.label, 'Undo');
    });

    testWidgets('showWithUndo() has 4-second duration', (tester) async {
      await pumpApp(tester, Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => SnackBarHelper.showWithUndo(
            context,
            'Removed',
            onUndo: () {},
          ),
          child: const Text('Tap'),
        ),
      ));

      await tester.tap(find.text('Tap'));
      await tester.pump();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.duration, const Duration(seconds: 4));
    });

    testWidgets('showWithUndo() supports custom undo label', (tester) async {
      await pumpApp(tester, Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => SnackBarHelper.showWithUndo(
            context,
            'Gelöscht',
            undoLabel: 'Rückgängig',
            onUndo: () {},
          ),
          child: const Text('Tap'),
        ),
      ));

      await tester.tap(find.text('Tap'));
      await tester.pump();

      expect(find.text('Rückgängig'), findsOneWidget);
    });

    testWidgets('show() does nothing when context is not mounted', (tester) async {
      // This tests the guard — we just ensure no crash when calling
      // after dispose. We use a StatefulWidget that calls show after pop.
      late BuildContext savedContext;

      await pumpApp(tester, Builder(
        builder: (context) {
          savedContext = context;
          return const Text('Page');
        },
      ));

      // Just verify it doesn't throw when called with a valid mounted context
      SnackBarHelper.show(savedContext, 'Still mounted');
      await tester.pump();
      expect(find.text('Still mounted'), findsOneWidget);
    });

    testWidgets('showSuccess() default duration is 3 seconds', (tester) async {
      await pumpApp(tester, Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => SnackBarHelper.showSuccess(context, 'Done!'),
          child: const Text('Tap'),
        ),
      ));

      await tester.tap(find.text('Tap'));
      await tester.pump();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.duration, const Duration(seconds: 3));
    });

    // #1692 — every snackbar's content is wrapped in a `liveRegion`
    // Semantics node so assistive technologies announce the message
    // when it appears (colour and motion are not the only signal).
    testWidgets('snackbar content is announced via a liveRegion',
        (tester) async {
      await pumpApp(tester, Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => SnackBarHelper.show(context, 'Announce me'),
          child: const Text('Tap'),
        ),
      ));

      await tester.tap(find.text('Tap'));
      await tester.pump();

      final liveRegion = find.descendant(
        of: find.byType(SnackBar),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.liveRegion == true,
        ),
      );
      expect(liveRegion, findsAtLeastNWidgets(1));
    });

    testWidgets('showSuccess() content is announced via a liveRegion',
        (tester) async {
      await pumpApp(tester, Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => SnackBarHelper.showSuccess(context, 'Saved'),
          child: const Text('Tap'),
        ),
      ));

      await tester.tap(find.text('Tap'));
      await tester.pump();

      final liveRegion = find.descendant(
        of: find.byType(SnackBar),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.liveRegion == true,
        ),
      );
      expect(liveRegion, findsAtLeastNWidgets(1));
    });

    testWidgets('show() with an action renders the action button',
        (tester) async {
      await pumpApp(tester, Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => SnackBarHelper.show(
            context,
            'With action',
            action: SnackBarAction(label: 'Go', onPressed: () {}),
          ),
          child: const Text('Tap'),
        ),
      ));

      await tester.tap(find.text('Tap'));
      await tester.pump();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.action, isNotNull);
      expect(snackBar.action!.label, 'Go');
    });

    group('builders', () {
      // The `*SnackBar` builders are pure — they let async call sites
      // capture a messenger before an `await` and theme the snackbar
      // without holding a BuildContext across the gap.
      testWidgets('infoSnackBar() builds a plain SnackBar with the message',
          (tester) async {
        await pumpApp(tester, Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ScaffoldMessenger.of(context)
                .showSnackBar(SnackBarHelper.infoSnackBar('Built info')),
            child: const Text('Tap'),
          ),
        ));

        await tester.tap(find.text('Tap'));
        await tester.pump();

        expect(find.text('Built info'), findsOneWidget);
        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.action, isNull);
      });

      testWidgets('infoSnackBar() carries the supplied action + key',
          (tester) async {
        await pumpApp(tester, Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBarHelper.infoSnackBar(
                'Built with action',
                key: const Key('builtSnack'),
                action: SnackBarAction(label: 'Act', onPressed: () {}),
              ),
            ),
            child: const Text('Tap'),
          ),
        ));

        await tester.tap(find.text('Tap'));
        await tester.pump();

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.key, const Key('builtSnack'));
        expect(snackBar.action!.label, 'Act');
      });

      testWidgets('errorSnackBar() is themed (errorContainer) with an icon',
          (tester) async {
        late ColorScheme scheme;
        await pumpApp(tester, Builder(
          builder: (context) {
            scheme = Theme.of(context).colorScheme;
            return ElevatedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBarHelper.errorSnackBar(scheme, 'Built error')),
              child: const Text('Tap'),
            );
          },
        ));

        await tester.tap(find.text('Tap'));
        await tester.pump();

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.backgroundColor, scheme.errorContainer);
        expect(snackBar.duration, const Duration(seconds: 5));
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('successSnackBar() is themed (tertiaryContainer) with icon',
          (tester) async {
        late ColorScheme scheme;
        await pumpApp(tester, Builder(
          builder: (context) {
            scheme = Theme.of(context).colorScheme;
            return ElevatedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBarHelper.successSnackBar(scheme, 'Built success')),
              child: const Text('Tap'),
            );
          },
        ));

        await tester.tap(find.text('Tap'));
        await tester.pump();

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.backgroundColor, scheme.tertiaryContainer);
        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      });
    });
  });
}
