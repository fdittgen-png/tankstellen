import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart'
    as v1;
import 'package:tankstellen/features/feature_management/v2/feature_gate.dart';
import 'package:tankstellen/features/feature_management/v2/known_features.dart';

/// Widget-level coverage for FeatureGate / FeatureGateBuilder. Pumps a
/// minimal MaterialApp around the gate so the effective-flags
/// provider has a Riverpod scope to read from.
class _TestFeatureFlags extends FeatureFlags {
  _TestFeatureFlags(this._initial);
  final Set<v1.Feature> _initial;

  @override
  Set<v1.Feature> build() => {..._initial};
}

void main() {
  Future<void> pump(
    WidgetTester tester,
    Set<v1.Feature> enabled,
    Widget child,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          featureFlagsProvider.overrideWith(() => _TestFeatureFlags(enabled)),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('FeatureGate', () {
    testWidgets('renders child when feature is effectively enabled',
        (tester) async {
      await pump(
        tester,
        {v1.Feature.priceHistory},
        const FeatureGate(
          feature: kFeaturePriceHistory,
          child: Text('GATED-CONTENT'),
        ),
      );
      expect(find.text('GATED-CONTENT'), findsOneWidget);
    });

    testWidgets('renders fallback (SizedBox.shrink by default) when off',
        (tester) async {
      await pump(
        tester,
        const <v1.Feature>{},
        const FeatureGate(
          feature: kFeaturePriceHistory,
          child: Text('GATED-CONTENT'),
        ),
      );
      expect(find.text('GATED-CONTENT'), findsNothing);
    });

    testWidgets('renders custom fallback when provided', (tester) async {
      await pump(
        tester,
        const <v1.Feature>{},
        const FeatureGate(
          feature: kFeaturePriceHistory,
          fallback: Text('FALLBACK'),
          child: Text('GATED-CONTENT'),
        ),
      );
      expect(find.text('GATED-CONTENT'), findsNothing);
      expect(find.text('FALLBACK'), findsOneWidget);
    });

    testWidgets('respects requires cascade — child off when parent off',
        (tester) async {
      // Enable gamification but not its required parent
      // (obd2TripRecording). The gate should hide the child.
      await pump(
        tester,
        {v1.Feature.gamification},
        const FeatureGate(
          feature: kFeatureGamification,
          child: Text('GAMIFICATION-UI'),
        ),
      );
      expect(find.text('GAMIFICATION-UI'), findsNothing);
    });

    testWidgets('renders child when both child + required parent are on',
        (tester) async {
      await pump(
        tester,
        {v1.Feature.gamification, v1.Feature.obd2TripRecording},
        const FeatureGate(
          feature: kFeatureGamification,
          child: Text('GAMIFICATION-UI'),
        ),
      );
      expect(find.text('GAMIFICATION-UI'), findsOneWidget);
    });
  });

  group('FeatureGateBuilder', () {
    testWidgets('only invokes builder when feature is enabled',
        (tester) async {
      var builderCalls = 0;
      await pump(
        tester,
        const <v1.Feature>{},
        FeatureGateBuilder(
          feature: kFeaturePriceHistory,
          builder: (_) {
            builderCalls++;
            return const Text('EXPENSIVE');
          },
        ),
      );
      expect(builderCalls, 0,
          reason: 'builder must not run when feature is off — that is the '
              'reason to use FeatureGateBuilder over FeatureGate');
      expect(find.text('EXPENSIVE'), findsNothing);
    });

    testWidgets('invokes builder when feature is enabled', (tester) async {
      var builderCalls = 0;
      await pump(
        tester,
        {v1.Feature.priceHistory},
        FeatureGateBuilder(
          feature: kFeaturePriceHistory,
          builder: (_) {
            builderCalls++;
            return const Text('EXPENSIVE');
          },
        ),
      );
      expect(builderCalls, 1);
      expect(find.text('EXPENSIVE'), findsOneWidget);
    });
  });
}
