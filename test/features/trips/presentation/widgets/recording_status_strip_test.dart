// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/obd2/api.dart';
import 'package:tankstellen/features/trips/presentation/widgets/recording/recording_status_strip.dart';
import 'package:tankstellen/features/trips/providers/recording_gps_fix_provider.dart';
import 'package:tankstellen/features/trips/providers/trip_recording_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/silence_error_logger.dart';

/// #3916 (Epic #3914) — the recording screen's status strip: two tappable
/// pills (OBD2 link, GPS fix) that say in plain language what each source
/// is doing, each opening a sheet that explains the state and what the
/// driver can do.
class _FakeTripRecording extends TripRecording {
  _FakeTripRecording(this._state);
  final TripRecordingState _state;
  @override
  TripRecordingState build() => _state;
}

class _PinnedLinkState extends Obd2Reconnect {
  _PinnedLinkState(this._pinned);
  final Obd2LinkState _pinned;
  @override
  Obd2LinkState build() => _pinned;
}

class _FakeObd2Status extends Obd2ConnectionStatus {
  _FakeObd2Status(this._initial);
  final Obd2ConnectionSnapshot _initial;
  @override
  Obd2ConnectionSnapshot build() => _initial;
}

class _SeededFix extends RecordingGpsFixTracker {
  _SeededFix(this._fix);
  final RecordingGpsFix? _fix;
  @override
  RecordingGpsFix? build() => _fix;
}

final _now = DateTime(2026, 3, 11, 14, 30);

Widget _harness({
  required TripRecordingState state,
  Obd2LinkState link = Obd2LinkState.ready,
  RecordingGpsFix? fix,
  String? adapterName = 'vLinker FS',
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: [
      tripRecordingProvider.overrideWith(() => _FakeTripRecording(state)),
      obd2ReconnectProvider.overrideWith(() => _PinnedLinkState(link)),
      obd2ConnectionStatusProvider.overrideWith(
        () => _FakeObd2Status(Obd2ConnectionSnapshot(
          state: adapterName == null
              ? Obd2ConnectionState.idle
              : Obd2ConnectionState.connected,
          adapterName: adapterName,
        )),
      ),
      recordingGpsFixProvider.overrideWith(() => _SeededFix(fix)),
      appClockProvider.overrideWithValue(FixedClock(_now)),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16),
          child: RecordingStatusStrip(),
        ),
      ),
    ),
  );
}

const _liveReading = TripLiveReading(
  elapsed: Duration(minutes: 5),
  distanceKmSoFar: 4.0,
  rpm: 1800,
  fuelRateLPerHour: 3.2,
  obd2ReadsPerSecond: 11.6,
);

void main() {
  silenceErrorLoggerSpool();

  group('RecordingStatusStrip — OBD2 chip', () {
    testWidgets('live engine data reads "Live · N PID/s" and the sheet '
        'names the adapter with no reset', (tester) async {
      await tester.pumpWidget(_harness(
        state: const TripRecordingState(
          phase: TripRecordingPhase.recording,
          live: _liveReading,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Live · 12 PID/s'), findsOneWidget);

      await tester.tap(find.byKey(const Key('recordingObd2StatusChip')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('recordingObd2StatusSheet')), findsOneWidget);
      expect(find.text('vLinker FS'), findsOneWidget);
      expect(
        find.textContaining('measured from the car'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('recordingStatusSheetReset')), findsNothing);
    });

    testWidgets('degraded + reconnecting reads "Reconnecting…" and the sheet '
        'offers the reset', (tester) async {
      await tester.pumpWidget(_harness(
        state: const TripRecordingState(
          phase: TripRecordingPhase.degradedGpsOnly,
          dropReason: TripDropReason.transportError,
          live: TripLiveReading(
            elapsed: Duration(minutes: 5),
            distanceKmSoFar: 4.0,
          ),
        ),
        link: Obd2LinkState.reconnecting,
      ));
      // The busy spinner animates forever: pump frames, never settle.
      await tester.pump();

      // The pinned test notifier has no supervisor → no attempt ordinal.
      expect(find.text('Reconnecting…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byKey(const Key('recordingObd2StatusChip')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('continues on GPS'), findsOneWidget);
      expect(
          find.byKey(const Key('recordingStatusSheetReset')), findsOneWidget);
    });

    testWidgets('passive wait reads "GPS only"', (tester) async {
      await tester.pumpWidget(_harness(
        state: const TripRecordingState(
          phase: TripRecordingPhase.degradedGpsOnly,
          reconnectPassiveWaiting: true,
        ),
        link: Obd2LinkState.idle,
      ));
      await tester.pumpAndSettle();
      expect(find.text('GPS only'), findsOneWidget);
    });

    testWidgets('engine-off wait reads "Engine off — waiting" with NO reset '
        '(#3858)', (tester) async {
      await tester.pumpWidget(_harness(
        state: const TripRecordingState(
          phase: TripRecordingPhase.degradedGpsOnly,
          dropReason: TripDropReason.engineOff,
        ),
        link: Obd2LinkState.engineOff,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Engine off — waiting'), findsOneWidget);

      await tester.tap(find.byKey(const Key('recordingObd2StatusChip')));
      await tester.pumpAndSettle();
      expect(find.textContaining('engine is off'), findsOneWidget);
      expect(find.byKey(const Key('recordingStatusSheetReset')), findsNothing);
    });

    testWidgets('French copy resolves through the ARB', (tester) async {
      await tester.pumpWidget(_harness(
        state: const TripRecordingState(
          phase: TripRecordingPhase.recording,
          live: _liveReading,
        ),
        locale: const Locale('fr'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('En direct · 12 PID/s'), findsOneWidget);
      expect(find.text('Pas de fix'), findsOneWidget);
    });
  });

  group('RecordingStatusStrip — GPS chip', () {
    testWidgets('no fix yet reads "No fix" and the sheet explains', (tester) async {
      await tester.pumpWidget(_harness(
        state: const TripRecordingState(phase: TripRecordingPhase.recording),
      ));
      await tester.pumpAndSettle();
      expect(find.text('No fix'), findsOneWidget);

      await tester.tap(find.byKey(const Key('recordingGpsStatusChip')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('recordingGpsStatusSheet')), findsOneWidget);
      expect(find.textContaining('No position has arrived'), findsOneWidget);
      expect(
          find.byKey(const Key('recordingStatusSheetFootnote')), findsNothing);
    });

    testWidgets('a precise fresh fix reads the accuracy + coverage, and the '
        'sheet carries the coverage footnote', (tester) async {
      await tester.pumpWidget(_harness(
        state: const TripRecordingState(
          phase: TripRecordingPhase.recording,
          live: _liveReading,
        ),
        fix: RecordingGpsFix(
          fixAt: _now.subtract(const Duration(seconds: 1)),
          firstFixAt: _now.subtract(const Duration(seconds: 21)),
          fixCount: 21,
          accuracyM: 4.8,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Precise fix (±5 m) · 100 %'), findsOneWidget);

      await tester.tap(find.byKey(const Key('recordingGpsStatusChip')));
      await tester.pumpAndSettle();
      expect(find.textContaining('accurate to a few metres'), findsOneWidget);
      expect(find.text('Coverage so far: 100 % of the seconds had a fix.'),
          findsOneWidget);
    });

    testWidgets('a coarse fix reads approximate', (tester) async {
      await tester.pumpWidget(_harness(
        state: const TripRecordingState(phase: TripRecordingPhase.recording),
        fix: RecordingGpsFix(
          fixAt: _now,
          firstFixAt: _now,
          fixCount: 1,
          accuracyM: 41.2,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Approximate fix (±41 m)'), findsOneWidget);
    });
  });
}
