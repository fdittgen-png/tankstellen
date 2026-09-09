// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/itinerary/domain/entities/saved_itinerary.dart';
import 'package:tankstellen/features/itinerary/presentation/screens/itineraries_screen.dart';
import 'package:tankstellen/features/itinerary/providers/itinerary_provider.dart';
import 'package:tankstellen/core/widgets/empty_state.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('ItinerariesScreen', () {
    testWidgets('renders Scaffold with app bar', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
      when(() => test.mockStorage.getItineraries()).thenReturn([]);

      await pumpApp(
        tester,
        const ItinerariesScreen(),
        overrides: [
          ...test.overrides,
          itineraryProvider.overrideWith(() => _EmptyItineraries()),
        ],
      );

      expect(find.byType(Scaffold), findsAtLeast(1));
      expect(find.text('Saved Routes'), findsOneWidget);
    });

    testWidgets('shows empty state when no saved routes', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
      when(() => test.mockStorage.getItineraries()).thenReturn([]);

      await pumpApp(
        tester,
        const ItinerariesScreen(),
        overrides: [
          ...test.overrides,
          itineraryProvider.overrideWith(() => _EmptyItineraries()),
        ],
      );

      expect(find.text('No saved routes'), findsOneWidget);
      expect(find.byIcon(Icons.route), findsOneWidget);
    });

    testWidgets('shows route list when itineraries exist', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
      when(() => test.mockStorage.getItineraries()).thenReturn([]);

      final itinerary = SavedItinerary(
        id: 'route-1',
        name: 'Berlin to Munich',
        waypoints: [
          {'lat': 52.52, 'lng': 13.405, 'label': 'Berlin'},
          {'lat': 48.14, 'lng': 11.58, 'label': 'Munich'},
        ],
        distanceKm: 580,
        durationMinutes: 360,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 3, 15),
      );

      await pumpApp(
        tester,
        const ItinerariesScreen(),
        overrides: [
          ...test.overrides,
          itineraryProvider
              .overrideWith(() => _FixedItineraries([itinerary])),
        ],
      );

      expect(find.text('Berlin to Munich'), findsOneWidget);
      expect(find.textContaining('580 km'), findsOneWidget);
    });

    // ---- #3993 ------------------------------------------------------

    testWidgets('while the first pull is running it says "loading", not '
        '"you have none" (#3993)', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
      when(() => test.mockStorage.getItineraries()).thenReturn([]);

      await pumpApp(
        tester,
        const ItinerariesScreen(),
        overrides: [
          ...test.overrides,
          itineraryProvider.overrideWith(() => _EmptyItineraries()),
          itineraryFirstLoadProvider.overrideWith(() => _LoadingFlag(true)),
        ],
        // The spinner never stops, so pumpAndSettle would wait forever.
        settle: false,
      );

      // The list is empty for a user whose routes are still on the
      // server. Stating "No saved routes" there is simply false.
      expect(find.byKey(const Key('itineraries_loading')), findsOneWidget);
      expect(find.byType(EmptyState), findsNothing);
      expect(find.text('No saved routes'), findsNothing);
    });

    testWidgets('once the pull has answered, an empty list IS the empty '
        'state (#3993)', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
      when(() => test.mockStorage.getItineraries()).thenReturn([]);

      await pumpApp(
        tester,
        const ItinerariesScreen(),
        overrides: [
          ...test.overrides,
          itineraryProvider.overrideWith(() => _EmptyItineraries()),
          itineraryFirstLoadProvider.overrideWith(() => _LoadingFlag(false)),
        ],
      );

      expect(find.byKey(const Key('itineraries_loading')), findsNothing);
      expect(find.text('No saved routes'), findsOneWidget);
    });

    testWidgets('swiping a route away offers an undo that restores it '
        '(#3993)', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
      when(() => test.mockStorage.getItineraries()).thenReturn([]);

      final itinerary = SavedItinerary(
        id: 'route-1',
        name: 'Berlin to Munich',
        waypoints: const [
          {'lat': 52.52, 'lng': 13.405, 'label': 'Berlin'},
        ],
        distanceKm: 580,
        durationMinutes: 360,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 3, 15),
      );
      final notifier = _RecordingItineraries([itinerary]);

      await pumpApp(
        tester,
        const ItinerariesScreen(),
        overrides: [
          ...test.overrides,
          itineraryProvider.overrideWith(() => notifier),
        ],
      );

      await tester.drag(
        find.text('Berlin to Munich'),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();
      // The shared swipe carries a confirmation (#3682) before the undo.
      final confirm = find.text('Delete');
      if (confirm.evaluate().isNotEmpty) {
        await tester.tap(confirm.last);
        await tester.pumpAndSettle();
      }

      expect(notifier.deleted, ['route-1']);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      // Restored VERBATIM — same id, same timestamps. A re-save would
      // resurrect the route as a different row in a different place.
      expect(notifier.restored, [itinerary]);
    });
  });
}

class _LoadingFlag extends ItineraryFirstLoad {
  _LoadingFlag(this._value);
  final bool _value;

  @override
  bool build() => _value;
}

class _RecordingItineraries extends ItineraryNotifier {
  _RecordingItineraries(this._items);
  final List<SavedItinerary> _items;
  final List<String> deleted = [];
  final List<SavedItinerary> restored = [];

  @override
  List<SavedItinerary> build() => _items;

  @override
  Future<void> delete(String id) async {
    deleted.add(id);
    state = state.where((i) => i.id != id).toList();
  }

  @override
  Future<void> restore(SavedItinerary itinerary) async {
    restored.add(itinerary);
    state = [...state, itinerary];
  }
}

class _EmptyItineraries extends ItineraryNotifier {
  @override
  List<SavedItinerary> build() => [];
}

class _FixedItineraries extends ItineraryNotifier {
  final List<SavedItinerary> _items;
  _FixedItineraries(this._items);

  @override
  List<SavedItinerary> build() => _items;
}
