import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/app/router.dart';
import 'package:tankstellen/features/widget/presentation/widget_click_listener.dart';

void main() {
  group('widgetUriToPath (#587 widget → detail)', () {
    test('fuel station id → /station/:id', () {
      expect(
        widgetUriToPath(Uri.parse('tankstellenwidget://station?id=abc123')),
        '/station/abc123',
      );
    });

    test('OCM-prefixed id → /ev-station/:id', () {
      expect(
        widgetUriToPath(Uri.parse('tankstellenwidget://station?id=ocm-42')),
        '/ev-station/ocm-42',
      );
    });

    test('null uri → null', () {
      expect(widgetUriToPath(null), isNull);
    });

    test('wrong scheme → null', () {
      expect(
        widgetUriToPath(Uri.parse('https://station?id=abc')),
        isNull,
      );
    });

    test('wrong host → null', () {
      expect(
        widgetUriToPath(Uri.parse('tankstellenwidget://unknown?id=abc')),
        isNull,
      );
    });

    test('missing id → null', () {
      expect(
        widgetUriToPath(Uri.parse('tankstellenwidget://station')),
        isNull,
      );
    });

    test('empty id → null', () {
      expect(
        widgetUriToPath(Uri.parse('tankstellenwidget://station?id=')),
        isNull,
      );
    });
  });

  group('WidgetLaunchHandler (#587 widget → detail)', () {
    testWidgets(
        'handle() pushes /station/:id onto the real router when called from '
        'MaterialApp.router builder context (the exact layer that was silently '
        'broken before — GoRouter.of(context) threw from above InheritedGoRouter)',
        (tester) async {
      String? landedOn;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Text('home')),
          GoRoute(
            path: '/station/:id',
            builder: (_, state) {
              landedOn = '/station/${state.pathParameters['id']}';
              return Text('station ${state.pathParameters['id']}');
            },
          ),
          GoRoute(
            path: '/ev-station/:id',
            builder: (_, state) {
              landedOn = '/ev-station/${state.pathParameters['id']}';
              return Text('ev ${state.pathParameters['id']}');
            },
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [routerProvider.overrideWith((_) => router)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            builder: (context, child) => WidgetClickListener(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      );
      expect(find.text('home'), findsOneWidget);

      container
          .read(widgetLaunchHandlerProvider)
          .handle(Uri.parse('tankstellenwidget://station?id=abc123'));
      await tester.pumpAndSettle();

      expect(landedOn, '/station/abc123');
      expect(find.text('station abc123'), findsOneWidget);
    });

    testWidgets('OCM id routes to /ev-station/:id', (tester) async {
      String? landedOn;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Text('home')),
          GoRoute(
            path: '/station/:id',
            builder: (_, state) {
              landedOn = '/station/${state.pathParameters['id']}';
              return const Text('station');
            },
          ),
          GoRoute(
            path: '/ev-station/:id',
            builder: (_, state) {
              landedOn = '/ev-station/${state.pathParameters['id']}';
              return Text('ev ${state.pathParameters['id']}');
            },
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [routerProvider.overrideWith((_) => router)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            builder: (context, child) => WidgetClickListener(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      );

      container
          .read(widgetLaunchHandlerProvider)
          .handle(Uri.parse('tankstellenwidget://station?id=ocm-42'));
      await tester.pumpAndSettle();

      expect(landedOn, '/ev-station/ocm-42');
      expect(find.text('ev ocm-42'), findsOneWidget);
    });

    testWidgets('invalid URI is a no-op — stays on home', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Text('home')),
          GoRoute(
            path: '/station/:id',
            builder: (_, _) => const Text('station'),
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [routerProvider.overrideWith((_) => router)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            builder: (context, child) => WidgetClickListener(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      );

      container
          .read(widgetLaunchHandlerProvider)
          .handle(Uri.parse('https://example.com/foo'));
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
      expect(find.text('station'), findsNothing);
    });
  });
}
