import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/itinerary/domain/entities/saved_itinerary.dart';
import 'package:tankstellen/features/itinerary/presentation/screens/itineraries_screen.dart';
import 'package:tankstellen/features/itinerary/providers/itinerary_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('ItinerariesScreen', () {
    testWidgets('renders Scaffold with app bar', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
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
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
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
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
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
  });
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
