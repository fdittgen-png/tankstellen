// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/theme/dark_mode_colors.dart';
import 'package:tankstellen/features/obd2/data/session/trip_recording_controller.dart';
import 'package:tankstellen/features/trips/domain/cold_start_baselines.dart';
import 'package:tankstellen/features/trips/domain/situation_classifier.dart';
import 'package:tankstellen/features/trips/presentation/widgets/recording/live_band_header.dart';
import 'package:tankstellen/features/trips/providers/trip_recording_provider.dart';

import '../../../../../helpers/pump_app.dart';

class _FakeTripRecording extends TripRecording {
  _FakeTripRecording(this._initial);
  final TripRecordingState _initial;

  @override
  TripRecordingState build() => _initial;
}

/// Mutable fake — drives the rebuild-efficiency case (#3613): the header
/// selects the five fields it renders, so a live emit that changes none
/// of them must not rebuild it.
class _MutableTripRecording extends TripRecording {
  _MutableTripRecording(this._initial);
  final TripRecordingState _initial;

  @override
  TripRecordingState build() => _initial;

  void emit(TripRecordingState next) => state = next;
}

TripRecordingState _active({
  ConsumptionBand band = ConsumptionBand.normal,
  DrivingSituation situation = DrivingSituation.highwayCruise,
  double? delta,
  double? distance,
}) =>
    TripRecordingState(
      phase: TripRecordingPhase.recording,
      situation: situation,
      band: band,
      liveDeltaFraction: delta,
      live: distance == null
          ? null
          : TripLiveReading(
              distanceKmSoFar: distance,
              elapsed: const Duration(minutes: 1),
            ),
    );

Future<void> pumpHeader(WidgetTester tester, TripRecording Function() fake) =>
    pumpApp(
      tester,
      const LiveBandHeader(),
      overrides: [tripRecordingProvider.overrideWith(fake)],
    );

Color headerColor(WidgetTester tester) {
  final container = tester.widget<Container>(
    find
        .descendant(
          of: find.byType(LiveBandHeader),
          matching: find.byType(Container),
        )
        .first,
  );
  return (container.decoration! as BoxDecoration).color!;
}

/// #3959 — the ambient efficiency signal moved off the top of every
/// screen and onto the recording FORM. These pin what the old app-wide
/// strip guaranteed: the band colour, the situation in words, the signed
/// delta, and a live-region announcement.
void main() {
  group('LiveBandHeader (#3959)', () {
    testWidgets('renders nothing when no trip is recording', (tester) async {
      await pumpHeader(
        tester,
        () => _FakeTripRecording(const TripRecordingState()),
      );
      expect(find.byKey(const Key('liveBandHeader')), findsNothing);
      expect(tester.getSize(find.byType(LiveBandHeader)).height, 0);
    });

    testWidgets('names the driving situation and the signed delta', (
      tester,
    ) async {
      await pumpHeader(
        tester,
        () => _FakeTripRecording(
          _active(band: ConsumptionBand.heavy, delta: 0.08, distance: 5.2),
        ),
      );
      expect(find.text('Highway'), findsOneWidget);
      expect(find.text('+8%'), findsOneWidget);
    });

    testWidgets('a negative delta carries no leading + (#767)', (tester) async {
      await pumpHeader(
        tester,
        () => _FakeTripRecording(
          _active(band: ConsumptionBand.eco, delta: -0.12),
        ),
      );
      expect(find.text('-12%'), findsOneWidget);
    });

    // One band per test: re-pumping a second ProviderScope into the same
    // tree keeps the first scope's value, which would silently assert the
    // eco colour twice.
    testWidgets('an eco band paints the success colour', (tester) async {
      await pumpHeader(
        tester,
        () => _FakeTripRecording(_active(band: ConsumptionBand.eco)),
      );
      final context = tester.element(find.byType(LiveBandHeader));
      expect(headerColor(tester), DarkModeColors.success(context));
      // Colour is never the only channel — the situation is in words.
      expect(find.text('Highway'), findsOneWidget);
    });

    testWidgets('a very heavy band paints the error colour', (tester) async {
      await pumpHeader(
        tester,
        () => _FakeTripRecording(_active(band: ConsumptionBand.veryHeavy)),
      );
      final context = tester.element(find.byType(LiveBandHeader));
      expect(headerColor(tester), DarkModeColors.error(context));
      expect(find.text('Highway'), findsOneWidget);
    });

    testWidgets('paused wins over a stale band: neutral surface, "paused", '
        'no delta', (tester) async {
      await pumpHeader(
        tester,
        () => _FakeTripRecording(const TripRecordingState(
          phase: TripRecordingPhase.paused,
          situation: DrivingSituation.highwayCruise,
          band: ConsumptionBand.heavy,
          liveDeltaFraction: 0.4,
        )),
      );
      expect(find.textContaining('paused'), findsOneWidget);
      expect(find.text('Highway'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      final context = tester.element(find.byType(LiveBandHeader));
      expect(
        headerColor(tester),
        Theme.of(context).colorScheme.surfaceContainerHighest,
      );
    });

    testWidgets('announces itself as one live region, not a stream of '
        'numbers', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpHeader(
        tester,
        () => _FakeTripRecording(
          _active(band: ConsumptionBand.heavy, delta: 0.08),
        ),
      );
      final data = tester
          .getSemantics(find.byKey(const Key('liveBandHeader')))
          .getSemanticsData();
      expect(data.label, contains('Highway'));
      expect(data.label, contains('+8%'));
      expect(data.flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });

    testWidgets('a live emit that changes none of the rendered fields does '
        'not rebuild it (#3613)', (tester) async {
      final fake = _MutableTripRecording(_active(distance: 1.0));
      await pumpApp(
        tester,
        const LiveBandHeader(),
        overrides: [tripRecordingProvider.overrideWith(() => fake)],
      );
      final before = tester.element(find.byType(LiveBandHeader));

      // Same phase / situation / band / delta, a new distance only.
      fake.emit(_active(distance: 2.0));
      await tester.pump();

      expect(
        identical(tester.element(find.byType(LiveBandHeader)), before),
        isTrue,
      );
      expect(find.text('Highway'), findsOneWidget);
    });
  });
}
