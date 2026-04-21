import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_recording_controller.dart';
import 'package:tankstellen/features/consumption/domain/cold_start_baselines.dart';
import 'package:tankstellen/features/consumption/domain/situation_classifier.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_recording_banner.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';

import '../../../../helpers/pump_app.dart';

/// Fake notifier lets tests pin the banner to an exact state without
/// spinning up an Obd2Service + controller + streams.
class _FakeTripRecording extends TripRecording {
  final TripRecordingState _initial;
  _FakeTripRecording(this._initial);

  @override
  TripRecordingState build() => _initial;
}

TripRecordingState _activeState({
  ConsumptionBand band = ConsumptionBand.normal,
  DrivingSituation situation = DrivingSituation.highwayCruise,
  double? delta,
  double? distance,
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
}
