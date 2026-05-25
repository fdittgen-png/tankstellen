// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_recording_controller.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/presentation/screens/add_fill_up_screen.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fill_up_numeric_field.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/consumption/providers/current_obd2_fuel_level_provider.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for the OBD2-fuel-level capture wiring on
/// [AddFillUpScreen] (#1434).
///
/// The screen calls [currentObd2FuelLevelLitresProvider] twice:
///   1. In `initState` → cached as `_fuelLevelBeforeL`
///   2. In `_save` → captured as `fuelLevelAfterL`
///
/// Both values are stamped onto the persisted [FillUp] so the
/// verified-by-adapter badge (#1430) and the variance prompt fire in
/// production. These tests pin that contract end-to-end through the
/// real screen and a fake [FillUpList] that captures what `add` was
/// invoked with.

const _stubVehicle = VehicleProfile(
  id: 'stub-vehicle',
  name: 'Stub Car',
  type: VehicleType.combustion,
  tankCapacityL: 50,
);

class _StubVehicleList extends VehicleProfileList {
  @override
  List<VehicleProfile> build() => const [_stubVehicle];
}

/// Stub `ActiveVehicleProfile` so the fuel-level provider's
/// `tankCapacityL` lookup doesn't fall through to Hive (which the
/// widget-test environment doesn't initialise).
class _StubActiveVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() => _stubVehicle;
}

/// Captures every fill-up handed to `add` so the test can inspect
/// the OBD2 fields. We deliberately bypass the production `add`
/// pipeline (repo, calibration, link-window) — those have their own
/// coverage; this test pins only the screen-side capture contract.
class _CapturingFillUpList extends FillUpList {
  final List<FillUp> captured = [];

  @override
  List<FillUp> build() => const [];

  @override
  Future<void> add(FillUp fillUp) async {
    captured.add(fillUp);
  }
}

/// Manual trip-recording fake — same pattern as the eco-coach tests.
/// We pin `state` directly so the test stays free of OBD2 / Hive
/// setup.
class _ManualTripRecording extends TripRecording {
  _ManualTripRecording(this._initial);
  final TripRecordingState _initial;

  @override
  TripRecordingState build() => _initial;
}

/// A minimal go_router-driven scaffold: pushes `AddFillUpScreen` as a
/// child route so `context.pop()` inside `_save` resolves cleanly. The
/// initial route is a launcher button that pushes the form, so the
/// pop after save returns to the launcher rather than throwing
/// "tried to pop the root navigator".
Future<void> pumpAddFillUpInRouter(
  WidgetTester tester, {
  required List<Object> overrides,
  AddFillUpScreen? screen,
}) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => ctx.push('/add'),
                child: const Text('open-form'),
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/add',
        builder: (context, state) => screen ?? const AddFillUpScreen(),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides.cast(),
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open-form'));
  await tester.pumpAndSettle();
}

Finder _fieldByLabel(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byType(FillUpNumericField),
    );

void _typeInto(WidgetTester tester, String label, String value) {
  final fieldFinder = find.descendant(
    of: _fieldByLabel(label),
    matching: find.byType(TextField),
  );
  final field = tester.widget<TextField>(fieldFinder);
  field.controller!.text = value;
}

TripRecordingState _recordingWithPercent(double percent) {
  return TripRecordingState(
    phase: TripRecordingPhase.recording,
    live: TripLiveReading(
      fuelLevelPercent: percent,
      distanceKmSoFar: 0,
      elapsed: const Duration(seconds: 1),
    ),
  );
}

Future<void> _fillFormAndSave(WidgetTester tester) async {
  _typeInto(tester, 'Liters', '40');
  _typeInto(tester, 'Total cost', '70');
  _typeInto(tester, 'Odometer (km)', '12345');
  await tester.pump();
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

void main() {
  group('AddFillUpScreen — OBD2 fuel-level capture (#1434)', () {
    testWidgets(
        'persists the provider value as fuelLevelBeforeL/After when active',
        (tester) async {
      // 75 % × 50 L = 37.5 L. The provider snapshots the same value
      // both at initState and at save (no state change in between in
      // this test), so before == after — that's fine for this contract:
      // we only need to prove BOTH fields land on the FillUp non-null.
      // The sibling test below pins the no-OBD2 case where both stay
      // null, which is the actual differential.
      final fillUpList = _CapturingFillUpList();
      await pumpAddFillUpInRouter(
        tester,
        overrides: [
          vehicleProfileListProvider.overrideWith(() => _StubVehicleList()),
          activeVehicleProfileProvider
              .overrideWith(() => _StubActiveVehicle()),
          tripRecordingProvider.overrideWith(
              () => _ManualTripRecording(_recordingWithPercent(75))),
          fillUpListProvider.overrideWith(() => fillUpList),
        ],
      );

      await _fillFormAndSave(tester);

      expect(fillUpList.captured, hasLength(1));
      final saved = fillUpList.captured.single;
      expect(saved.fuelLevelBeforeL, closeTo(37.5, 0.001));
      expect(saved.fuelLevelAfterL, closeTo(37.5, 0.001));
      // User-entered fields survive untouched.
      expect(saved.liters, closeTo(40, 0.001));
      expect(saved.totalCost, closeTo(70, 0.001));
    });

    testWidgets(
        'leaves fuelLevelBeforeL/After null when no trip is recording',
        (tester) async {
      // Idle phase → provider returns null both at initState and at
      // save. The persisted FillUp must keep the legacy "user-entered
      // only" shape so the variance prompt skips itself
      // (FillUpVariance.hasAdapterCapture returns false) and the
      // verified-by-adapter badge stays hidden.
      final fillUpList = _CapturingFillUpList();
      await pumpAddFillUpInRouter(
        tester,
        overrides: [
          vehicleProfileListProvider.overrideWith(() => _StubVehicleList()),
          tripRecordingProvider.overrideWith(
              () => _ManualTripRecording(const TripRecordingState())),
          fillUpListProvider.overrideWith(() => fillUpList),
        ],
      );

      await _fillFormAndSave(tester);

      expect(fillUpList.captured, hasLength(1));
      final saved = fillUpList.captured.single;
      expect(saved.fuelLevelBeforeL, isNull);
      expect(saved.fuelLevelAfterL, isNull);
    });

    testWidgets(
        'widget seam initialFuelLevelBeforeL/After takes precedence over '
        'the live provider value', (tester) async {
      // Pre-existing test seam (#1401 phase 7b). The provider would
      // yield 37.5 L (75 % × 50 L) but the test seam pins 15.0 / 55.0
      // — those values must reach the FillUp untouched so widget tests
      // can exercise the verified-by-adapter path deterministically
      // without a live OBD2 chain. delta = 40 L matches the user-typed
      // 40 L exactly, so the variance prompt does NOT fire.
      final fillUpList = _CapturingFillUpList();
      await pumpAddFillUpInRouter(
        tester,
        overrides: [
          vehicleProfileListProvider.overrideWith(() => _StubVehicleList()),
          activeVehicleProfileProvider
              .overrideWith(() => _StubActiveVehicle()),
          tripRecordingProvider.overrideWith(
              () => _ManualTripRecording(_recordingWithPercent(75))),
          fillUpListProvider.overrideWith(() => fillUpList),
        ],
        screen: const AddFillUpScreen(
          initialFuelLevelBeforeL: 15.0,
          initialFuelLevelAfterL: 55.0,
        ),
      );

      await _fillFormAndSave(tester);

      expect(fillUpList.captured, hasLength(1));
      final saved = fillUpList.captured.single;
      expect(saved.fuelLevelBeforeL, 15.0);
      expect(saved.fuelLevelAfterL, 55.0);
    });
  });
}
