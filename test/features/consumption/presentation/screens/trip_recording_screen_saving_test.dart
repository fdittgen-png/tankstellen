// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/screens/trip_recording_screen.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_save_progress.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/consumption/providers/wakelock_facade.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/silence_error_logger.dart';
import '../../../../helpers/recording_profile_override.dart';

/// #2548 — staged save-progress when a recording is stopped. The screen
/// renders the inline [TripSaveProgress] card while [phase] is the
/// transient (non-active) `saving` phase, the stop-side bookend to the
/// #2274 connecting view. These structural tests pin: the card renders
/// for every save stage with the right label, the saving title shows,
/// and the phase is observable but NOT active (so the recording banner
/// must not resurface mid-save). No goldens.
///
/// Pumped with a manual [WidgetTester.pump] (never `pumpAndSettle`) —
/// the progress card runs an indefinitely-repeating spin/pulse, which
/// never settles, exactly like the connecting-progress card.
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

Future<void> _pumpSaving(WidgetTester tester, TripSaveStage stage) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tripRecordingProvider.overrideWith(
          () => _FakeTripRecording(
            TripRecordingState(
              phase: TripRecordingPhase.saving,
              saveStage: stage,
            ),
          ),
        ),
        wakelockFacadeProvider.overrideWithValue(_FakeWakelockFacade()),
      recordingProfileOverride() as Override,
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: TripRecordingScreen(),
      ),
    ),
  );
  // A single frame — the repeating animations never settle.
  await tester.pump();
}

void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TripRecordingScreen — staged save progress (#2548)', () {
    testWidgets('renders the TripSaveProgress card while saving',
        (tester) async {
      await _pumpSaving(tester, TripSaveStage.finalizingSummary);

      expect(find.byKey(const Key('tripSaveProgress')), findsOneWidget);
      expect(find.byType(TripSaveProgress), findsOneWidget);
      // The connecting card must NOT be up — saving wins.
      expect(find.byKey(const Key('tripRecordingConnectingProgress')),
          findsNothing);
    });

    testWidgets('finalizing stage shows the finalizing label', (tester) async {
      await _pumpSaving(tester, TripSaveStage.finalizingSummary);
      expect(find.text('Finalizing summary…'), findsOneWidget);
    });

    testWidgets('saving stage shows the saving-to-history label',
        (tester) async {
      await _pumpSaving(tester, TripSaveStage.savingToHistory);
      expect(find.text('Saving to history…'), findsOneWidget);
    });

    testWidgets('syncing stage shows the honest in-background label',
        (tester) async {
      await _pumpSaving(tester, TripSaveStage.syncingToCloud);
      // Honest wording: the upload is fire-and-forget, so it is worded
      // "in background", never a determinate percentage.
      expect(find.text('Syncing in background…'), findsOneWidget);
    });

    testWidgets('the AppBar title reads the saving variant', (tester) async {
      await _pumpSaving(tester, TripSaveStage.savingToHistory);
      expect(find.text('Saving trip…'), findsOneWidget);
    });

    testWidgets('the progress indicator is indeterminate (no value)',
        (tester) async {
      await _pumpSaving(tester, TripSaveStage.finalizingSummary);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, isNull,
          reason: 'the save is a sub-second fixed await sequence — the bar '
              'is indeterminate, never a determinate percentage');
    });

    testWidgets('a liveRegion announces the stage to screen readers',
        (tester) async {
      await _pumpSaving(tester, TripSaveStage.finalizingSummary);
      final semantics = tester.widget<Semantics>(
        find
            .ancestor(
              of: find.text('Finalizing summary…'),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(semantics.properties.liveRegion, isTrue);
    });
  });

  group('TripRecordingState — saving is non-active (#2548)', () {
    test('saving phase is observable via isSaving but NOT active', () {
      const state = TripRecordingState(
        phase: TripRecordingPhase.saving,
        saveStage: TripSaveStage.savingToHistory,
      );
      expect(state.isSaving, isTrue);
      expect(state.isActive, isFalse,
          reason: 'the trip has left the live loop — the recording banner '
              'must NOT resurface mid-save');
      expect(state.isConnecting, isFalse);
      expect(state.saveStage, TripSaveStage.savingToHistory);
    });

    test('copyWith carries + clears the saveStage', () {
      const base = TripRecordingState(
        phase: TripRecordingPhase.saving,
        saveStage: TripSaveStage.finalizingSummary,
      );
      expect(
        base.copyWith(saveStage: TripSaveStage.syncingToCloud).saveStage,
        TripSaveStage.syncingToCloud,
      );
      expect(base.copyWith(clearSaveStage: true).saveStage, isNull);
    });
  });
}
