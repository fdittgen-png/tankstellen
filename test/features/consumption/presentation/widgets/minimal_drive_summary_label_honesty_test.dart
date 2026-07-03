// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/trip_live_reading.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/minimal_drive_summary.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #3431 (epic #3416) — label honesty on the minimal drive summary.
///
/// Before #3431 the card's single big figure was the trip RUNNING
/// AVERAGE (`liveAvgLPer100Km`) under the "Instant consumption" label.
/// These tests pin the fix: the headline is the true instantaneous
/// signal, and the running average appears on its own row with an
/// honest "Trip average" label — both figures visible, both labelled.
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
  group('MinimalDriveSummary label honesty (#3431)', () {
    testWidgets(
        'headline shows the TRUE instant figure and the running average '
        'sits on a separate, honestly-labelled row', (tester) async {
      // Trip average: 0.83 L over 10 km = 8.3 L/100 km. Instant (EMA):
      // 10.0 L/100 km — deliberately different so a conflation of the
      // two figures cannot pass.
      const state = TripRecordingState(
        live: TripLiveReading(
          elapsed: Duration(minutes: 5),
          distanceKmSoFar: 10.0,
          fuelLitersSoFar: 0.83,
          fuelRateLPerHour: 6.0,
          speedKmh: 60.0,
          instantLPer100Km: 10.0,
          instantLPerHour: 6.0,
          instantIsIdle: false,
        ),
      );
      await tester.pumpWidget(_harness(state));
      await tester.pumpAndSettle();

      // Headline = the instant signal (formatInstantConsumption mask).
      final headline = tester.widget<Text>(
          find.byKey(const Key('minimal_drive_instant_value')));
      expect(headline.data, '10.0 L/100');

      // The running average is present too — on its own labelled row.
      final avg = tester.widget<Text>(
          find.byKey(const Key('minimal_drive_trip_avg_value')));
      expect(avg.data, '8.3 L/100 km');

      // Both labels are visible: instant + trip average (en copy).
      expect(find.text('Instant consumption'), findsOneWidget);
      expect(find.text('Trip average'), findsOneWidget);
    });

    testWidgets('idle mode: headline falls back to L/h, average stays',
        (tester) async {
      const state = TripRecordingState(
        live: TripLiveReading(
          elapsed: Duration(minutes: 5),
          distanceKmSoFar: 4.0,
          fuelLitersSoFar: 0.4,
          fuelRateLPerHour: 0.8,
          speedKmh: 0.0,
          instantLPerHour: 0.8,
          instantIsIdle: true,
        ),
      );
      await tester.pumpWidget(_harness(state));
      await tester.pumpAndSettle();

      final headline = tester.widget<Text>(
          find.byKey(const Key('minimal_drive_instant_value')));
      expect(headline.data, '0.8 L/h');
      final avg = tester.widget<Text>(
          find.byKey(const Key('minimal_drive_trip_avg_value')));
      expect(avg.data, '10.0 L/100 km');
    });

    testWidgets(
        'no instant signal and no average → headline dashes, no avg row',
        (tester) async {
      const state = TripRecordingState(
        live: TripLiveReading(
          elapsed: Duration(minutes: 1),
          distanceKmSoFar: 0.0,
        ),
      );
      await tester.pumpWidget(_harness(state));
      await tester.pumpAndSettle();

      final headline = tester.widget<Text>(
          find.byKey(const Key('minimal_drive_instant_value')));
      expect(headline.data, '—');
      expect(
          find.byKey(const Key('minimal_drive_trip_avg_value')), findsNothing);
    });
  });
}
