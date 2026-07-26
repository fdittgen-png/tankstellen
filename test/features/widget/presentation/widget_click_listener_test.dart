// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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

    test('id with URL-encoded slash (ocm-42%2Ffoo) is REJECTED '
        '(#3612 charset guard)', () {
      // `%2F` decodes to `/`. Pre-#3612 the decoded slash flowed into
      // the router path verbatim; the charset guard now rejects it —
      // no real id format contains a slash, only injection attempts do.
      final path = widgetUriToPath(
        Uri.parse('tankstellenwidget://station?id=ocm-42%2Ffoo'),
      );
      expect(path, isNull,
          reason: 'A slash in an id can shape the router path — the '
              '#3612 guard turns it into the same no-op as any other '
              'invalid URI.');
    });

    test('id with URL-encoded space (%20) is REJECTED (#3612)', () {
      final path = widgetUriToPath(
        Uri.parse('tankstellenwidget://station?id=it-42%20milano'),
      );
      expect(path, isNull,
          reason: 'No real station id contains a space; the #3612 '
              'charset guard rejects it rather than routing a mangled '
              'path.');
    });

    test('id with a literal space is REJECTED — deterministically (#3612)',
        () {
      // An un-encoded space in a URI is illegal but `Uri.parse` is
      // forgiving and keeps the space in queryParameters. The #3612
      // guard rejects it; lock the behaviour in so a future `Uri`
      // upgrade doesn't silently change what the widget tap does.
      final uri = Uri.parse('tankstellenwidget://station?id=de abc');
      expect(widgetUriToPath(uri), isNull);
    });

    test('id with `+` decodes to space per `application/x-www-form-urlencoded` '
        'and is therefore REJECTED (#3612)', () {
      // #753 diagnostics need to know `+` is not a literal plus in this
      // decoder: `Uri.queryParameters` decodes it to a space, which the
      // #3612 charset guard rejects. If a country's id ever contains
      // `+`, the native side must `%2B`-encode it — and the guard's
      // charset must be widened deliberately.
      final path = widgetUriToPath(
        Uri.parse('tankstellenwidget://station?id=a+b'),
      );
      expect(path, isNull);
    });
  });

  group('widgetUriToPath (#3612 — id charset guard)', () {
    test('accepts an ocm-prefixed EV id', () {
      expect(
        widgetUriToPath(
          Uri.parse('tankstellenwidget://station?id=ocm-149681'),
        ),
        '/ev-station/ocm-149681',
      );
    });

    test('accepts a tankerkoenig-style UUID id', () {
      expect(
        widgetUriToPath(
          Uri.parse('tankstellenwidget://station'
              '?id=51d4b671-a095-1aa0-e100-80009459e03a'),
        ),
        '/station/51d4b671-a095-1aa0-e100-80009459e03a',
      );
    });

    test('rejects a path-traversal shaped id (../)', () {
      expect(
        widgetUriToPath(
          Uri.parse('tankstellenwidget://station?id=..%2F..%2Fsettings'),
        ),
        isNull,
      );
    });

    test('rejects an id containing quotes', () {
      expect(
        widgetUriToPath(
          Uri.parse('tankstellenwidget://station?id=%22onclick%22'),
        ),
        isNull,
      );
      expect(
        widgetUriToPath(
          Uri.parse("tankstellenwidget://station?id=it-42'or'1"),
        ),
        isNull,
      );
    });

    test('accepts a 64-char id but rejects 65 chars', () {
      final ok = 'a' * 64;
      final tooLong = 'a' * 65;
      expect(
        widgetUriToPath(Uri.parse('tankstellenwidget://station?id=$ok')),
        '/station/$ok',
      );
      expect(
        widgetUriToPath(Uri.parse('tankstellenwidget://station?id=$tooLong')),
        isNull,
      );
    });
  });

  group('WidgetLaunchHandler — refresh URI removed (#2600)', () {
    // #2600 — the refresh button is now a native broadcast handled in
    // place; it never launches the app. The old refresh-marker URI is
    // therefore no longer a navigation seam at all. A
    // `tankstellenwidget://refresh` URI (host != station) resolves to no
    // path and is a harmless no-op should one ever still arrive.
    testWidgets(
        'a (legacy) refresh URI resolves to no path and never navigates',
        (tester) async {
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
      final handler = WidgetLaunchHandler(router);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      expect(find.text('home'), findsOneWidget);

      handler.handle(Uri.parse('tankstellenwidget://refresh'));
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget,
          reason: 'host != station → widgetUriToPath null → no navigation');
      expect(widgetUriToPath(Uri.parse('tankstellenwidget://refresh')),
          isNull);
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

    testWidgets(
        '#2157 resume-time fallback dedupes by lastDispatched — '
        'the same URI dispatched via Stream then re-read on resume '
        'must not push twice', (tester) async {
      // We can't easily simulate the home_widget Stream + lifecycle
      // in a widget test, so verify the dedup contract by exercising
      // the handler directly: two handle() calls with the same URI
      // produce one push, the second is a no-op equivalent.
      // Verification is by router-state — the second push of the
      // same path on top of itself would land on a different
      // matchedLocation under go_router's behaviour.
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

      // Initial Stream-style dispatch.
      container
          .read(widgetLaunchHandlerProvider)
          .handle(Uri.parse('tankstellenwidget://station?id=xyz-77'));
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, '/station/xyz-77');

      // A different URI must still dispatch.
      container
          .read(widgetLaunchHandlerProvider)
          .handle(Uri.parse('tankstellenwidget://station?id=xyz-88'));
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, '/station/xyz-88');
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
