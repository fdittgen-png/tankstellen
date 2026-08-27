// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/domain/trip_live_reading.dart';
import 'package:tankstellen/features/trips/presentation/widgets/minimal_drive_summary.dart';
import 'package:tankstellen/features/trips/providers/trip_recording_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

Widget _harness(TripRecordingState state) {
  return ProviderScope(
    overrides: [
      tripRecordingProvider.overrideWith(
        () => _FakeTripRecordingNotifier(state),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: MinimalDriveSummary()),
    ),
  );
}

// ignore_for_file: prefer_const_constructors

class _FakeTripRecordingNotifier extends TripRecording {
  _FakeTripRecordingNotifier(this._state);
  final TripRecordingState _state;
  @override
  TripRecordingState build() => _state;
}

void main() {
  group('MinimalDriveSummary (#2026)', () {
    testWidgets('renders headline em-dash when no live reading is available',
        (tester) async {
      await tester.pumpWidget(_harness(const TripRecordingState()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('minimal_drive_summary_card')),
          findsOneWidget);
      final headline = tester.widget<Text>(
          find.byKey(const Key('minimal_drive_instant_value')));
      expect(headline.data, '—');
    });

    testWidgets('renders the computed live L/100 km figure when present',
        (tester) async {
      // liveAvgLPer100Km is a getter — 0.83 L over 10 km = 8.3 L/100 km.
      const state = TripRecordingState(
        live: TripLiveReading(
          elapsed: Duration(minutes: 5),
          distanceKmSoFar: 10.0,
          fuelLitersSoFar: 0.83,
        ),
      );
      await tester.pumpWidget(_harness(state));
      await tester.pumpAndSettle();
      expect(find.text('8.3 L/100 km'), findsOneWidget);
    });

    testWidgets('renders all three coaching symbols even when inactive',
        (tester) async {
      await tester.pumpWidget(_harness(const TripRecordingState()));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.keyboard_double_arrow_up), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_double_arrow_down), findsOneWidget);
      expect(find.byIcon(Icons.eco), findsOneWidget);
    });
  });

  group('#3845 live driving-behaviour band', () {
    TripRecordingState stateWithScore(int? score) => TripRecordingState(
          live: TripLiveReading(
            elapsed: Duration(minutes: 5),
            distanceKmSoFar: 10.0,
            liveDrivingScore: score,
          ),
        );

    testWidgets('hidden while the tracker has not earned a band yet',
        (tester) async {
      await tester.pumpWidget(_harness(stateWithScore(null)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('minimal_drive_behaviour_band')), findsNothing,
          reason: 'a colour shown before the score is earned would be '
              'reporting "no data" as "driving well"');
    });

    // The four bands the user asked for, good -> bad, with the colour
    // each must paint. Colour is asserted directly: "green yellow orange
    // red" WAS the requirement, so a theme-role regression that silently
    // repainted them has to fail here.
    const bands = <String, (int, Color)>{
      'green': (92, Color(0xFF2E7D32)),
      'yellow': (75, Color(0xFFF9A825)),
      'orange': (58, Color(0xFFEF6C00)),
      'red': (30, Color(0xFFC62828)),
    };

    bands.forEach((colourName, spec) {
      final (score, colour) = spec;
      testWidgets('score $score paints $colourName', (tester) async {
        await tester.pumpWidget(_harness(stateWithScore(score)));
        await tester.pumpAndSettle();
        expect(
            find.byKey(const Key('minimal_drive_behaviour_band')),
            findsOneWidget);
        final label = tester.widget<Text>(
            find.byKey(const Key('minimal_drive_behaviour_label')));
        expect(label.style?.color, colour);
        final bar = tester.widget<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator));
        expect(bar.value, closeTo(score / 100.0, 1e-9));
      });
    });

    testWidgets('the number is rendered beside the colour', (tester) async {
      // Colour must never be the only channel — a colour-blind driver and
      // a screen reader both need the value.
      await tester.pumpWidget(_harness(stateWithScore(64)));
      await tester.pumpAndSettle();
      final score = tester.widget<Text>(
          find.byKey(const Key('minimal_drive_behaviour_score')));
      expect(score.data, '64',
          reason: 'the score must be readable without relying on colour');
    });

    testWidgets('the band survives a GPS-only reading (no fuel-rate PID)',
        (tester) async {
      // The always-on requirement: no fuelRateLPerHour anywhere in this
      // reading, and the band still shows.
      const state = TripRecordingState(
        live: TripLiveReading(
          elapsed: Duration(minutes: 5),
          distanceKmSoFar: 10.0,
          speedKmh: 60.0,
          liveDrivingScore: 88,
        ),
      );
      await tester.pumpWidget(_harness(state));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('minimal_drive_behaviour_band')),
          findsOneWidget);
    });
  });
}
