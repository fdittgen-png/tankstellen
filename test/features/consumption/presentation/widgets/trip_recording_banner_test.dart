import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_recording_controller.dart';
import 'package:tankstellen/features/consumption/domain/cold_start_baselines.dart';
import 'package:tankstellen/features/consumption/domain/situation_classifier.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_recording_banner.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

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

  // #1322 — TripRecordingBanner sits inside MaterialApp.builder, so
  // its build context can be ABOVE the Router/Navigator subtree on
  // certain modal paths (e.g. /privacy-dashboard). GoRouter.of throws
  // "No GoRouter found in context" there. Verify the banner now uses
  // GoRouter.maybeOf and falls back to a snackbar instead of crashing.
  group('TripRecordingBanner GoRouter fallback (#1322)', () {
    testWidgets(
        'tap with no GoRouter ancestor does not throw — '
        'falls back gracefully on /privacy-dashboard-style modal paths',
        (tester) async {
      // Plain MaterialApp (no .router constructor) means the InheritedWidget
      // lookup for GoRouter will return null, mirroring the production
      // crash on /privacy-dashboard.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tripRecordingProvider.overrideWith(
              () => _FakeTripRecording(_activeState(
                band: ConsumptionBand.normal,
                distance: 1.0,
              )),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: TripRecordingBanner(child: SizedBox()),
            ),
          ),
        ),
      );
      await tester.pump();

      // Sanity: banner is mounted.
      expect(find.byKey(const Key('tripRecordingBanner')), findsOneWidget);

      // Tapping must not throw — the production trace was a hard crash.
      await tester.tap(find.byKey(const Key('tripRecordingBanner')));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'tap with no GoRouter ancestor surfaces snackbar pointing '
        'the user at the consumption tab — silent no-op would be worse',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tripRecordingProvider.overrideWith(
              () => _FakeTripRecording(_activeState(
                band: ConsumptionBand.normal,
                distance: 1.0,
              )),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: TripRecordingBanner(child: SizedBox()),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('tripRecordingBanner')));
      // SnackBar uses a slide animation — pump a few frames to let it
      // mount, but don't pumpAndSettle (the banner shows no spinner
      // here, but the SnackBar dismissal timer could otherwise dangle).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Open the active trip from the Conso tab'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'tap with GoRouter ancestor pushes /trip-recording — '
        'regression for the happy path',
        (tester) async {
      final pushedLocations = <String>[];
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(
              body: TripRecordingBanner(child: SizedBox()),
            ),
          ),
          GoRoute(
            path: '/trip-recording',
            builder: (_, _) {
              pushedLocations.add('/trip-recording');
              return const Scaffold(body: Text('trip-recording-screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tripRecordingProvider.overrideWith(
              () => _FakeTripRecording(_activeState(
                band: ConsumptionBand.normal,
                distance: 1.0,
              )),
            ),
          ],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('tripRecordingBanner')), findsOneWidget);

      await tester.tap(find.byKey(const Key('tripRecordingBanner')));
      // GoRouter push triggers a route transition animation. Pump a
      // bounded number of frames rather than pumpAndSettle (in case
      // any descendant shows a continuous indicator on transition).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(pushedLocations, contains('/trip-recording'));
      expect(find.text('trip-recording-screen'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
