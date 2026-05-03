import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/providers/app_state_provider.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_breadcrumb_collector.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/obd2_breadcrumb_overlay.dart';
import 'package:tankstellen/features/consumption/providers/obd2_breadcrumb_provider.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('Obd2BreadcrumbOverlay (#1395)', () {
    testWidgets(
      'hidden when obd2DebugOverlayProvider is false (release path)',
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
          const Stack(children: [Obd2BreadcrumbOverlay()]),
          overrides: [
            obd2DebugOverlayProvider.overrideWith(() => _FixedOverlay(false)),
          ],
        );
        // The overlay's outer Material chrome must NOT be in the tree
        // when the flag is off; SizedBox.shrink leaves nothing visible.
        expect(find.text('OBD2 breadcrumbs'), findsNothing);
      },
    );

    testWidgets('visible when obd2DebugOverlayProvider is true', (tester) async {
      await pumpApp(
        tester,
        const Stack(children: [Obd2BreadcrumbOverlay()]),
        overrides: [
          obd2DebugOverlayProvider.overrideWith(() => _FixedOverlay(true)),
        ],
      );
      expect(find.text('OBD2 breadcrumbs'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('renders breadcrumbs from the notifier', (tester) async {
      await pumpApp(
        tester,
        const Stack(children: [Obd2BreadcrumbOverlay()]),
        overrides: [
          obd2DebugOverlayProvider.overrideWith(() => _FixedOverlay(true)),
        ],
      );

      // Push a few breadcrumbs and rebuild.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Obd2BreadcrumbOverlay)),
      );
      container.read(obd2BreadcrumbsProvider.notifier)
        ..record(
          branch: Obd2BranchTag.pid5E,
          fuelRateLPerHour: 4.20,
          rpm: 2200,
          afr: 14.7,
          fuelDensityGPerL: 745,
          engineDisplacementCc: 1500,
          volumetricEfficiency: 0.85,
        )
        ..record(
          branch: Obd2BranchTag.maf,
          fuelRateLPerHour: 3.39,
          mafGramsPerSecond: 10.24,
          afr: 14.7,
          fuelDensityGPerL: 745,
          engineDisplacementCc: 1500,
          volumetricEfficiency: 0.85,
        );
      await tester.pump();

      // The overlay renders one row per breadcrumb. Each row shows the
      // branch tag in brackets ([5E] / [MAF]) so the user can group
      // by tier.
      expect(find.textContaining('[5E]'), findsOneWidget);
      expect(find.textContaining('[MAF]'), findsOneWidget);
      expect(find.textContaining('4.20 L/h'), findsOneWidget);
      expect(find.textContaining('3.39 L/h'), findsOneWidget);
    });

    testWidgets('Clear empties the breadcrumb list', (tester) async {
      await pumpApp(
        tester,
        const Stack(children: [Obd2BreadcrumbOverlay()]),
        overrides: [
          obd2DebugOverlayProvider.overrideWith(() => _FixedOverlay(true)),
        ],
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(Obd2BreadcrumbOverlay)),
      );
      container.read(obd2BreadcrumbsProvider.notifier)
        ..record(branch: Obd2BranchTag.pid5E, fuelRateLPerHour: 4.20)
        ..record(branch: Obd2BranchTag.maf, fuelRateLPerHour: 3.39);
      await tester.pump();
      expect(find.textContaining('4.20 L/h'), findsOneWidget);

      await tester.tap(find.text('Clear'));
      await tester.pump();

      expect(find.textContaining('4.20 L/h'), findsNothing);
      expect(find.textContaining('3.39 L/h'), findsNothing);
      expect(container.read(obd2BreadcrumbsProvider), isEmpty);
    });

    testWidgets('Close disables the overlay flag', (tester) async {
      await pumpApp(
        tester,
        const Stack(children: [Obd2BreadcrumbOverlay()]),
        overrides: [
          obd2DebugOverlayProvider.overrideWith(() => _MutableOverlay(true)),
        ],
      );

      expect(find.text('OBD2 breadcrumbs'), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Obd2BreadcrumbOverlay)),
      );

      await tester.tap(find.text('Close'));
      await tester.pump();

      // The flag must be off. In `kDebugMode` the overlay still shows
      // (debug-mode auto-on path); release-mode hides. Either way the
      // provider must report `false`.
      expect(container.read(obd2DebugOverlayProvider), isFalse);
    });
  });
}

/// Notifier override that returns a fixed bool — used for hidden /
/// visible variants where the test does not need to mutate state.
class _FixedOverlay extends Obd2DebugOverlay {
  _FixedOverlay(this._value);
  final bool _value;
  @override
  bool build() => _value;
}

/// Notifier override that supports the `disable()` action while
/// starting from a known initial state. Mirrors the production
/// behaviour without touching real Hive storage.
class _MutableOverlay extends Obd2DebugOverlay {
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
