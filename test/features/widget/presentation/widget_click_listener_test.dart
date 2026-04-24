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

  group('widgetUriToPath (#753 — URI encoding edge cases)', () {
    // Every station id that reaches the URI builder on the Kotlin side
    // gets interpolated raw via `Uri.parse("tankstellenwidget://station?
    // id=$stationId")`. If an id ever contains characters that Uri's
    // query parser treats specially (`&`, `=`, `%xx`, spaces), the
    // decoded `queryParameters['id']` can silently differ from the
    // original. These cases lock in the exact behaviour so any future
    // regression (e.g. a country whose ids contain `&`) produces a test
    // failure rather than a wrong-station tap.

    test('id containing `&` — Uri query parser splits at the ampersand, '
        'the resulting path uses only the pre-`&` portion', () {
      // When the native side builds `...?id=foo&bar`, `Uri.parse`
      // treats `&bar` as a separate parameter — the `id` query value is
      // just `foo`. This pins that behaviour so #753 follow-up can
      // decide whether to encode ampersands on the Kotlin side.
      final path = widgetUriToPath(
        Uri.parse('tankstellenwidget://station?id=foo&bar'),
      );
      expect(path, '/station/foo',
          reason: 'Unencoded `&` in an id truncates it — documenting '
              'the exact current behaviour so a future encoding fix '
              'trips this test and forces a review.');
    });

    test('id with URL-encoded slash (ocm-42%2Ffoo) round-trips to '
        'the decoded form', () {
      // `%2F` decodes to `/`. The router path will contain a `/`, which
      // downstream GoRoute parsing may treat as a path separator — but
      // THAT is the router's concern. Here we only assert the id is
      // passed through as decoded by `queryParameters`.
      final path = widgetUriToPath(
        Uri.parse('tankstellenwidget://station?id=ocm-42%2Ffoo'),
      );
      expect(path, '/ev-station/ocm-42/foo',
          reason: 'Encoded slash decodes to a literal slash in the id, '
              'which then becomes part of the router path. If the '
              'router rejects that, the user sees a no-op instead of a '
              'wrong station — acceptable trade-off.');
    });

    test('id with URL-encoded space (%20) round-trips to literal space', () {
      final path = widgetUriToPath(
        Uri.parse('tankstellenwidget://station?id=it-42%20milano'),
      );
      expect(path, '/station/it-42 milano',
          reason: 'Space-in-id is a pathological but legal input; the '
              'decoder should pass it through unchanged so the router '
              'decides what to do — rather than silently mangling it '
              'into a different id.');
    });

    test('id with a literal space — Uri parse treats as separator; '
        'behaviour must be deterministic (not random across runs)', () {
      // An un-encoded space in a URI is illegal but `Uri.parse` is
      // forgiving. Behaviour is deterministic across Dart VM runs;
      // lock it in so a future `Uri` upgrade doesn't silently change
      // what the widget tap does.
      final uri = Uri.parse('tankstellenwidget://station?id=de abc');
      final path = widgetUriToPath(uri);
      // Dart's Uri parser keeps the space as-is in queryParameters.
      expect(path, '/station/de abc');
    });

    test('id with `+` decodes to space per `application/x-www-form-urlencoded` '
        '(form-encoded query — the exact behaviour of Uri.queryParameters)',
        () {
      // Not the bug, but #753 diagnostics need to know `+` is not a
      // literal plus in this decoder. If a country's id ever contains
      // `+`, the native side must `%2B`-encode it or the Flutter side
      // will see a space.
      final path = widgetUriToPath(
        Uri.parse('tankstellenwidget://station?id=a+b'),
      );
      expect(path, '/station/a b',
          reason: 'Uri.queryParameters decodes `+` as space. A real id '
              'containing `+` must be pre-encoded as `%2B` on the '
              'Kotlin side or the app will open a sibling station.');
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

    testWidgets(
        'two consecutive handle() calls with different ids — second wins, '
        'no stale router state (#753 — rapid-tap regression guard)',
        (tester) async {
      // If the second tap ever resolved to the first station (e.g. a
      // lingering setState or a cached path), #753 would reproduce in
      // isolation. This locks the rapid-tap ordering so a future
      // refactor of `WidgetLaunchHandler` cannot silently introduce a
      // race.
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Text('home')),
          GoRoute(
            path: '/station/:id',
            builder: (_, state) =>
                Text('station ${state.pathParameters['id']}'),
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

      final handler = container.read(widgetLaunchHandlerProvider);
      handler.handle(Uri.parse('tankstellenwidget://station?id=first'));
      await tester.pumpAndSettle();
      // Router has /station/first on top of the stack.
      expect(router.state.matchedLocation, '/station/first');

      handler.handle(Uri.parse('tankstellenwidget://station?id=second'));
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, '/station/second',
          reason: 'Second handle() must win — if this ever fails, the '
              'widget would open the previously-tapped station instead '
              'of the one the user just tapped. #753 in isolation.');
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
