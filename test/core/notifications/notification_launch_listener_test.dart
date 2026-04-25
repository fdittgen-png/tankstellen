import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/app/router.dart';
import 'package:tankstellen/core/notifications/notification_launch_listener.dart';
import 'package:tankstellen/core/notifications/notification_payload.dart';

void main() {
  group('NotificationLaunchHandler (#1012 phase 3 — payload routing)', () {
    testWidgets(
        'handle() pushes /station/:id when payload is a valid radius alert',
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
        ],
      );

      final container = ProviderContainer(
        overrides: [routerProvider.overrideWith((_) => router)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      expect(find.text('home'), findsOneWidget);

      const payload = NotificationPayload(
        kind: NotificationPayload.kindRadius,
        stationId: 'de-001',
        country: 'de',
      );
      container
          .read(notificationLaunchHandlerProvider)
          .handle(payload.encode());
      await tester.pumpAndSettle();

      expect(landedOn, '/station/de-001');
      expect(find.text('station de-001'), findsOneWidget);
    });

    testWidgets('null payload is a no-op — stays on home', (tester) async {
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
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      container.read(notificationLaunchHandlerProvider).handle(null);
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
      expect(find.text('station'), findsNothing);
    });

    testWidgets('malformed payload is a no-op — stays on home',
        (tester) async {
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
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      // Looks JSON-ish but missing required keys — must not crash and
      // must not route the user anywhere unexpected.
      container
          .read(notificationLaunchHandlerProvider)
          .handle('{"unrelated":"junk"}');
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
      expect(find.text('station'), findsNothing);
    });

    testWidgets('unknown kind is a no-op — protects forward compat',
        (tester) async {
      // A future notification kind reaches an older app version. The
      // resolver returns null and the handler must degrade cleanly.
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
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      const future = NotificationPayload(
        kind: 'price_drop_v2',
        stationId: 'shell-456',
        country: 'de',
      );
      container
          .read(notificationLaunchHandlerProvider)
          .handle(future.encode());
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
      expect(find.text('station'), findsNothing);
    });
  });
}
