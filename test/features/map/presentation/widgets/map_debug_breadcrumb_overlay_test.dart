import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/providers/app_state_provider.dart';
import 'package:tankstellen/features/map/presentation/widgets/map_debug_breadcrumb_overlay.dart';
import 'package:tankstellen/features/map/providers/map_breadcrumb_provider.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('MapDebugBreadcrumbOverlay (#1316 phase 2)', () {
    testWidgets(
      'hidden when mapDebugOverlayProvider is false (release path)',
      (tester) async {
        if (kDebugMode) {
          // The kDebugMode-OR-flag visibility means in debug builds the
          // overlay is always on; this assertion only makes sense in
          // release-mode CI. Skip locally so devs can still run the
          // suite without spurious failures.
          return;
        }
        await pumpApp(
          tester,
          const Stack(children: [MapDebugBreadcrumbOverlay()]),
          overrides: [
            mapDebugOverlayProvider.overrideWith(() => _FixedOverlay(false)),
          ],
        );
        // The overlay's outer Material chrome must NOT be in the tree
        // when the flag is off; SizedBox.shrink leaves nothing visible.
        expect(find.text('Map breadcrumbs'), findsNothing);
      },
    );

    testWidgets('visible when mapDebugOverlayProvider is true', (tester) async {
      await pumpApp(
        tester,
        const Stack(children: [MapDebugBreadcrumbOverlay()]),
        overrides: [
          mapDebugOverlayProvider.overrideWith(() => _FixedOverlay(true)),
        ],
      );
      expect(find.text('Map breadcrumbs'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('renders breadcrumbs from the notifier', (tester) async {
      await pumpApp(
        tester,
        const Stack(children: [MapDebugBreadcrumbOverlay()]),
        overrides: [
          mapDebugOverlayProvider.overrideWith(() => _FixedOverlay(true)),
        ],
      );

      // Push a few breadcrumbs and rebuild.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MapDebugBreadcrumbOverlay)),
      );
      container.read(mapBreadcrumbsProvider.notifier)
        ..record('map-cold-start', 'first crumb')
        ..record('map-incarn', 'second crumb');
      await tester.pump();

      expect(find.textContaining('first crumb'), findsOneWidget);
      expect(find.textContaining('second crumb'), findsOneWidget);
      expect(find.textContaining('[map-cold-start]'), findsOneWidget);
      expect(find.textContaining('[map-incarn]'), findsOneWidget);
    });

    testWidgets('Clear empties the breadcrumb list', (tester) async {
      await pumpApp(
        tester,
        const Stack(children: [MapDebugBreadcrumbOverlay()]),
        overrides: [
          mapDebugOverlayProvider.overrideWith(() => _FixedOverlay(true)),
        ],
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MapDebugBreadcrumbOverlay)),
      );
      container.read(mapBreadcrumbsProvider.notifier)
        ..record('a', 'one')
        ..record('b', 'two');
      await tester.pump();
      expect(find.textContaining('one'), findsOneWidget);

      await tester.tap(find.text('Clear'));
      await tester.pump();

      expect(find.textContaining('one'), findsNothing);
      expect(find.textContaining('two'), findsNothing);
      expect(container.read(mapBreadcrumbsProvider), isEmpty);
    });

    testWidgets('Close disables the overlay flag', (tester) async {
      await pumpApp(
        tester,
        const Stack(children: [MapDebugBreadcrumbOverlay()]),
        overrides: [
          mapDebugOverlayProvider.overrideWith(() => _MutableOverlay(true)),
        ],
      );

      expect(find.text('Map breadcrumbs'), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MapDebugBreadcrumbOverlay)),
      );

      await tester.tap(find.text('Close'));
      await tester.pump();

      // The flag must be off. In `kDebugMode` the overlay still shows
      // (debug-mode auto-on path); release-mode hides. Either way the
      // provider must report `false`.
      expect(container.read(mapDebugOverlayProvider), isFalse);
    });
  });
}

/// Notifier override that returns a fixed bool — used for hidden /
/// visible variants where the test does not need to mutate state.
class _FixedOverlay extends MapDebugOverlay {
  _FixedOverlay(this._value);
  final bool _value;
  @override
  bool build() => _value;
}

/// Notifier override that supports the `disable()` action while
/// starting from a known initial state. Mirrors the production
/// behaviour without touching real Hive storage.
class _MutableOverlay extends MapDebugOverlay {
  _MutableOverlay(this._initial);
  final bool _initial;

  @override
  bool build() => _initial;

  @override
  Future<void> enable() async {
    state = true;
  }

  @override
  Future<void> disable() async {
    state = false;
  }

  @override
  Future<void> toggle() async {
    state = !state;
  }
}

