// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/consumption/data/obd2/broken_map_belief.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd_adapter_blocklist.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/broken_map_widgets.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/pump_app.dart';

/// Widget tests for the broken-MAP UI surfaces (#1423 phase 5):
/// - [BrokenMapOverlayRow]: hidden when no observation, "verified"
///   below 0.4, "verifying" 0.4-0.7, "suspicious" >= 0.7
/// - [BrokenMapBanner]: hidden until confidence >= 0.9
/// - [BrokenMapDisclaimerChip]: visible only in 0.7-0.9 band
void main() {
  group('BrokenMapOverlayRow (#1423 phase 5)', () {
    testWidgets('hidden when active vehicle has no observation', (tester) async {
      await pumpApp(
        tester,
        const BrokenMapOverlayRow(),
        overrides: [
          ..._belief(const BrokenMapBelief()),
        ],
      );
      expect(find.byKey(const Key('brokenMapOverlayRow')), findsNothing);
    });

    testWidgets('renders posterior + ± margin in the silent band (#1424 G)',
        (tester) async {
      // α=1, β=19 → mean = 0.05.
      await pumpApp(
        tester,
        const BrokenMapOverlayRow(),
        overrides: [
          ..._belief(const BrokenMapBelief(
            alpha: 1,
            beta: 19,
            observationCount: 2,
          )),
        ],
      );
      expect(find.byKey(const Key('brokenMapOverlayRow')), findsOneWidget);
      expect(find.textContaining('5%'), findsOneWidget);
      expect(find.textContaining('±'), findsOneWidget);
      // Not yet at the auto-clear gate (observationCount = 2 ≤ 50) so
      // the (verified) badge must NOT appear.
      expect(find.textContaining('verified'), findsNothing);
    });

    testWidgets('renders (verified) badge once isVerifiedClean fires',
        (tester) async {
      // 60 obs, α=5 β=95 → satisfies the auto-clear gate.
      await pumpApp(
        tester,
        const BrokenMapOverlayRow(),
        overrides: [
          ..._belief(const BrokenMapBelief(
            alpha: 5,
            beta: 95,
            observationCount: 60,
          )),
        ],
      );
      expect(find.byKey(const Key('brokenMapOverlayRow')), findsOneWidget);
      expect(find.textContaining('verified'), findsOneWidget);
    });

    testWidgets('renders posterior + ± margin in the verifying band',
        (tester) async {
      // α=4.3 β=5 → mean ≈ 0.46 (verifying band).
      await pumpApp(
        tester,
        const BrokenMapOverlayRow(),
        overrides: [
          ..._belief(const BrokenMapBelief(
            alpha: 4.3,
            beta: 5,
            observationCount: 2,
          )),
        ],
      );
      expect(find.byKey(const Key('brokenMapOverlayRow')), findsOneWidget);
      expect(find.textContaining('±'), findsOneWidget);
      expect(find.textContaining('46%'), findsOneWidget);
    });

    testWidgets('renders posterior + ± margin in the warning/hardDisable band',
        (tester) async {
      // α=92 β=8 → mean = 0.92 (hard-disable band).
      await pumpApp(
        tester,
        const BrokenMapOverlayRow(),
        overrides: [
          ..._belief(const BrokenMapBelief(
            alpha: 92,
            beta: 8,
            observationCount: 5,
          )),
        ],
      );
      expect(find.byKey(const Key('brokenMapOverlayRow')), findsOneWidget);
      expect(find.textContaining('92%'), findsOneWidget);
      expect(find.textContaining('±'), findsOneWidget);
    });

    testWidgets('hidden when no active vehicle is set', (tester) async {
      await pumpApp(
        tester,
        const BrokenMapOverlayRow(),
        overrides: [
          activeVehicleProfileProvider
              .overrideWith(() => _NullActiveVehicle()),
        ],
      );
      expect(find.byKey(const Key('brokenMapOverlayRow')), findsNothing);
    });
  });

  group('BrokenMapBanner (#1423 phase 5)', () {
    testWidgets('hidden when posterior is in the warning band (~0.85)',
        (tester) async {
      // mean = 17/20 = 0.85 (warning band, NOT hard-disable).
      await pumpApp(
        tester,
        const BrokenMapBanner(),
        overrides: [
          ..._belief(const BrokenMapBelief(
            alpha: 17,
            beta: 3,
            observationCount: 6,
          )),
        ],
      );
      expect(find.byKey(const Key('brokenMapBanner')), findsNothing);
    });

    testWidgets('rendered when posterior is at or above 0.9', (tester) async {
      // mean = 92/100 = 0.92 (hard-disable).
      await pumpApp(
        tester,
        const BrokenMapBanner(),
        overrides: [
          ..._belief(const BrokenMapBelief(
            alpha: 92,
            beta: 8,
            observationCount: 8,
          )),
        ],
      );
      expect(find.byKey(const Key('brokenMapBanner')), findsOneWidget);
    });
  });

  group('BrokenMapDisclaimerChip (#1423 phase 5)', () {
    testWidgets('hidden when posterior < 0.7', (tester) async {
      // mean = 5/10 = 0.5.
      await pumpApp(
        tester,
        const BrokenMapDisclaimerChip(),
        overrides: [
          ..._belief(const BrokenMapBelief(
            alpha: 5,
            beta: 5,
            observationCount: 3,
          )),
        ],
      );
      expect(find.byKey(const Key('brokenMapDisclaimerChip')), findsNothing);
    });

    testWidgets('visible in the 0.7-0.9 band', (tester) async {
      // mean = 78/100 = 0.78.
      await pumpApp(
        tester,
        const BrokenMapDisclaimerChip(),
        overrides: [
          ..._belief(const BrokenMapBelief(
            alpha: 78,
            beta: 22,
            observationCount: 4,
          )),
        ],
      );
      expect(
        find.byKey(const Key('brokenMapDisclaimerChip')),
        findsOneWidget,
      );
    });

    testWidgets('hidden again at hard-disable (>=0.9)', (tester) async {
      // mean = 94/100 = 0.94.
      await pumpApp(
        tester,
        const BrokenMapDisclaimerChip(),
        overrides: [
          ..._belief(const BrokenMapBelief(
            alpha: 94,
            beta: 6,
            observationCount: 9,
          )),
        ],
      );
      expect(find.byKey(const Key('brokenMapDisclaimerChip')), findsNothing);
    });
  });

  group('brokenMapBandFor (#1423 phase 5)', () {
    test('thresholds match the spec', () {
      expect(brokenMapBandFor(0.0), BrokenMapBand.silent);
      expect(brokenMapBandFor(0.39), BrokenMapBand.silent);
      expect(brokenMapBandFor(0.4), BrokenMapBand.verifying);
      expect(brokenMapBandFor(0.69), BrokenMapBand.verifying);
      expect(brokenMapBandFor(0.7), BrokenMapBand.warning);
      expect(brokenMapBandFor(0.89), BrokenMapBand.warning);
      expect(brokenMapBandFor(0.9), BrokenMapBand.hardDisable);
      expect(brokenMapBandFor(1.0), BrokenMapBand.hardDisable);
    });
  });

  // #1622 — broken-MAP belief + adapter-blocklist diagnostics card.
  group('BrokenMapDiagnosticsCard (#1622)', () {
    testWidgets(
        'hidden when the vehicle has no observations and the blocklist '
        'is empty', (tester) async {
      final blocklist = ObdAdapterBlocklist(_FakeSettingsStorage());
      await pumpApp(
        tester,
        const BrokenMapDiagnosticsCard(),
        overrides: [
          obdAdapterBlocklistProvider.overrideWithValue(blocklist),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('MAP sensor diagnostics'), findsNothing);
    });

    testWidgets('renders blocklisted adapters with a Clear button',
        (tester) async {
      final blocklist = ObdAdapterBlocklist(_FakeSettingsStorage());
      await blocklist.recordBelief('ELM327 v2.1', 0.85);

      await pumpApp(
        tester,
        const BrokenMapDiagnosticsCard(),
        overrides: [
          obdAdapterBlocklistProvider.overrideWithValue(blocklist),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('ELM327 v2.1'), findsOneWidget);
      expect(
        find.byKey(const Key('brokenMapBlocklistClear_ELM327 v2.1')),
        findsOneWidget,
      );
    });

    testWidgets('tapping Clear removes the adapter from the blocklist',
        (tester) async {
      final blocklist = ObdAdapterBlocklist(_FakeSettingsStorage());
      await blocklist.recordBelief('ELM327 v2.1', 0.85);

      await pumpApp(
        tester,
        const BrokenMapDiagnosticsCard(),
        overrides: [
          obdAdapterBlocklistProvider.overrideWithValue(blocklist),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('ELM327 v2.1'), findsOneWidget);

      await tester.tap(
          find.byKey(const Key('brokenMapBlocklistClear_ELM327 v2.1')));
      await tester.pumpAndSettle();

      // The row is gone, and the underlying blocklist no longer
      // recalls the adapter.
      expect(find.textContaining('ELM327 v2.1'), findsNothing);
      expect(await blocklist.recall('ELM327 v2.1'), isNull);
    });

    testWidgets('renders the belief line when the vehicle has observations',
        (tester) async {
      // α=8, β=2 → point estimate 0.8.
      final blocklist = ObdAdapterBlocklist(_FakeSettingsStorage());
      await pumpApp(
        tester,
        const BrokenMapDiagnosticsCard(vehicleId: 'veh-a'),
        overrides: [
          brokenMapBeliefByVehicleProvider.overrideWith(
            () => _FixedBeliefByVehicle({
              'veh-a': const BrokenMapBelief(
                alpha: 8,
                beta: 2,
                observationCount: 6,
              ),
            }),
          ),
          obdAdapterBlocklistProvider.overrideWithValue(blocklist),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('MAP sensor diagnostics'), findsOneWidget);
      expect(find.textContaining('80%'), findsOneWidget);
      expect(find.textContaining('6 observations'), findsOneWidget);
    });
  });
}

/// Build the override list for a fixed [BrokenMapBelief] under the
/// veh-a vehicle id so the widget reads it back via the
/// `activeVehicleProfileProvider` + `brokenMapBeliefByVehicleProvider`
/// duo. Mirrors how the production trip-recording screen wires them.
List<Override> _belief(BrokenMapBelief belief) => [
      activeVehicleProfileProvider
          .overrideWith(() => _FixedActiveVehicle('veh-a')),
      brokenMapBeliefByVehicleProvider.overrideWith(
        () => _FixedBeliefByVehicle({'veh-a': belief}),
      ),
    ];

/// In-memory [SettingsStorage] double — backs the [ObdAdapterBlocklist]
/// in the diagnostics-card tests so `entries()` / `clearEntry()` run
/// against real blocklist logic (#1622).
class _FakeSettingsStorage implements SettingsStorage {
  final Map<String, dynamic> data = {};

  @override
  dynamic getSetting(String key) => data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    data[key] = value;
  }

  @override
  bool get isSetupComplete => false;
  @override
  bool get isSetupSkipped => false;
  @override
  Future<void> skipSetup() async {}
  @override
  Future<void> resetSetupSkip() async {}
}

class _FixedBeliefByVehicle extends BrokenMapBeliefByVehicle {
  _FixedBeliefByVehicle(this._initial);
  final Map<String, BrokenMapBelief> _initial;

  @override
  Map<String, BrokenMapBelief> build() => _initial;
}

class _FixedActiveVehicle extends ActiveVehicleProfile {
  _FixedActiveVehicle(this._activeId);
  final String _activeId;

  @override
  VehicleProfile? build() =>
      VehicleProfile(id: _activeId, name: 'Test');
}

class _NullActiveVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() => null;
}
