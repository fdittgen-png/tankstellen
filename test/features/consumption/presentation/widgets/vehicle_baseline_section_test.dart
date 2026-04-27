import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/situation_classifier.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/vehicle_baseline_section.dart';
import 'package:tankstellen/features/consumption/providers/vehicle_baseline_summary_provider.dart';

import '../../../../helpers/pump_app.dart';

const _vehicleId = 'car-a';

/// Convenience: wraps the section in a sized container so the
/// `LinearProgressIndicator`s have a real width to lay out against.
Widget _host({int fullConfidenceSamples = 30}) => SizedBox(
      width: 600,
      child: VehicleBaselineSection(
        vehicleId: _vehicleId,
        fullConfidenceSamples: fullConfidenceSamples,
      ),
    );

/// Build the override that pins the baseline summary to a specific
/// per-situation count map. Saves repeating `.overrideWithValue(...)`
/// boilerplate in every test.
Object _summaryOverride(Map<DrivingSituation, int> counts) =>
    vehicleBaselineSummaryProvider(_vehicleId).overrideWithValue(counts);

void main() {
  group('VehicleBaselineSection (#779)', () {
    testWidgets(
        'empty counts: every progress bar reads 0/cap and the empty '
        'message is shown so a user with no trips yet understands why '
        'the section is blank instead of broken', (tester) async {
      await pumpApp(
        tester,
        _host(),
        overrides: [_summaryOverride(const {})],
      );

      // All 6 persisted situations render at 0/30.
      expect(find.text('0/30'), findsNWidgets(6));

      // Empty-state copy mentions OBD2 trips.
      expect(find.textContaining('OBD2 trip'), findsOneWidget);

      // Reset button is disabled when nothing has been learned —
      // no point wiping a baseline that doesn't exist.
      final resetBtn =
          tester.widget<TextButton>(find.byType(TextButton).first);
      expect(resetBtn.onPressed, isNull);
    });

    testWidgets(
        'partial confidence: a situation with 15 samples and a 30 cap '
        'renders its bar at 50% so the user can eyeball calibration '
        'progress', (tester) async {
      await pumpApp(
        tester,
        _host(),
        overrides: [
          _summaryOverride(const {
            DrivingSituation.urbanCruise: 15,
          }),
        ],
      );

      // The "15/30" readout proves we're rendering the partial state.
      expect(find.text('15/30'), findsOneWidget);

      // The progress bar paired with this row sits at 0.5.
      final bars = tester
          .widgetList<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          )
          .toList();
      expect(bars.length, 6);
      // One of the bars must be at 0.5 — exact ordering is the widget's
      // concern, not the test's.
      expect(
        bars.where((b) => (b.value ?? 0) == 0.5).length,
        1,
        reason: 'urbanCruise row should render at 50% progress',
      );
      // The other 5 are at 0.
      expect(bars.where((b) => (b.value ?? -1) == 0.0).length, 5);
    });

    testWidgets(
        'full confidence: a situation that hits the cap renders at '
        '100% — the user needs to see "this mode is fully learned" '
        'without doing the math', (tester) async {
      await pumpApp(
        tester,
        _host(),
        overrides: [
          _summaryOverride(const {
            DrivingSituation.highwayCruise: 30,
          }),
        ],
      );

      expect(find.text('30/30'), findsOneWidget);

      final bars = tester
          .widgetList<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          )
          .toList();
      expect(bars.where((b) => (b.value ?? 0) == 1.0).length, 1);
    });

    testWidgets(
        'over-cap counts clamp to 100% — a long-running car can rack '
        'up >30 samples and the bar must NOT overflow past the right '
        'edge', (tester) async {
      await pumpApp(
        tester,
        _host(),
        overrides: [
          _summaryOverride(const {
            DrivingSituation.idle: 45,
          }),
        ],
      );

      // Raw count surfaces honestly — clamping is for the bar, not
      // the readout.
      expect(find.text('45/30'), findsOneWidget);

      final bars = tester
          .widgetList<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          )
          .toList();
      // Every bar is in [0.0, 1.0]; none exceeds the cap.
      for (final b in bars) {
        expect(b.value, isNotNull);
        expect(b.value!, lessThanOrEqualTo(1.0));
        expect(b.value!, greaterThanOrEqualTo(0.0));
      }
      // The over-cap row specifically lands at 1.0 (the clamped max).
      expect(bars.where((b) => b.value == 1.0).length, 1);
    });

    testWidgets(
        'all 6 persisted situations render — transients (hardAccel, '
        'fuelCutCoast) must NOT appear because they never accumulate '
        'samples and would mislead the user about calibration scope',
        (tester) async {
      await pumpApp(
        tester,
        _host(),
        overrides: [_summaryOverride(const {})],
      );

      // Six persisted-situation labels.
      expect(find.text('Idle'), findsOneWidget);
      expect(find.text('Stop & go'), findsOneWidget);
      expect(find.text('Urban'), findsOneWidget);
      expect(find.text('Highway'), findsOneWidget);
      expect(find.text('Decelerating'), findsOneWidget);
      expect(find.text('Climbing / loaded'), findsOneWidget);

      // Transient enum names should never leak into the UI.
      expect(find.text('hardAccel'), findsNothing);
      expect(find.text('fuelCutCoast'), findsNothing);

      // Exactly 6 progress bars — one per persisted situation.
      expect(find.byType(LinearProgressIndicator), findsNWidgets(6));
    });

    testWidgets(
        'reset button is enabled once any sample exists, and tapping '
        'it surfaces the confirm dialog so a stray tap does not wipe '
        'a hard-earned baseline', (tester) async {
      await pumpApp(
        tester,
        _host(),
        overrides: [
          _summaryOverride(const {
            DrivingSituation.idle: 4,
          }),
        ],
      );

      final reset = find.byKey(const Key('resetBaselinesButton'));
      expect(reset, findsOneWidget);

      // Button is enabled — onPressed is non-null when totalSamples > 0.
      final btn = tester.widget<TextButton>(reset);
      expect(btn.onPressed, isNotNull);

      await tester.tap(reset);
      await tester.pumpAndSettle();

      // Confirm dialog title + body are visible. #1219 — title now
      // explicitly names "driving-situation baseline" so users can
      // distinguish it from the volumetric-efficiency reset.
      expect(
        find.text('Reset driving-situation baseline?'),
        findsOneWidget,
      );
      expect(find.textContaining('wipes every learned sample'), findsOneWidget);
    });

    testWidgets(
        'confirm dialog Cancel button dismisses without invoking the '
        'reset provider — guarding against accidental wipes is the '
        'whole reason the dialog exists', (tester) async {
      var resetCalls = 0;
      await pumpApp(
        tester,
        _host(),
        overrides: [
          _summaryOverride(const {
            DrivingSituation.idle: 4,
          }),
          resetVehicleBaselinesProvider(_vehicleId).overrideWith((ref) async {
            resetCalls++;
          }),
        ],
      );

      await tester.tap(find.byKey(const Key('resetBaselinesButton')));
      await tester.pumpAndSettle();

      // Tap the Cancel action in the dialog.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog gone, provider untouched.
      expect(
        find.text('Reset driving-situation baseline?'),
        findsNothing,
      );
      expect(resetCalls, 0);
    });

    testWidgets(
        'confirm dialog Reset button invokes resetVehicleBaselinesProvider '
        '— wiring the dialog to the provider is the whole feature, so '
        'a regression here breaks user-driven recalibration',
        (tester) async {
      var resetCalls = 0;
      await pumpApp(
        tester,
        _host(),
        overrides: [
          _summaryOverride(const {
            DrivingSituation.idle: 4,
          }),
          resetVehicleBaselinesProvider(_vehicleId).overrideWith((ref) async {
            resetCalls++;
          }),
        ],
      );

      await tester.tap(find.byKey(const Key('resetBaselinesButton')));
      await tester.pumpAndSettle();

      // The dialog has TWO "Reset driving-situation baseline" texts:
      // the original button (still on screen behind the dialog) and
      // the FilledButton in the dialog. Tap the FilledButton.
      await tester.tap(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.text('Reset driving-situation baseline'),
        ),
      );
      await tester.pumpAndSettle();

      expect(resetCalls, 1);
    });

    testWidgets(
        'localized title surfaces — confirms the section title text '
        'comes through AppLocalizations rather than the English '
        'fallback hardcoded inside the widget', (tester) async {
      await pumpApp(
        tester,
        _host(),
        overrides: [_summaryOverride(const {})],
      );

      expect(find.text('Baseline calibration'), findsOneWidget);
    });

    testWidgets(
        'reset button uses the tune_outlined icon and the explicit '
        '"driving-situation baseline" label so users can tell it apart '
        'from the η_v reset on the same screen (#1219)',
        (tester) async {
      await pumpApp(
        tester,
        _host(),
        overrides: [
          _summaryOverride(const {
            DrivingSituation.idle: 4,
          }),
        ],
      );

      // Distinct icon — tune_outlined, not the generic restart_alt.
      expect(
        find.descendant(
          of: find.byKey(const Key('resetBaselinesButton')),
          matching: find.byIcon(Icons.tune_outlined),
        ),
        findsOneWidget,
      );
      // Explicit label — names the cleared data, not just "reset".
      expect(
        find.text('Reset driving-situation baseline'),
        findsOneWidget,
      );
    });
  });
}
