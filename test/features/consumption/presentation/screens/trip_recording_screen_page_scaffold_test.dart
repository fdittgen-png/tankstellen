import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/page_scaffold.dart';
import 'package:tankstellen/features/consumption/domain/cold_start_baselines.dart';
import 'package:tankstellen/features/consumption/domain/situation_classifier.dart';
import 'package:tankstellen/features/consumption/presentation/screens/trip_recording_screen.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/consumption/providers/wakelock_facade.dart';

import '../../../../helpers/pump_app.dart';

/// Regression: TripRecordingScreen must render its chrome via
/// [PageScaffold] (#923 phase 3m). Pause / Resume / Stop and the #891
/// pin toggle all flow through `PageScaffold.actions`, so their keys
/// must remain findable after the migration.
class _FakeTripRecording extends TripRecording {
  final TripRecordingState _initial;
  _FakeTripRecording(this._initial);

  @override
  TripRecordingState build() => _initial;
}

class _FakeWakelockFacade implements WakelockFacade {
  @override
  Future<void> enable() async {}

  @override
  Future<void> disable() async {}
}

TripRecordingState _recordingState() {
  return const TripRecordingState(
    phase: TripRecordingPhase.recording,
    situation: DrivingSituation.highwayCruise,
    band: ConsumptionBand.normal,
  );
}

Future<void> _pumpRecordingScreen(WidgetTester tester) async {
  await pumpApp(
    tester,
    const TripRecordingScreen(),
    overrides: [
      tripRecordingProvider.overrideWith(
        () => _FakeTripRecording(_recordingState()),
      ),
      wakelockFacadeProvider.overrideWithValue(_FakeWakelockFacade()),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TripRecordingScreen — PageScaffold migration (#923 phase 3m)', () {
    testWidgets('chrome is rendered via PageScaffold', (tester) async {
      await _pumpRecordingScreen(tester);

      expect(find.byType(PageScaffold), findsOneWidget);
    });

    testWidgets('page title reads "Recording trip" while actively recording',
        (tester) async {
      await _pumpRecordingScreen(tester);

      // Title flows through PageScaffold → AppBar.title.
      expect(find.text('Recording trip'), findsOneWidget);
    });

    testWidgets('pause / stop / pin action buttons survive the migration',
        (tester) async {
      await _pumpRecordingScreen(tester);

      expect(find.byKey(const Key('tripPinButton')), findsOneWidget);
      expect(find.byKey(const Key('tripPauseButton')), findsOneWidget);
      expect(find.byKey(const Key('tripStopButton')), findsOneWidget);
    });
  });
}
