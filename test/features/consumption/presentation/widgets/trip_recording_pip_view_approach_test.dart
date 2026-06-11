// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/approach_detector.dart';
import 'package:tankstellen/features/obd2/data/trip_recording_controller.dart';
import 'package:tankstellen/features/consumption/domain/cold_start_baselines.dart';
import 'package:tankstellen/features/consumption/domain/situation_classifier.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/proximity_fill_bar.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_recording_pip_view.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

const _stationE10 = Station(
  id: 's-1',
  name: 'Carrefour Pézenas',
  brand: 'Carrefour',
  street: '12 ROUTE DE BÉZIERS',
  postCode: '34120',
  place: 'Pézenas',
  lat: 43.46,
  lng: 3.42,
  e10: 1.879,
  diesel: 1.999,
  isOpen: true,
);

TripRecordingState _activeState({
  double distance = 12.4,
  Duration elapsed = const Duration(minutes: 8, seconds: 32),
  // Default fuel rate keeps tests on the OBD2 branch (#2094 Branch 1)
  // where the L/100 km marker is rendered — that's the canonical
  // "default layout" for the legacy tests. The GPS-estimate branch
  // (#2390), GPS-distance branch and pre-roll branch get their own
  // dedicated tests further down.
  double? fuelRateLPerHour = 4.06,
  // #2390 — GPS-only live physics estimate (L/100 km). Null on OBD2
  // trips + during the estimator's warm-up.
  double? gpsEstimatedLPer100Km,
  TripRecordingPhase phase = TripRecordingPhase.recording,
}) => TripRecordingState(
  phase: phase,
  situation: DrivingSituation.highwayCruise,
  band: ConsumptionBand.normal,
  live: TripLiveReading(
    speedKmh: 70,
    distanceKmSoFar: distance,
    elapsed: elapsed,
    fuelRateLPerHour: fuelRateLPerHour,
    gpsEstimatedLPer100Km: gpsEstimatedLPer100Km,
  ),
);

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

/// Constrain the PiP view to the REAL Android 2:1 tile geometry so the
/// no-clip assertions exercise the same fixed-aspect box production hits
/// (MainActivity.kt `setAspectRatio(Rational(2,1))`). 320×160 = 2:1. The
/// tile is pinned to the TOP-LEFT origin so a text's global `getRect()`
/// can be compared directly against the tile height (0..160).
Widget _wrapPip(Widget child, {Size size = const Size(320, 160)}) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: size.width, height: size.height, child: child),
        ),
      ),
    );

void main() {
  group('TripRecordingPipView (#2084) — approach-radius layout', () {
    testWidgets('default state renders the L/100 km layout — no approach', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          TripRecordingPipView(
            state: _activeState(),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            approachState: const ApproachIdle(),
          ),
        ),
      );
      // L/100 km unit caption is the canonical default-layout marker.
      expect(find.text('L/100 km'), findsOneWidget);
      // Approach layout would surface the station name; assert absent.
      expect(find.text('Carrefour Pézenas'), findsNothing);
    });

    testWidgets('ApproachInRadius flips to huge-price layout', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TripRecordingPipView(
            state: _activeState(),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            approachState: const ApproachInRadius(
              station: _stationE10,
              distanceMeters: 350,
            ),
            fuelType: FuelType.e10,
          ),
        ),
      );
      // Station name shows.
      expect(find.text('Carrefour Pézenas'), findsOneWidget);
      // The price for the requested fuel type renders.
      // Format depends on locale; assert the integer portion is present.
      expect(find.textContaining('1'), findsWidgets);
      // The L/100 km caption is GONE in approach mode.
      expect(find.text('L/100 km'), findsNothing);
    });

    testWidgets('ApproachLeaving keeps the price layout through grace', (
      tester,
    ) async {
      // During the 5 s exit grace the price should stay visible —
      // suppresses UI flicker.
      await tester.pumpWidget(
        _wrap(
          TripRecordingPipView(
            state: _activeState(),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            approachState: const ApproachLeaving(lastStation: _stationE10),
            fuelType: FuelType.e10,
          ),
        ),
      );
      expect(find.text('Carrefour Pézenas'), findsOneWidget);
      expect(find.text('L/100 km'), findsNothing);
    });

    testWidgets('approachState=null still renders the default layout', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          TripRecordingPipView(
            state: _activeState(),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      );
      expect(find.text('L/100 km'), findsOneWidget);
    });

    testWidgets(
      'approach with no price for the requested fuel falls back to —',
      (tester) async {
        const stationDieselOnly = Station(
          id: 's-2',
          name: 'Diesel-only',
          brand: 'X',
          street: '',
          postCode: '',
          place: '',
          lat: 0,
          lng: 0,
          diesel: 2.0,
          isOpen: true,
        );
        await tester.pumpWidget(
          _wrap(
            TripRecordingPipView(
              state: _activeState(),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              approachState: const ApproachInRadius(
                station: stationDieselOnly,
                distanceMeters: 100,
              ),
              fuelType: FuelType.e10, // not sold here
            ),
          ),
        );
        expect(find.text('—'), findsOneWidget);
        expect(find.text('Diesel-only'), findsOneWidget);
      },
    );
  });

  group('TripRecordingPipView (#2661) — polling radar price + km layout', () {
    testWidgets(
        'polling with a radar station → leads with its price + km (not consumption)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          TripRecordingPipView(
            state: _activeState(),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            // No in-radius hit; the radar surfaced the nearest priced station
            // 2.4 km out while still approaching.
            radarStation: _stationE10.copyWith(dist: 2.4),
            radarDistanceMeters: 2400,
            radiusMeters: 5000,
            fuelType: FuelType.e10,
          ),
        ),
      );

      // Leads with the station price + name (not L/100 km consumption).
      expect(find.text('Carrefour Pézenas'), findsOneWidget);
      expect(find.text('L/100 km'), findsNothing);
      // Distance reads in KM (not metres).
      expect(find.textContaining('2.4 km'), findsOneWidget);
      expect(find.textContaining(' m away'), findsNothing);
    });

    testWidgets(
        'no radar station (null) → falls back to the consumption layout',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          TripRecordingPipView(
            state: _activeState(),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            radarStation: null,
            fuelType: FuelType.e10,
          ),
        ),
      );
      // Falls back to consumption — never blank.
      expect(find.text('L/100 km'), findsOneWidget);
      expect(find.text('Carrefour Pézenas'), findsNothing);
    });

    testWidgets('an in-radius hit still wins over a radar station',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          TripRecordingPipView(
            state: _activeState(),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            approachState: const ApproachInRadius(
              station: _stationE10,
              distanceMeters: 350,
            ),
            // A different radar candidate must NOT override the locked target.
            radarStation: _stationE10.copyWith(name: 'Other Station'),
            radarDistanceMeters: 2400,
            fuelType: FuelType.e10,
          ),
        ),
      );
      // In-radius target shows in metres; the radar candidate is suppressed.
      expect(find.text('Carrefour Pézenas'), findsOneWidget);
      expect(find.text('Other Station'), findsNothing);
      expect(find.textContaining('350'), findsWidgets);
    });

    testWidgets('radar layout renders the corporate-green proximity bar',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          TripRecordingPipView(
            state: _activeState(),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            radarStation: _stationE10.copyWith(dist: 2.4),
            radarDistanceMeters: 2400,
            radiusMeters: 5000,
            fuelType: FuelType.e10,
          ),
        ),
      );
      final bar = tester.widget<ProximityFillBar>(find.byType(ProximityFillBar));
      expect(bar.distanceMeters, 2400);
      expect(bar.radiusMeters, 5000);
      // fill = 1 - 2400/5000 = 0.52.
      expect(
        ProximityFillBar.fillFor(bar.distanceMeters, bar.radiusMeters!),
        closeTo(0.52, 1e-9),
      );
    });
  });

  group('TripRecordingPipView (#2086) — state-machine transitions', () {
    // Integration coverage: simulated trajet passes through a station
    // fixture, asserts overlay flips to big-price on radius entry,
    // holds for the grace, and collapses back to L/100 km on exit.
    testWidgets('Idle → Polling → InRadius → Leaving → Polling: layout follows '
        'the state-machine transitions one-to-one', (tester) async {
      // Sweep the widget through the 5 state-machine transitions and
      // assert the layout matches at each step. We do not test the
      // detector itself here (that's covered by
      // approach_detector_test.dart) — only the widget's response.

      Future<void> pumpWithState(ApproachState approach) async {
        await tester.pumpWidget(
          _wrap(
            TripRecordingPipView(
              state: _activeState(),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              approachState: approach,
              fuelType: FuelType.e10,
            ),
          ),
        );
        await tester.pump();
      }

      // 1. Idle — default layout (L/100 km caption present, station
      //    absent).
      await pumpWithState(const ApproachIdle());
      expect(find.text('L/100 km'), findsOneWidget);
      expect(find.text('Carrefour Pézenas'), findsNothing);

      // 2. Polling — same default layout (we'd need a real GPS Position
      //    to build a Polling state; the widget doesn't care about that
      //    state's fields, only that it's NOT InRadius/Leaving).

      // 3. InRadius — flips to price view.
      await pumpWithState(
        const ApproachInRadius(station: _stationE10, distanceMeters: 350),
      );
      expect(find.text('Carrefour Pézenas'), findsOneWidget);
      expect(find.text('L/100 km'), findsNothing);

      // 4. Leaving — price view persists.
      await pumpWithState(const ApproachLeaving(lastStation: _stationE10));
      expect(find.text('Carrefour Pézenas'), findsOneWidget);
      expect(find.text('L/100 km'), findsNothing);

      // 5. Back to Idle — layout collapses to L/100 km again.
      await pumpWithState(const ApproachIdle());
      expect(find.text('L/100 km'), findsOneWidget);
      expect(find.text('Carrefour Pézenas'), findsNothing);
    });
  });
  group('TripRecordingPipView (#2094/#2601) — consumption-framed hero', () {
    Widget buildWith({double? fuelRate, double distance = 12.4}) => _wrap(
      TripRecordingPipView(
        state: _activeState(distance: distance, fuelRateLPerHour: fuelRate),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );

    testWidgets('OBD2 branch — fuel rate live → big L/100 km', (tester) async {
      await tester.pumpWidget(buildWith(fuelRate: 4.06));
      // Branch 1 active.
      expect(find.text('L/100 km'), findsOneWidget);
      // km / elapsed move to the secondary row, NOT the caption.
      expect(find.text('km'), findsNothing);
      expect(find.text('elapsed'), findsNothing);
    });

    testWidgets(
      '#2601 warm-up — distance ≥ 0.1 km, no estimate → "~" + est caption '
      '(NOT big distance)',
      (tester) async {
        await tester.pumpWidget(buildWith(fuelRate: null, distance: 4.0));
        // #2601 — the hero stays consumption-framed: a "~" placeholder under
        // the est. L/100 km caption, never a huge distance.
        expect(find.text('~'), findsOneWidget);
        expect(find.text('est. L/100 km'), findsOneWidget);
        // Distance is demoted to the secondary row (km suffix, not a hero).
        expect(find.text('4.0 km'), findsOneWidget);
        expect(find.text('L/100 km'), findsNothing);
        // No bare "km" caption hero anymore.
        expect(find.text('km'), findsNothing);
      },
    );

    testWidgets(
      '#2601 warm-up — distance ≈ 0 (pre-roll) → "~" + est caption with '
      'elapsed in the secondary row (NOT big elapsed — THE BUG)',
      (tester) async {
        await tester.pumpWidget(buildWith(fuelRate: null, distance: 0.0));
        // #2601 — THE BUG fix: pre-roll no longer leads with huge elapsed.
        // The hero is the consumption-framed "~" placeholder; elapsed is
        // demoted to the secondary row. Default helper uses 8m 32s elapsed.
        expect(find.text('~'), findsOneWidget);
        expect(find.text('est. L/100 km'), findsOneWidget);
        expect(find.text('8m 32s'), findsOneWidget); // secondary row
        // Elapsed is NOT the hero caption anymore.
        expect(find.text('elapsed'), findsNothing);
        expect(find.text('km'), findsNothing);
        expect(find.text('L/100 km'), findsNothing);
      },
    );

    testWidgets('elapsed-time formatter reads as a duration, not a clock '
        '(secondary row)', (tester) async {
      // The formatter shapes still render — now in the warm-up branch's
      // secondary row rather than as the hero.
      // Hour-plus shape drops seconds.
      await tester.pumpWidget(
        _wrap(
          TripRecordingPipView(
            state: _activeState(
              distance: 0.0,
              fuelRateLPerHour: null,
              elapsed: const Duration(hours: 1, minutes: 14, seconds: 12),
            ),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      );
      expect(find.text('1h 14m'), findsOneWidget);
      // Under-1-minute shape uses seconds only.
      await tester.pumpWidget(
        _wrap(
          TripRecordingPipView(
            state: _activeState(
              distance: 0.0,
              fuelRateLPerHour: null,
              elapsed: const Duration(seconds: 42),
            ),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      );
      expect(find.text('42s'), findsOneWidget);
    });

    testWidgets(
      'real-trip life-cycle — warm-up → warm-up → OBD2 keeps the hero '
      'consumption-framed at every step (#2601)',
      (tester) async {
        // Walks the widget through the natural sequence a real trip
        // produces: start parked (pre-roll, 0 km, no fuel rate), drive a
        // bit on GPS only (distance > 0.1 km, still no fuel rate),
        // adapter finally connects mid-trip (fuel rate becomes
        // available). The hero must stay CONSUMPTION-framed at every step —
        // never a huge elapsed/distance (#2601).
        Future<void> pumpAt({
          double distance = 0,
          double? fuelRate,
          Duration elapsed = const Duration(seconds: 42),
        }) async {
          await tester.pumpWidget(
            _wrap(
              TripRecordingPipView(
                state: _activeState(
                  distance: distance,
                  fuelRateLPerHour: fuelRate,
                  elapsed: elapsed,
                ),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          );
          await tester.pump();
        }

        // T = 0 — engine on, GPS still warming up, no fuel rate.
        // #2601 warm-up: "~" hero under the est caption, elapsed secondary.
        await pumpAt(distance: 0, fuelRate: null);
        expect(find.text('~'), findsOneWidget);
        expect(find.text('est. L/100 km'), findsOneWidget);
        expect(find.text('42s'), findsOneWidget); // secondary row
        expect(
          find.text('elapsed'),
          findsNothing,
          reason: '#2601 — the hero must never be elapsed time',
        );
        expect(find.text('L/100 km'), findsNothing);

        // T = 30 s — moved 0.5 km on GPS, still no OBD2 adapter.
        // Still warm-up: "~" hero, distance demoted to the secondary row.
        await pumpAt(
          distance: 0.5,
          fuelRate: null,
          elapsed: const Duration(seconds: 30),
        );
        expect(find.text('~'), findsOneWidget);
        expect(find.text('est. L/100 km'), findsOneWidget);
        expect(find.text('0.5 km'), findsOneWidget); // secondary row
        expect(find.text('km'), findsNothing);
        expect(find.text('L/100 km'), findsNothing);

        // T = 5 min — adapter connected, fuel-rate sample landed.
        // Branch 1: L/100 km takes the hero slot.
        await pumpAt(
          distance: 4.0,
          fuelRate: 4.06,
          elapsed: const Duration(minutes: 5),
        );
        expect(find.text('L/100 km'), findsOneWidget);
        // Distance + elapsed move to the secondary row — they're
        // still findable, just no longer the hero caption.
        expect(find.textContaining('4.0'), findsOneWidget);
        expect(find.text('elapsed'), findsNothing);
        // The measured value carries no "~" / est caption.
        expect(find.text('est. L/100 km'), findsNothing);
      },
    );
  });

  group('TripRecordingPipView (#2390) — GPS-only live estimate', () {
    Widget buildWith({
      double? fuelRate,
      double? gpsEstimate,
      double distance = 1.2,
      Duration elapsed = const Duration(minutes: 7, seconds: 7),
    }) => _wrap(
      TripRecordingPipView(
        state: _activeState(
          distance: distance,
          elapsed: elapsed,
          fuelRateLPerHour: fuelRate,
          gpsEstimatedLPer100Km: gpsEstimate,
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );

    testWidgets(
      'GPS-only trip with a live estimate → big "~X.X" + "est. L/100 km", '
      'not elapsed time',
      (tester) async {
        // No OBD2 fuel rate, estimator has produced 6.4 L/100 km. The
        // estimate becomes the hero with a leading "~" and the dedicated
        // localized "est. L/100 km" caption (#2393) — the elapsed time is
        // demoted.
        await tester.pumpWidget(buildWith(fuelRate: null, gpsEstimate: 6.4));
        expect(find.text('~6.4'), findsOneWidget);
        // #2393 — the estimate caption is the dedicated marker, distinct
        // from the OBD2 branch's bare "L/100 km".
        expect(find.text('est. L/100 km'), findsOneWidget);
        expect(find.text('L/100 km'), findsNothing);
        // The elapsed time is NOT the hero figure (it moves to the
        // secondary row instead of leading the tile).
        expect(find.text('7m 7s'), findsOneWidget); // secondary row
        // Distance also stays in the secondary row.
        expect(find.text('1.2 km'), findsOneWidget);
      },
    );

    testWidgets(
      'GPS-only estimate → approximate tooltip + a11y label (#2393)',
      (tester) async {
        await tester.pumpWidget(buildWith(fuelRate: null, gpsEstimate: 6.4));
        // The figure block is wrapped in a Tooltip carrying the
        // approximate-explanation message (long-press affordance).
        final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
        expect(tooltip.message, isNotNull);
        expect(tooltip.message, contains('GPS'));
        // The same explanation is exposed as a Semantics label for a11y.
        expect(find.bySemanticsLabel(RegExp('GPS')), findsOneWidget);
      },
    );

    testWidgets('OBD2 trip → real measured consumption, estimate path NOT '
        'taken (tilde-free, no est. caption, no tooltip)', (tester) async {
      // A real OBD2 fuel rate is present; even if an estimate were also
      // present, the measured value wins and stays tilde-free.
      await tester.pumpWidget(buildWith(fuelRate: 4.06, gpsEstimate: 6.4));
      expect(find.text('L/100 km'), findsOneWidget);
      // Measured value: 4.06 L/h at 70 km/h → ~5.8 L/100 km, no "~".
      expect(find.text('5.8'), findsOneWidget);
      expect(find.textContaining('~'), findsNothing);
      // #2393 — the measured value carries neither the est. caption nor
      // the approximate tooltip (it is a real reading, not an estimate).
      expect(find.text('est. L/100 km'), findsNothing);
      expect(find.byType(Tooltip), findsNothing);
    });

    testWidgets(
      'GPS-only warm-up (null estimate) → "~" hero + est caption, distance '
      'demoted (#2601)',
      (tester) async {
        // Estimator hasn't warmed up yet: estimate is null. #2601 keeps the
        // hero consumption-framed — a "~" under the est caption — with
        // distance demoted to the secondary row (never a huge distance).
        await tester.pumpWidget(
          buildWith(fuelRate: null, gpsEstimate: null, distance: 1.2),
        );
        expect(find.text('~'), findsOneWidget);
        expect(find.text('est. L/100 km'), findsOneWidget);
        expect(find.text('1.2 km'), findsOneWidget); // secondary row
        expect(find.text('L/100 km'), findsNothing);
        expect(find.text('km'), findsNothing);
      },
    );

    testWidgets(
      'GPS-only pre-roll (null estimate, distance ≈ 0) → "~" hero + est '
      'caption, elapsed demoted (#2601)',
      (tester) async {
        await tester.pumpWidget(
          buildWith(
            fuelRate: null,
            gpsEstimate: null,
            distance: 0.0,
            elapsed: const Duration(minutes: 7, seconds: 7),
          ),
        );
        // #2601 — pre-roll keeps the consumption-framed hero; elapsed is
        // demoted to the secondary row instead of leading the tile.
        expect(find.text('~'), findsOneWidget);
        expect(find.text('est. L/100 km'), findsOneWidget);
        expect(find.text('7m 7s'), findsOneWidget); // secondary row
        expect(find.text('elapsed'), findsNothing);
        expect(find.text('L/100 km'), findsNothing);
      },
    );

    testWidgets('paused GPS-only trip suppresses the estimate', (tester) async {
      // Paused → the estimate must not show (a stale reading would
      // mislead); the tile shows distance instead.
      await tester.pumpWidget(
        _wrap(
          TripRecordingPipView(
            state: _activeState(
              distance: 1.2,
              fuelRateLPerHour: null,
              gpsEstimatedLPer100Km: 6.4,
              phase: TripRecordingPhase.paused,
            ),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      );
      expect(find.textContaining('~'), findsNothing);
      expect(find.text('L/100 km'), findsNothing);
    });
  });

  group('TripRecordingPipView (#2964) — tap the tile body to restore', () {
    // #2964 — the user expects a tap on the floating PiP window to bring the
    // full app back to the foreground. The host (the banner) passes an
    // onBodyTap callback; tapping the tile body must invoke it (this replaces
    // the prior #2601 tap-to-navigate on the price layout). Tests assert the
    // callback fires exactly once per tap, and that the body stays
    // non-tappable when no callback is wired (preview / no-host fallback).

    testWidgets(
      'tapping the approach-price tile body invokes onBodyTap (restore)',
      (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          _wrap(
            TripRecordingPipView(
              state: _activeState(),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              approachState: const ApproachInRadius(
                station: _stationE10,
                distanceMeters: 350,
              ),
              fuelType: FuelType.e10,
              onBodyTap: () => taps++,
            ),
          ),
        );

        // The tile body carries a live GestureDetector wired to onBodyTap.
        final gesture = tester.widget<GestureDetector>(
          find.descendant(
            of: find.byType(Tooltip),
            matching: find.byType(GestureDetector),
          ),
        );
        expect(gesture.onTap, isNotNull);

        await tester.tap(find.byType(GestureDetector));
        await tester.pumpAndSettle();
        expect(taps, 1, reason: 'tapping the tile body must restore the app');
      },
    );

    testWidgets(
      'tapping the radar-price tile body invokes onBodyTap (restore)',
      (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          _wrap(
            TripRecordingPipView(
              state: _activeState(),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              radarStation: _stationE10.copyWith(dist: 2.4),
              radarDistanceMeters: 2400,
              radiusMeters: 5000,
              fuelType: FuelType.e10,
              onBodyTap: () => taps++,
            ),
          ),
        );
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();
        expect(taps, 1);
      },
    );

    testWidgets(
      'tapping the default consumption tile body invokes onBodyTap (restore)',
      (tester) async {
        // #2964 — unlike #2601 (which only made the price layout tappable),
        // the default consumption layout is now tappable too: a tap on ANY
        // tile body restores the app.
        var taps = 0;
        await tester.pumpWidget(
          _wrap(
            TripRecordingPipView(
              state: _activeState(),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              approachState: const ApproachIdle(),
              onBodyTap: () => taps++,
            ),
          ),
        );
        // L/100 km default layout, with a body tap target.
        expect(find.text('L/100 km'), findsOneWidget);
        await tester.tap(find.byType(GestureDetector));
        await tester.pumpAndSettle();
        expect(taps, 1);
      },
    );

    testWidgets(
      'the tile body exposes the restore tooltip + a11y label',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            TripRecordingPipView(
              state: _activeState(),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              approachState: const ApproachIdle(),
              onBodyTap: () {},
            ),
          ),
        );
        final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
        expect(tooltip.message, 'Tap to open the full app');
        // The body is announced as a button carrying the restore label so a
        // screen-reader user knows the tap brings the app back.
        final semantics = tester.widget<Semantics>(
          find.descendant(
            of: find.byType(Tooltip),
            matching: find.byWidgetPredicate(
              (w) => w is Semantics && w.properties.label != null,
            ),
          ),
        );
        expect(semantics.properties.label, 'Tap to open the full app');
        expect(semantics.properties.button, isTrue);
      },
    );

    testWidgets(
      'no onBodyTap → the tile body is NOT tappable (no host fallback)',
      (tester) async {
        // Without a wired host the tile renders plainly — no GestureDetector,
        // so previews / widget tests without a PiP host stay inert.
        await tester.pumpWidget(
          _wrap(
            TripRecordingPipView(
              state: _activeState(),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              approachState: const ApproachInRadius(
                station: _stationE10,
                distanceMeters: 350,
              ),
              fuelType: FuelType.e10,
            ),
          ),
        );
        expect(find.byType(GestureDetector), findsNothing);
      },
    );
  });

  group('TripRecordingPipView (#2620) — no clip in a small PiP viewport', () {
    // Every state must render its full stack — figure + caption +
    // secondary row — inside the fixed 2:1 Android tile (320×160) WITHOUT
    // a RenderFlex overflow and WITHOUT the bottom line bleeding past the
    // tile. The reported bug clipped the `distance · elapsed` row in the
    // warm-up state; the outer `FittedBox(scaleDown)` now shrinks the
    // whole stack so the last line stays on-screen and readable.
    const tileHeight = 160.0;

    testWidgets(
      'warm-up (the reported bug) — "~" + est caption + secondary row all '
      'fit, secondary not clipped',
      (tester) async {
        // fuelRate null + gpsEstimate null + distance 0.0 + elapsed 37s — the
        // exact warm-up branch from the screenshot (`~` / est. L/100 km /
        // 0.0 km · 37s).
        await tester.pumpWidget(
          _wrapPip(
            TripRecordingPipView(
              state: _activeState(
                distance: 0.0,
                fuelRateLPerHour: null,
                gpsEstimatedLPer100Km: null,
                elapsed: const Duration(seconds: 37),
              ),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('~'), findsOneWidget);
        expect(find.text('est. L/100 km'), findsOneWidget);
        expect(find.text('37s'), findsOneWidget);
        // The secondary row's bottom must stay within the tile — not clipped.
        expect(
          tester.getRect(find.text('37s')).bottom,
          lessThanOrEqualTo(tileHeight),
        );
      },
    );

    testWidgets('GPS-estimate — "~6.4" + secondary row within bounds', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapPip(
          TripRecordingPipView(
            state: _activeState(
              distance: 1.2,
              fuelRateLPerHour: null,
              gpsEstimatedLPer100Km: 6.4,
              elapsed: const Duration(minutes: 7, seconds: 7),
            ),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('~6.4'), findsOneWidget);
      expect(find.text('7m 7s'), findsOneWidget);
      expect(
        tester.getRect(find.text('7m 7s')).bottom,
        lessThanOrEqualTo(tileHeight),
      );
    });

    testWidgets('OBD2 live — L/100 km + secondary row within bounds', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapPip(
          TripRecordingPipView(
            state: _activeState(fuelRateLPerHour: 4.06),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('L/100 km'), findsOneWidget);
      // Default helper elapsed is 8m 32s — its bottom must stay on-tile.
      expect(
        tester.getRect(find.text('8m 32s')).bottom,
        lessThanOrEqualTo(tileHeight),
      );
    });

    testWidgets('approach-price — name + price + distance line within bounds', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapPip(
          TripRecordingPipView(
            state: _activeState(),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            approachState: const ApproachInRadius(
              station: _stationE10,
              distanceMeters: 350,
            ),
            fuelType: FuelType.e10,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Carrefour Pézenas'), findsOneWidget);
      // Price for E10 renders (locale-dependent format, integer present).
      expect(find.textContaining('1'), findsWidgets);
      // The bottom-most distance line must stay within the tile.
      expect(
        tester.getRect(find.textContaining('350')).bottom,
        lessThanOrEqualTo(tileHeight),
      );
    });

    testWidgets('paused — fallback figure + paused label both within bounds', (
      tester,
    ) async {
      // Paused suppresses every live reading (raw + estimate both null),
      // so the layout hits its fallback figure + the localized paused
      // label. Both must stay on-tile.
      await tester.pumpWidget(
        _wrapPip(
          TripRecordingPipView(
            state: _activeState(
              distance: 4.0,
              fuelRateLPerHour: 4.06,
              gpsEstimatedLPer100Km: 6.4,
              elapsed: const Duration(minutes: 5),
              phase: TripRecordingPhase.paused,
            ),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      // The localized paused banner is the bottom-most line.
      final pausedLine = find.text('Trip paused — tap to resume');
      expect(pausedLine, findsOneWidget);
      expect(tester.getRect(pausedLine).bottom, lessThanOrEqualTo(tileHeight));
    });
  });
}
