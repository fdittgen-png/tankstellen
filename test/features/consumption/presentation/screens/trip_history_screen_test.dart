import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/core/feedback/auto_record_badge_provider.dart';
import 'package:tankstellen/core/widgets/empty_state.dart';
import 'package:tankstellen/core/widgets/page_scaffold.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/presentation/screens/trip_history_screen.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_history_card.dart';
import 'package:tankstellen/features/consumption/providers/trip_history_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/pump_app.dart';

/// Widget tests for `TripHistoryScreen` (#561 zero-coverage backlog +
/// #1004 phase 6).
///
/// The screen is a thin shell around `tripHistoryListProvider`: empty
/// list → `EmptyState`, non-empty → a `ListView.builder` of
/// `Dismissible`-wrapped `TripHistoryCard`s. Swipes call
/// `notifier.delete(tripId)`. The AppBar exposes a "Mark all as read"
/// affordance backed by `autoRecordBadgeCountProvider` (#1004 phase 6).

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

class _FixedTripHistoryList extends TripHistoryList {
  _FixedTripHistoryList(this._value);
  final List<TripHistoryEntry> _value;

  @override
  List<TripHistoryEntry> build() => _value;
}

class _FakeBadgeCount extends AutoRecordBadgeCount {
  _FakeBadgeCount(this._initial);
  final int _initial;
  int markAllCallCount = 0;

  @override
  int build() => _initial;

  @override
  Future<void> markAllAsRead() async {
    markAllCallCount++;
    state = 0;
  }

  @override
  Future<void> refresh() async {
    // No-op — tests drive state via constructor seeds.
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

Future<_FakeBadgeCount> _pumpScreen(
  WidgetTester tester, {
  required int badgeCount,
  List<TripHistoryEntry> trips = const [],
}) async {
  final fakeBadge = _FakeBadgeCount(badgeCount);
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const TripHistoryScreen(),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tripHistoryListProvider
            .overrideWith(() => _FixedTripHistoryList(trips)),
        autoRecordBadgeCountProvider.overrideWith(() => fakeBadge),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return fakeBadge;
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

      await tester.fling(
        find.byKey(const ValueKey('trip-a')),
        const Offset(-500, 0),
        2000,
      );
      await tester.pumpAndSettle();

      expect(notifier.deleteCallCount, 1);
      expect(notifier.lastDeletedId, 'trip-a');
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

      expect(find.byType(TripHistoryScreen), findsOneWidget);
      expect(find.text('ConsumptionStub'), findsNothing);

      await tester.tap(find.widgetWithIcon(IconButton, Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(TripHistoryScreen), findsNothing);
      expect(find.text('ConsumptionStub'), findsOneWidget);
    });
  });

  group('TripHistoryScreen badge clear (#1004 phase 6)', () {
    testWidgets('badge action is hidden when counter is 0', (tester) async {
      await _pumpScreen(tester, badgeCount: 0);
      expect(
        find.byKey(const Key('tripHistoryBadgeClear')),
        findsNothing,
      );
    });

    testWidgets('badge action is visible when counter is > 0',
        (tester) async {
      await _pumpScreen(tester, badgeCount: 3);
      expect(
        find.byKey(const Key('tripHistoryBadgeClear')),
        findsOneWidget,
      );
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('counter > 99 renders as 99+ to prevent overflow',
        (tester) async {
      await _pumpScreen(tester, badgeCount: 250);
      expect(find.text('99+'), findsOneWidget);
      expect(find.text('250'), findsNothing);
    });

    testWidgets('tapping the badge action runs markAllAsRead and hides it',
        (tester) async {
      final badge = await _pumpScreen(tester, badgeCount: 2);
      expect(badge.markAllCallCount, 0);

      await tester.tap(find.byKey(const Key('tripHistoryBadgeClear')));
      await tester.pumpAndSettle();

      expect(badge.markAllCallCount, 1);
      expect(
        find.byKey(const Key('tripHistoryBadgeClear')),
        findsNothing,
      );
    });

    testWidgets('badge action carries a tooltip for accessibility',
        (tester) async {
      await _pumpScreen(tester, badgeCount: 5);
      final btn = tester.widget<IconButton>(
        find.byKey(const Key('tripHistoryBadgeClear')),
      );
      expect(btn.tooltip, isNotNull);
      expect(btn.tooltip, isNotEmpty);
    });
  });
}
