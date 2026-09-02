// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/pump_gain_chip.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/pump_app.dart';

/// [PumpGainChip] (#3901) — the pump-anchored calibration pill that
/// replaced the η_v learner chip on the consumption card.
class _FixedActiveVehicle extends ActiveVehicleProfile {
  _FixedActiveVehicle(this._profile);
  final VehicleProfile? _profile;

  @override
  VehicleProfile? build() => _profile;
}

void main() {
  group('PumpGainChipView', () {
    test('correctionPercent is |1 − gain| in whole percent', () {
      expect(PumpGainChipView.correctionPercent(1.0), 0);
      expect(PumpGainChipView.correctionPercent(0.93), 7);
      expect(PumpGainChipView.correctionPercent(1.126), 13);
    });

    testWidgets('samples == 0 → neutral "not pump-calibrated yet"',
        (tester) async {
      await pumpApp(
        tester,
        const PumpGainChipView(pumpGain: 1.0, samples: 0),
      );
      expect(find.text('Not pump-calibrated yet'), findsOneWidget);
      expect(find.textContaining('η_v'), findsNothing);
    });

    testWidgets('samples > 0 → "Pump-calibrated · N fill-ups · ±x %"',
        (tester) async {
      await pumpApp(
        tester,
        const PumpGainChipView(pumpGain: 0.93, samples: 6),
      );
      expect(find.text('Pump-calibrated · 6 fill-ups · ±7 %'), findsOneWidget);
    });

    testWidgets('one sample uses the singular form', (tester) async {
      await pumpApp(
        tester,
        const PumpGainChipView(pumpGain: 1.05, samples: 1),
      );
      expect(find.text('Pump-calibrated · 1 fill-up · ±5 %'), findsOneWidget);
    });
  });

  group('PumpGainChip (provider-backed)', () {
    testWidgets('reads the active vehicle\'s pump gain', (tester) async {
      await pumpApp(
        tester,
        const PumpGainChip(),
        overrides: [
          activeVehicleProfileProvider.overrideWith(
            () => _FixedActiveVehicle(
              const VehicleProfile(
                id: 'v1',
                name: 'Polo',
                pumpGain: 0.9,
                pumpGainSamples: 3,
              ),
            ),
          ),
        ],
      );
      expect(find.text('Pump-calibrated · 3 fill-ups · ±10 %'), findsOneWidget);
    });

    testWidgets('no active vehicle → not calibrated', (tester) async {
      await pumpApp(
        tester,
        const PumpGainChip(),
        overrides: [
          activeVehicleProfileProvider
              .overrideWith(() => _FixedActiveVehicle(null)),
        ],
      );
      expect(find.text('Not pump-calibrated yet'), findsOneWidget);
    });
  });
}
