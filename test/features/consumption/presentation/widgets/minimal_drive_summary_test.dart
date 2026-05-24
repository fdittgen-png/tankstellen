import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_live_reading.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/minimal_drive_summary.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_state.dart';
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
}
