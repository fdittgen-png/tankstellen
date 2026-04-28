import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/app/routes/invalid_id_screen.dart';

Widget _wrap(String path) {
  return MaterialApp(
    home: Builder(builder: (ctx) => invalidIdScreen(ctx, path)),
  );
}

void main() {
  group('invalidIdScreen', () {
    testWidgets('renders AppBar with "Invalid link" title', (tester) async {
      await tester.pumpWidget(_wrap('foo'));

      expect(find.byType(AppBar), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Invalid link'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders the link_off icon', (tester) async {
      await tester.pumpWidget(_wrap('foo'));

      expect(find.byIcon(Icons.link_off), findsOneWidget);
    });

    testWidgets('renders the path interpolated in the body', (tester) async {
      await tester.pumpWidget(_wrap('station/foo123'));

      expect(
        find.text('The link "station/foo123" is not valid.'),
        findsOneWidget,
      );
    });

    testWidgets('renders a Home FilledButton', (tester) async {
      await tester.pumpWidget(_wrap('foo'));

      expect(find.byType(FilledButton), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.text('Home'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping Home navigates to /', (tester) async {
      final router = GoRouter(
        initialLocation: '/invalid',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                const Scaffold(key: Key('homeScreen'), body: Text('Home page')),
          ),
          GoRoute(
            path: '/invalid',
            builder: (ctx, _) => invalidIdScreen(ctx, 'station/abc'),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      // Sanity: started on the invalid screen.
      expect(find.text('The link "station/abc" is not valid.'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Home'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('homeScreen')), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        '/',
      );
    });
  });
}
