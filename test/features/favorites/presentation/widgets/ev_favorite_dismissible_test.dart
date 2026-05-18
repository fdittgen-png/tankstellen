import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/favorites/presentation/widgets/ev_favorite_card.dart';
import 'package:tankstellen/features/favorites/presentation/widgets/ev_favorite_dismissible.dart';
import 'package:tankstellen/features/favorites/providers/ev_favorites_provider.dart';

import '../../../../helpers/pump_app.dart';

/// Regression tests for #1958 — EV-charger favorites must be swipeable
/// like fuel-station favorites (`FavoriteStationDismissible`).
const _ev = ChargingStation(
  id: 'ev-charger-7',
  name: 'IECharge Anduze',
  latitude: 44.05,
  longitude: 3.99,
);

/// Test double for [EvFavorites] — records `remove` / `add` so the
/// swipe-left and undo paths can be asserted without real storage.
class _RecordingEvFavorites extends EvFavorites {
  final List<String> removeCalls = <String>[];
  final List<({String id, ChargingStation? station})> addCalls = [];

  @override
  List<String> build() => const ['ev-charger-7'];

  @override
  Future<void> remove(String stationId) async => removeCalls.add(stationId);

  @override
  Future<void> add(String stationId, {ChargingStation? stationData}) async =>
      addCalls.add((id: stationId, station: stationData));
}

void main() {
  group('EvFavoriteDismissible (#1958)', () {
    testWidgets('wraps the EV favorite in a swipeable Dismissible',
        (tester) async {
      await pumpApp(
        tester,
        const EvFavoriteDismissible(station: _ev),
        overrides: [
          evFavoritesProvider.overrideWith(_RecordingEvFavorites.new),
        ],
      );

      expect(find.byType(Dismissible), findsOneWidget);
      expect(find.byType(EvFavoriteCard), findsOneWidget);
    });

    testWidgets(
        'swipe-left removes the EV favorite and shows the undo snackbar',
        (tester) async {
      final recording = _RecordingEvFavorites();
      await pumpApp(
        tester,
        const EvFavoriteDismissible(station: _ev),
        overrides: [
          evFavoritesProvider.overrideWith(() => recording),
        ],
      );

      await tester.fling(
        find.byType(Dismissible),
        const Offset(-500, 0),
        1000,
      );
      await tester.pumpAndSettle();

      // Removal routed to the EV favorites notifier — not the fuel one.
      expect(recording.removeCalls, ['ev-charger-7']);
      expect(
        find.textContaining('removed from favorites'),
        findsOneWidget,
      );
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('the undo action re-adds the charger with its station data',
        (tester) async {
      final recording = _RecordingEvFavorites();
      await pumpApp(
        tester,
        const EvFavoriteDismissible(station: _ev),
        overrides: [
          evFavoritesProvider.overrideWith(() => recording),
        ],
      );

      await tester.fling(
        find.byType(Dismissible),
        const Offset(-500, 0),
        1000,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(recording.addCalls, hasLength(1));
      expect(recording.addCalls.single.id, 'ev-charger-7');
      expect(recording.addCalls.single.station?.id, 'ev-charger-7');
    });
  });
}
