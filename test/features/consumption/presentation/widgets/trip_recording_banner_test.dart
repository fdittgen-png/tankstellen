// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/core/services/approach_detector.dart';
import 'package:tankstellen/core/theme/contrast_utils.dart';
import 'package:tankstellen/core/theme/fuel_colors.dart';
import 'package:tankstellen/features/approach/providers/effective_approach_state_provider.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_recording_controller.dart';
import 'package:tankstellen/features/consumption/domain/cold_start_baselines.dart';
import 'package:tankstellen/features/consumption/domain/situation_classifier.dart';
import 'package:tankstellen/app/router.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_recording_banner.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_recording_pip_view.dart';
import 'package:tankstellen/features/consumption/providers/pip_mode_provider.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/profile/providers/effective_fuel_type_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/pump_app.dart';

/// Fake notifier lets tests pin the banner to an exact state without
/// spinning up an Obd2Service + controller + streams.
class _FakeTripRecording extends TripRecording {
  final TripRecordingState _initial;
  _FakeTripRecording(this._initial);

  @override
  TripRecordingState build() => _initial;
}

/// Fake [PipMode] notifier — pins the app's PiP-mode flag for a test.
class _FakePipMode extends PipMode {
  final bool _value;
  _FakePipMode(this._value);

  @override
  bool build() => _value;
}

TripRecordingState _activeState({
  ConsumptionBand band = ConsumptionBand.normal,
  DrivingSituation situation = DrivingSituation.highwayCruise,
  double? delta,
  double? distance,
  double? speedKmh,
  double? fuelRateLPerHour,
  double? gpsEstimatedLPer100Km,
}) {
  return TripRecordingState(
    phase: TripRecordingPhase.recording,
    situation: situation,
    band: band,
    liveDeltaFraction: delta,
    live: distance == null
        ? null
        : TripLiveReading(
            distanceKmSoFar: distance,
            elapsed: const Duration(minutes: 1),
            speedKmh: speedKmh,
            fuelRateLPerHour: fuelRateLPerHour,
            gpsEstimatedLPer100Km: gpsEstimatedLPer100Km,
          ),
  );
}

void main() {
  group('TripRecordingBanner a11y (#767)', () {
    testWidgets('idle state: no banner rendered — Semantics empty',
        (tester) async {
      await pumpApp(
        tester,
        const TripRecordingBanner(child: SizedBox(key: Key('child'))),
      );
      expect(find.byKey(const Key('tripRecordingBanner')), findsNothing);
      expect(find.byKey(const Key('child')), findsOneWidget);
    });

    testWidgets('active state exposes a single merged Semantics node '
        'with a TalkBack-readable label — separate per-chip labels '
        'would narrate as a stream of numbers and be unusable',
        (tester) async {
      await pumpApp(
        tester,
        const TripRecordingBanner(child: SizedBox()),
        overrides: [
          tripRecordingProvider.overrideWith(
            () => _FakeTripRecording(_activeState(
              band: ConsumptionBand.heavy,
              delta: 0.08,
              distance: 5.2,
            )),
          ),
        ],
      );

      final handle = tester.ensureSemantics();
      final labels = tester
          .getSemantics(find.byKey(const Key('tripRecordingBanner')).first)
          .getSemanticsData()
          .label;
      expect(labels, contains('Recording trip'));
      expect(labels, contains('Highway'));
      expect(labels, contains('+8%'));
      expect(labels, contains('5.2 km'));
      handle.dispose();
    });

    testWidgets('paused state reads as "Trip paused" — consumption '
        'band on a paused reading would mislead',
        (tester) async {
      await pumpApp(
        tester,
        const TripRecordingBanner(child: SizedBox()),
        overrides: [
          tripRecordingProvider.overrideWith(
            () => _FakeTripRecording(const TripRecordingState(
              phase: TripRecordingPhase.paused,
              situation: DrivingSituation.highwayCruise,
              band: ConsumptionBand.heavy,
            )),
          ),
        ],
      );

      final handle = tester.ensureSemantics();
      final label = tester
          .getSemantics(find.byKey(const Key('tripRecordingBanner')).first)
          .getSemanticsData()
          .label;
      expect(label, contains('paused'));
      expect(label, isNot(contains('Highway')));
      expect(label, isNot(contains('%')));
      handle.dispose();
    });

    testWidgets('negative delta renders without a leading + so '
        'TalkBack announces "minus 8 percent" not "plus minus 8"',
        (tester) async {
      await pumpApp(
        tester,
        const TripRecordingBanner(child: SizedBox()),
        overrides: [
          tripRecordingProvider.overrideWith(
            () => _FakeTripRecording(_activeState(
              band: ConsumptionBand.eco,
              delta: -0.12,
            )),
          ),
        ],
      );

      final handle = tester.ensureSemantics();
      final label = tester
          .getSemantics(find.byKey(const Key('tripRecordingBanner')).first)
          .getSemanticsData()
          .label;
      expect(label, contains('-12%'));
      expect(label, isNot(contains('+-12%')));
      handle.dispose();
    });
  });

  // #1987 — TripRecordingBanner sits inside MaterialApp.builder, above
  // the Router/Navigator subtree, so `GoRouter.of(context)` cannot
  // resolve. It now navigates through the `routerProvider` instance;
  // verify the tap reliably opens /trip-recording.
  group('TripRecordingBanner tap → /trip-recording (#1987)', () {
    testWidgets(
        'tapping the recording banner pushes /trip-recording via '
        'routerProvider — no dependence on a context-resolvable GoRouter',
        (tester) async {
      final pushed = <String>[];
      final testRouter = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(
              body: TripRecordingBanner(child: SizedBox()),
            ),
          ),
          GoRoute(
            path: '/trip-recording',
            builder: (_, _) {
              pushed.add('/trip-recording');
              return const Scaffold(body: Text('trip-recording-screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tripRecordingProvider.overrideWith(
              () => _FakeTripRecording(_activeState(
                band: ConsumptionBand.normal,
                distance: 1.0,
              )),
            ),
            routerProvider.overrideWith((ref) => testRouter),
          ],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: testRouter,
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('tripRecordingBanner')), findsOneWidget);

      await tester.tap(find.byKey(const Key('tripRecordingBanner')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(pushed, contains('/trip-recording'));
      expect(find.text('trip-recording-screen'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('TripRecordingBanner PiP mode (#1977)', () {
    testWidgets(
        'in PiP mode renders only the compact tile — the shell child '
        '(which carries the bottom nav bar) is dropped', (tester) async {
      await pumpApp(
        tester,
        const TripRecordingBanner(child: SizedBox(key: Key('shell-child'))),
        overrides: [
          tripRecordingProvider.overrideWith(
            () => _FakeTripRecording(_activeState(distance: 4.0)),
          ),
          pipModeProvider.overrideWith(() => _FakePipMode(true)),
        ],
      );

      expect(find.byKey(const Key('shell-child')), findsNothing,
          reason: 'PiP must not render the shell — that is what dragged '
              'the button bar into the tile (#1977)');
      // The compact trip strip is still shown. With distance=4.0 +
      // no fuel rate + no estimate, #2601's consumption-framed warm-up
      // branch leads with the "~" placeholder under the est. L/100 km
      // caption and demotes the distance ("4.0 km") to the secondary
      // row. Finding the distance value is enough proof the tile
      // didn't collapse to nothing.
      expect(find.text('~'), findsOneWidget);
      expect(find.text('4.0 km'), findsOneWidget);
    });

    testWidgets('outside PiP mode the shell child renders as usual',
        (tester) async {
      await pumpApp(
        tester,
        const TripRecordingBanner(child: SizedBox(key: Key('shell-child'))),
        overrides: [
          tripRecordingProvider.overrideWith(
            () => _FakeTripRecording(_activeState(distance: 4.0)),
          ),
          pipModeProvider.overrideWith(() => _FakePipMode(false)),
        ],
      );

      expect(find.byKey(const Key('shell-child')), findsOneWidget);
    });
  });

  // #2382 — in approach mode the PiP tile adopts the FUEL TYPE's colour
  // (matching the hue the fuel wears elsewhere in the app) with a
  // WCAG-contrasting foreground. Outside approach mode it keeps the
  // driving-band palette.
  group('TripRecordingBanner approach-overlay fuel-type colour (#2382)', () {
    const station = Station(
      id: 's-1',
      name: 'Carrefour Pézenas',
      brand: 'Carrefour',
      street: '12 ROUTE DE BÉZIERS',
      postCode: '34120',
      place: 'Pézenas',
      lat: 43.46,
      lng: 3.42,
      e85: 1.099,
      isOpen: true,
    );

    TripRecordingPipView pipView(WidgetTester tester) =>
        tester.widget<TripRecordingPipView>(
          find.byType(TripRecordingPipView),
        );

    Future<void> pumpInApproach(
      WidgetTester tester, {
      required ApproachState approach,
      required FuelType fuel,
    }) {
      return pumpApp(
        tester,
        const TripRecordingBanner(child: SizedBox()),
        overrides: [
          tripRecordingProvider.overrideWith(
            () => _FakeTripRecording(_activeState(distance: 4.0)),
          ),
          pipModeProvider.overrideWith(() => _FakePipMode(true)),
          effectiveApproachStateProvider.overrideWithValue(approach),
          effectiveFuelTypeProvider.overrideWithValue(fuel),
        ],
      );
    }

    testWidgets('ApproachInRadius → background is the fuel type colour',
        (tester) async {
      const fuel = FuelType.e85;
      await pumpInApproach(
        tester,
        approach: const ApproachInRadius(
          station: station,
          distanceMeters: 350,
        ),
        fuel: fuel,
      );

      final view = pipView(tester);
      expect(view.backgroundColor, FuelColors.forType(fuel),
          reason: 'approach mode must paint the tile in the fuel hue');
      // Foreground must clear WCAG AA-large against the fuel background.
      expect(
        ContrastUtils.meetsAALarge(view.foregroundColor, view.backgroundColor),
        isTrue,
        reason: 'the huge price figure must stay legible on the fuel hue',
      );
    });

    testWidgets('a DIFFERENT fuel type yields its OWN colour', (tester) async {
      const fuel = FuelType.diesel;
      await pumpInApproach(
        tester,
        approach: const ApproachLeaving(lastStation: station),
        fuel: fuel,
      );
      expect(pipView(tester).backgroundColor, FuelColors.forType(fuel));
    });

    testWidgets('outside approach mode the band palette wins — NOT the fuel '
        'colour', (tester) async {
      await pumpApp(
        tester,
        const TripRecordingBanner(child: SizedBox()),
        overrides: [
          tripRecordingProvider.overrideWith(
            () => _FakeTripRecording(_activeState(
              band: ConsumptionBand.eco,
              distance: 4.0,
            )),
          ),
          pipModeProvider.overrideWith(() => _FakePipMode(true)),
          effectiveApproachStateProvider
              .overrideWithValue(const ApproachIdle()),
          effectiveFuelTypeProvider.overrideWithValue(FuelType.e85),
        ],
      );
      expect(
        pipView(tester).backgroundColor,
        isNot(FuelColors.forType(FuelType.e85)),
        reason: 'no approach → the driving-band palette must win',
      );
    });
  });

  // #2390 — the banner strip mirrors the PiP: on a GPS-only trajet the
  // consumption slot (normally OBD2-only) shows the live physics
  // estimate as "~X.X L/100"; OBD2 trips stay tilde-free; warm-up
  // (null estimate) leaves the slot silent.
  group('TripRecordingBanner GPS-only estimate strip (#2390)', () {
    testWidgets('GPS-only trip with an estimate → "~X.X L/100" in the strip',
        (tester) async {
      await pumpApp(
        tester,
        const TripRecordingBanner(child: SizedBox()),
        overrides: [
          tripRecordingProvider.overrideWith(
            () => _FakeTripRecording(_activeState(
              distance: 1.2,
              fuelRateLPerHour: null, // GPS-only: no OBD2 fuel rate
              gpsEstimatedLPer100Km: 6.4,
            )),
          ),
        ],
      );
      expect(find.text('~6.4 L/100'), findsOneWidget);
    });

    testWidgets('GPS-only estimate → approximate tooltip on the value (#2393)',
        (tester) async {
      await pumpApp(
        tester,
        const TripRecordingBanner(child: SizedBox()),
        overrides: [
          tripRecordingProvider.overrideWith(
            () => _FakeTripRecording(_activeState(
              distance: 1.2,
              fuelRateLPerHour: null,
              gpsEstimatedLPer100Km: 6.4,
            )),
          ),
        ],
      );
      // The estimate value is wrapped in a Tooltip carrying the
      // approximate-explanation message (long-press affordance).
      final tooltip = tester.widget<Tooltip>(
        find.ancestor(
          of: find.text('~6.4 L/100'),
          matching: find.byType(Tooltip),
        ),
      );
      expect(tooltip.message, isNotNull);
      expect(tooltip.message, contains('GPS'));
    });

    testWidgets(
        'GPS-only estimate → disclaimer folded into the banner a11y label '
        '(#2393)', (tester) async {
      await pumpApp(
        tester,
        const TripRecordingBanner(child: SizedBox()),
        overrides: [
          tripRecordingProvider.overrideWith(
            () => _FakeTripRecording(_activeState(
              distance: 1.2,
              fuelRateLPerHour: null,
              gpsEstimatedLPer100Km: 6.4,
            )),
          ),
        ],
      );
      final handle = tester.ensureSemantics();
      final label = tester
          .getSemantics(find.byKey(const Key('tripRecordingBanner')).first)
          .getSemanticsData()
          .label;
      // The outer Semantics label (content is ExcludeSemantics'd) carries
      // the estimate disclaimer so screen-reader users hear it.
      expect(label, contains('GPS'));
      handle.dispose();
    });

    testWidgets('OBD2 trip → real measured value, no "~"', (tester) async {
      await pumpApp(
        tester,
        const TripRecordingBanner(child: SizedBox()),
        overrides: [
          tripRecordingProvider.overrideWith(
            () => _FakeTripRecording(_activeState(
              distance: 1.2,
              speedKmh: 70,
              fuelRateLPerHour: 4.06, // OBD2 measured
              gpsEstimatedLPer100Km: 6.4, // present but must be ignored
            )),
          ),
        ],
      );
      // 4.06 L/h at 70 km/h → ~5.8 L/100, tilde-free.
      expect(find.text('5.8 L/100'), findsOneWidget);
      expect(find.textContaining('~'), findsNothing);
      // #2393 — the measured value is NOT wrapped in an estimate Tooltip
      // (it is a real reading, no approximate disclaimer).
      expect(
        find.ancestor(
          of: find.text('5.8 L/100'),
          matching: find.byType(Tooltip),
        ),
        findsNothing,
      );
    });

    testWidgets('GPS-only warm-up (null estimate) → no consumption text',
        (tester) async {
      await pumpApp(
        tester,
        const TripRecordingBanner(child: SizedBox()),
        overrides: [
          tripRecordingProvider.overrideWith(
            () => _FakeTripRecording(_activeState(
              distance: 1.2,
              fuelRateLPerHour: null,
              gpsEstimatedLPer100Km: null,
            )),
          ),
        ],
      );
      expect(find.textContaining('L/100'), findsNothing);
      expect(find.textContaining('~'), findsNothing);
    });
  });
}
