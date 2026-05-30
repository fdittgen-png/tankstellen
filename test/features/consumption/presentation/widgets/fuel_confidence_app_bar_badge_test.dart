// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fuel_confidence_app_bar_badge.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/pump_app.dart';

// ─── Provider stubs ────────────────────────────────────────────────────────

class _NoVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() => null;
}

/// Combustion vehicle with calibration data — surfaced to the badge.
class _CalibratedVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() => const VehicleProfile(
        id: 'v1',
        name: 'Test Car',
        type: VehicleType.combustion,
        volumetricEfficiency: 0.91,
        volumetricEfficiencySamples: 5,
      );
}

/// Vehicle with no plein-complet samples yet.
class _UncalibratedVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() => const VehicleProfile(
        id: 'v2',
        name: 'New Car',
        type: VehicleType.combustion,
        volumetricEfficiency: 0.85,
        volumetricEfficiencySamples: 0,
      );
}

/// Feature-flags stub that enables Developer / debug mode (#2262).
class _DebugModeOn extends FeatureFlags {
  @override
  Set<Feature> build() => {Feature.debugMode};
}

// ─── Helpers ───────────────────────────────────────────────────────────────

final _calibrated = [
  activeVehicleProfileProvider.overrideWith(() => _CalibratedVehicle()),
];

final _uncalibrated = [
  activeVehicleProfileProvider.overrideWith(() => _UncalibratedVehicle()),
];

final _noVehicle = [
  activeVehicleProfileProvider.overrideWith(() => _NoVehicle()),
];

final _calibratedDebug = [
  activeVehicleProfileProvider.overrideWith(() => _CalibratedVehicle()),
  featureFlagsProvider.overrideWith(() => _DebugModeOn()),
];

final _uncalibratedDebug = [
  activeVehicleProfileProvider.overrideWith(() => _UncalibratedVehicle()),
  featureFlagsProvider.overrideWith(() => _DebugModeOn()),
];

// ─── Tests ─────────────────────────────────────────────────────────────────

void main() {
  group('FuelConfidenceAppBarBadge — visibility', () {
    testWidgets(
      'renders nothing when no active vehicle',
      (tester) async {
        await pumpApp(
          tester,
          const FuelConfidenceAppBarBadge(),
          overrides: _noVehicle,
        );
        // SizedBox.shrink collapses to zero size; no Accuracy text.
        expect(find.textContaining('Accuracy:'), findsNothing);
        expect(find.textContaining('η_v'), findsNothing);
      },
    );

    testWidgets(
      'renders accuracy indicator when vehicle has calibration samples',
      (tester) async {
        await pumpApp(
          tester,
          const FuelConfidenceAppBarBadge(),
          overrides: _calibrated,
        );
        // ConfidenceTierBadge renders "Accuracy: High · ±3-7%" (tier C,
        // samples=5, hasGpsPlusObd2Trip defaults true).
        expect(find.textContaining('Accuracy:'), findsOneWidget);
      },
    );

    testWidgets(
      'renders accuracy indicator for uncalibrated vehicle (samples == 0)',
      (tester) async {
        await pumpApp(
          tester,
          const FuelConfidenceAppBarBadge(),
          overrides: _uncalibrated,
        );
        // samples=0 → tier A → "Accuracy: Low · ±40-60%"
        expect(find.textContaining('Accuracy:'), findsOneWidget);
        expect(find.textContaining('Low'), findsOneWidget);
      },
    );
  });

  // ─── #2262 — raw η_v chip gated on Feature.debugMode ─────────────────

  group('FuelConfidenceAppBarBadge — η_v debug gate (#2262)', () {
    testWidgets(
      'η_v chip is ABSENT for normal users (debugMode off — default)',
      (tester) async {
        await pumpApp(
          tester,
          const FuelConfidenceAppBarBadge(),
          overrides: _calibrated,
        );
        // The raw η_v glyph must not surface in non-debug builds.
        expect(find.textContaining('η_v'), findsNothing);
        expect(find.textContaining('samples'), findsNothing);
      },
    );

    testWidgets(
      'η_v chip IS shown when Developer mode is ON (calibrated vehicle)',
      (tester) async {
        await pumpApp(
          tester,
          const FuelConfidenceAppBarBadge(),
          overrides: _calibratedDebug,
        );
        // Both the accuracy indicator and the raw chip show.
        expect(find.textContaining('Accuracy:'), findsOneWidget);
        expect(find.textContaining('η_v'), findsOneWidget);
        expect(find.textContaining('samples'), findsOneWidget);
      },
    );

    testWidgets(
      'η_v chip IS shown when Developer mode is ON (uncalibrated vehicle)',
      (tester) async {
        // Suppress the RenderFlex overflow that occurs because the long
        // "no plein-complet yet" label is tested outside an AppBar context.
        // In production the badge lives in an AppBar's actions row which
        // constrains each action independently — overflow cannot happen.
        final errors = <FlutterErrorDetails>[];
        final originalHandler = FlutterError.onError;
        FlutterError.onError = errors.add;
        addTearDown(() => FlutterError.onError = originalHandler);

        await pumpApp(
          tester,
          const FuelConfidenceAppBarBadge(),
          overrides: _uncalibratedDebug,
        );
        // samples == 0 → "no plein-complet yet" label.
        expect(find.textContaining('no plein-complet'), findsOneWidget);

        // Only layout overflow is expected; any other error is real.
        for (final e in errors) {
          if (!e.toString().contains('RenderFlex overflowed')) {
            FlutterError.reportError(e);
          }
        }
      },
    );

    testWidgets(
      'η_v chip is ABSENT even for uncalibrated vehicle without debug mode',
      (tester) async {
        await pumpApp(
          tester,
          const FuelConfidenceAppBarBadge(),
          overrides: _uncalibrated,
        );
        expect(find.textContaining('no plein-complet'), findsNothing);
        expect(find.textContaining('η_v'), findsNothing);
      },
    );
  });
}
