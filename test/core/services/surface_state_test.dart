// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/surface_state.dart';
import 'package:tankstellen/core/services/widgets/service_status_banner.dart';

import '../../helpers/pump_app.dart';

/// #4134 — one model for how well a surface is currently working.
void main() {
  final at = DateTime.utc(2026, 9, 13, 12);

  ServiceResult<int> result({
    bool stale = false,
    List<ServiceError> errors = const [],
  }) =>
      ServiceResult<int>(
        data: 1,
        source: ServiceSource.cache,
        fetchedAt: at,
        isStale: stale,
        errors: errors,
      );

  group('the verdict', () {
    test('everything worked is full', () {
      expect(surfaceStateOf(result()), SurfaceState.full);
    });

    test('a fallback was used is degraded', () {
      expect(
        surfaceStateOf(result(errors: [
          ServiceError(
            source: ServiceSource.tankerkoenigApi,
            message: 'down',
            occurredAt: at,
          ),
        ])),
        SurfaceState.degraded,
      );
    });

    test('serving what was already on the device is offline', () {
      expect(surfaceStateOf(result(stale: true)), SurfaceState.offline);
    });

    test('stale wins over a fallback', () {
      // Both true: the user is looking at old data, which is the more
      // important thing to say.
      expect(
        surfaceStateOf(result(stale: true, errors: [
          ServiceError(
            source: ServiceSource.tankerkoenigApi,
            message: 'down',
            occurredAt: at,
          ),
        ])),
        SurfaceState.offline,
      );
    });
  });

  group('how it looks', () {
    testWidgets('full paints nothing — silence is the healthy state',
        (tester) async {
      await pumpApp(tester, ServiceStatusBanner(result: result()));
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('NEITHER degraded nor offline uses the error palette',
        (tester) async {
      // The banner used to paint offline in `errorContainer`. Cached
      // prices with no network are the app doing its job under worse
      // conditions; telling the user something broke when nothing did
      // spends the error colour on a state that needs no decision.
      for (final state in [SurfaceState.degraded, SurfaceState.offline]) {
        await pumpApp(tester, Builder(builder: (context) {
          final style = SurfaceStateStyle.of(context, state)!;
          final scheme = Theme.of(context).colorScheme;
          expect(style.background, isNot(scheme.errorContainer),
              reason: '$state must not read as an error');
          expect(style.background, isNot(scheme.error));
          return const SizedBox.shrink();
        }));
      }
    });

    testWidgets('the two states are visually distinct', (tester) async {
      await pumpApp(tester, Builder(builder: (context) {
        expect(
          SurfaceStateStyle.of(context, SurfaceState.degraded)!.background,
          isNot(SurfaceStateStyle.of(context, SurfaceState.offline)!.background),
        );
        return const SizedBox.shrink();
      }));
    });
  });
}
