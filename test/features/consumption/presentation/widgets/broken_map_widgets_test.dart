import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/broken_map_belief.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/broken_map_widgets.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
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

    testWidgets('renders "verified" copy when confidence < 0.4', (tester) async {
      await pumpApp(
        tester,
        const BrokenMapOverlayRow(),
        overrides: [
          ..._belief(const BrokenMapBelief(
            confidence: 0.05,
            observationCount: 2,
          )),
        ],
      );
      expect(find.byKey(const Key('brokenMapOverlayRow')), findsOneWidget);
      expect(find.textContaining('verified'), findsOneWidget);
      expect(find.textContaining('0.05'), findsOneWidget);
    });

    testWidgets('renders "verifying" copy when 0.4 <= confidence < 0.7',
        (tester) async {
      await pumpApp(
        tester,
        const BrokenMapOverlayRow(),
        overrides: [
          ..._belief(const BrokenMapBelief(
            confidence: 0.43,
            observationCount: 2,
          )),
        ],
      );
      expect(find.byKey(const Key('brokenMapOverlayRow')), findsOneWidget);
      expect(find.textContaining('verifying'), findsOneWidget);
      expect(find.textContaining('0.43'), findsOneWidget);
    });

    testWidgets('renders "suspicious" copy when confidence >= 0.7',
        (tester) async {
      await pumpApp(
        tester,
        const BrokenMapOverlayRow(),
        overrides: [
          ..._belief(const BrokenMapBelief(
            confidence: 0.92,
            observationCount: 5,
          )),
        ],
      );
      expect(find.byKey(const Key('brokenMapOverlayRow')), findsOneWidget);
      expect(find.textContaining('suspicious'), findsOneWidget);
      expect(find.textContaining('0.92'), findsOneWidget);
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
    testWidgets('hidden when confidence is in the warning band (0.85)',
        (tester) async {
      await pumpApp(
        tester,
        const BrokenMapBanner(),
        overrides: [
          ..._belief(const BrokenMapBelief(
            confidence: 0.85,
            observationCount: 6,
          )),
        ],
      );
      expect(find.byKey(const Key('brokenMapBanner')), findsNothing);
    });

    testWidgets('rendered when confidence is at or above 0.9', (tester) async {
      await pumpApp(
        tester,
        const BrokenMapBanner(),
        overrides: [
          ..._belief(const BrokenMapBelief(
            confidence: 0.92,
            observationCount: 8,
          )),
        ],
      );
      expect(find.byKey(const Key('brokenMapBanner')), findsOneWidget);
    });
  });

  group('BrokenMapDisclaimerChip (#1423 phase 5)', () {
    testWidgets('hidden when confidence < 0.7', (tester) async {
      await pumpApp(
        tester,
        const BrokenMapDisclaimerChip(),
        overrides: [
          ..._belief(const BrokenMapBelief(
            confidence: 0.5,
            observationCount: 3,
          )),
        ],
      );
      expect(find.byKey(const Key('brokenMapDisclaimerChip')), findsNothing);
    });

    testWidgets('visible in the 0.7-0.9 band', (tester) async {
      await pumpApp(
        tester,
        const BrokenMapDisclaimerChip(),
        overrides: [
          ..._belief(const BrokenMapBelief(
            confidence: 0.78,
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
      await pumpApp(
        tester,
        const BrokenMapDisclaimerChip(),
        overrides: [
          ..._belief(const BrokenMapBelief(
            confidence: 0.94,
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
