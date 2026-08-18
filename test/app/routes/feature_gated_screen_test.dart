// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/app/routes/feature_gated_screen.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/feature_management/domain/feature_manifest.dart';

/// A [FeatureFlags] notifier whose enabled set is the manifest default
/// minus [_disabled] — the same test double the #1638 gate tests use.
class _FlagsWithout extends FeatureFlags {
  _FlagsWithout(this._disabled);

  final Set<Feature> _disabled;

  @override
  Set<Feature> build() =>
      FeatureManifest.defaultManifest.defaultEnabledSet().difference(_disabled);
}

void main() {
  group('FeatureGatedScreen', () {
    Future<GoRouter> pumpWithRouter(
      WidgetTester tester, {
      required Set<Feature> disabled,
    }) async {
      final router = GoRouter(
        initialLocation: '/gated',
        routes: [
          GoRoute(
            path: '/fallback',
            builder: (_, _) => const Text('fallback screen'),
          ),
          GoRoute(
            path: '/gated',
            builder: (_, _) => const FeatureGatedScreen(
              feature: Feature.priceAlerts,
              fallbackPath: '/fallback',
              child: Text('gated screen'),
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            featureFlagsProvider.overrideWith(() => _FlagsWithout(disabled)),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      return router;
    }

    testWidgets('renders the child when the feature is enabled (default)',
        (tester) async {
      await pumpWithRouter(tester, disabled: const {});
      await tester.pumpAndSettle();
      expect(find.text('gated screen'), findsOneWidget);
      expect(find.text('fallback screen'), findsNothing);
    });

    testWidgets(
        'redirects a deep link to the fallback when the feature is disabled',
        (tester) async {
      await pumpWithRouter(tester, disabled: {Feature.priceAlerts});
      await tester.pumpAndSettle();
      expect(find.text('gated screen'), findsNothing);
      expect(find.text('fallback screen'), findsOneWidget);
    });
  });
}
