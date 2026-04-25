import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/core/widgets/empty_state.dart';
import 'package:tankstellen/core/widgets/page_scaffold.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/presentation/screens/trip_history_screen.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_history_card.dart';
import 'package:tankstellen/features/consumption/providers/trip_history_provider.dart';

import '../../../../helpers/pump_app.dart';

/// Widget tests for `TripHistoryScreen` (#561 zero-coverage backlog).
///
/// The screen is a thin shell around `tripHistoryListProvider`: empty
/// list → `EmptyState`, non-empty → a `ListView.builder` of
/// `Dismissible`-wrapped `TripHistoryCard`s. Swipes call
/// `notifier.delete(tripId)`. The back button uses `context.pop()` so
/// the tests wrap the screen in a `GoRouter` with a stub initial route.

class _FakeTripHistoryList extends TripHistoryList {
  _FakeTripHistoryList(this._initial);

  final List<TripHistoryEntry> _initial;
  int deleteCallCount = 0;
  String? lastDeletedId;

  @override
  List<TripHistoryEntry> build() => _initial;

  @override
  Future<void> delete(String id) async {
    deleteCallCount++;
    lastDeletedId = id;
    state = state.where((e) => e.id != id).toList();
  }
}

TripHistoryEntry _entry({
  String id = 'trip-1',
  String? vehicleId = 'v1',
  double distanceKm = 12.3,
  DateTime? startedAt,
  DateTime? endedAt,
  String distanceSource = 'virtual',
}) {
  return TripHistoryEntry(
    id: id,
    vehicleId: vehicleId,
    summary: TripSummary(
      distanceKm: distanceKm,
      maxRpm: 0,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
      startedAt: startedAt ?? DateTime(2026, 4, 22, 10),
      endedAt: endedAt,
      distanceSource: distanceSource,
    ),
  );
}

Future<_FakeTripHistoryList> _pumpHistory(
  WidgetTester tester, {
  required List<TripHistoryEntry> trips,
}) async {
  final notifier = _FakeTripHistoryList(trips);
  final router = GoRouter(
    // Stub initial route gives `context.pop()` a parent to pop back to,
    // mirroring the real flow where the user lands on the consumption
    // screen and pushes the trip history on top.
    initialLocation: '/consumption-stub',
    routes: [
      GoRoute(
        path: '/consumption-stub',
        builder: (_, _) => const Scaffold(
          key: Key('consumption-stub'),
          body: Text('ConsumptionStub'),
        ),
      ),
      GoRoute(
        path: '/trips',
        builder: (_, _) => const TripHistoryScreen(),
      ),
    ],
  );
  await pumpApp(
    tester,
    MaterialApp.router(routerConfig: router),
    overrides: [
      tripHistoryListProvider.overrideWith(() => notifier),
    ],
  );
  unawaited(router.push('/trips'));
  await tester.pumpAndSettle();
  return notifier;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TripHistoryScreen — empty state', () {
    testWidgets(
        'renders EmptyState with localized copy when the list is empty',
        (tester) async {
      await _pumpHistory(tester, trips: const []);

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('No trips yet'), findsOneWidget);
      expect(
        find.textContaining('Connect an OBD2 adapter'),
        findsOneWidget,
      );
      // No ListView rendered when the list is empty.
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(TripHistoryCard), findsNothing);
    });
  });

  group('TripHistoryScreen — populated list', () {
    testWidgets('renders one TripHistoryCard per trip in a ListView',
        (tester) async {
      await _pumpHistory(
        tester,
        trips: [
          _entry(id: 'trip-a', distanceKm: 10),
          _entry(id: 'trip-b', distanceKm: 20),
          _entry(id: 'trip-c', distanceKm: 30),
        ],
      );

      expect(find.byType(EmptyState), findsNothing);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(TripHistoryCard), findsNWidgets(3));
    });

    testWidgets('every card is wrapped in a Dismissible keyed by trip id',
        (tester) async {
      await _pumpHistory(
        tester,
        trips: [
          _entry(id: 'trip-a'),
          _entry(id: 'trip-b'),
        ],
      );

      // Two `Dismissible`s — one per row. The screen keys them on
      // `ValueKey(trip.id)` so swipe-to-delete attaches to the right
      // entry across rebuilds.
      final dismissibles =
          tester.widgetList<Dismissible>(find.byType(Dismissible));
      expect(dismissibles.length, 2);
      expect(
        dismissibles.map((d) => d.key).toSet(),
        {const ValueKey('trip-a'), const ValueKey('trip-b')},
      );
    });

    testWidgets('swipe-to-dismiss invokes notifier.delete with the trip id',
        (tester) async {
      final notifier = await _pumpHistory(
        tester,
        trips: [
          _entry(id: 'trip-a'),
          _entry(id: 'trip-b'),
        ],
      );

      // Swipe the first card (trip-a) right-to-left → endToStart
      // direction. `fling` triggers the dismiss animation; we settle
      // afterwards so `onDismissed` runs.
      await tester.fling(
        find.byKey(const ValueKey('trip-a')),
        const Offset(-500, 0),
        2000,
      );
      await tester.pumpAndSettle();

      expect(notifier.deleteCallCount, 1);
      expect(notifier.lastDeletedId, 'trip-a');
      // After the optimistic state update only one row remains.
      expect(find.byType(TripHistoryCard), findsOneWidget);
    });
  });

  group('TripHistoryScreen — chrome', () {
    testWidgets('renders a PageScaffold with the localized title',
        (tester) async {
      await _pumpHistory(tester, trips: const []);

      expect(find.byType(PageScaffold), findsOneWidget);
      expect(find.text('Trip history'), findsOneWidget);
    });

    testWidgets('back IconButton carries the localized tooltip',
        (tester) async {
      await _pumpHistory(tester, trips: const []);

      // One IconButton in the leading slot — the back arrow.
      final back = find.widgetWithIcon(IconButton, Icons.arrow_back);
      expect(back, findsOneWidget);
      final button = tester.widget<IconButton>(back);
      expect(button.tooltip, 'Back');
    });

    testWidgets('back IconButton pops the navigation stack', (tester) async {
      await _pumpHistory(
        tester,
        trips: [_entry(id: 'trip-a')],
      );

      // We are on /trips with /consumption-stub underneath.
      expect(find.byType(TripHistoryScreen), findsOneWidget);
      expect(find.text('ConsumptionStub'), findsNothing);

      await tester.tap(find.widgetWithIcon(IconButton, Icons.arrow_back));
      await tester.pumpAndSettle();

      // Pop returned us to the stub; the history screen is gone.
      expect(find.byType(TripHistoryScreen), findsNothing);
      expect(find.text('ConsumptionStub'), findsOneWidget);
    });
  });
}
