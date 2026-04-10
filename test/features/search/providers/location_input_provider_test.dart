import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/location_search_service.dart';
import 'package:tankstellen/features/search/providers/location_input_provider.dart';

void main() {
  ProviderContainer makeContainer() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  const city1 = ResolvedLocation(
    name: 'Montpellier',
    lat: 43.6,
    lng: 3.88,
    postcode: '34000',
  );
  const city2 = ResolvedLocation(
    name: 'Nimes',
    lat: 43.83,
    lng: 4.35,
    postcode: '30000',
  );

  group('LocationInputController', () {
    test('initial state: GPS type, empty suggestions', () {
      final c = makeContainer();
      final s = c.read(locationInputControllerProvider);
      expect(s.inputType, LocationInputType.gps);
      expect(s.suggestions, isEmpty);
      expect(s.selectedCity, isNull);
      expect(s.isSearching, isFalse);
    });

    test('setInputType(zip) clears suggestions and selected city', () {
      final c = makeContainer();
      final ctrl = c.read(locationInputControllerProvider.notifier);
      ctrl.setSuggestions(const [city1, city2]);
      ctrl.selectCity(city1);
      ctrl.setInputType(LocationInputType.zip);

      final s = c.read(locationInputControllerProvider);
      expect(s.inputType, LocationInputType.zip);
      expect(s.suggestions, isEmpty);
      expect(s.selectedCity, isNull);
    });

    test('setInputType(city) keeps existing suggestions', () {
      final c = makeContainer();
      final ctrl = c.read(locationInputControllerProvider.notifier);
      ctrl.setSuggestions(const [city1]);
      ctrl.setInputType(LocationInputType.city);

      expect(
        c.read(locationInputControllerProvider).suggestions,
        hasLength(1),
      );
    });

    test('selectCity stores city and clears suggestions', () {
      final c = makeContainer();
      final ctrl = c.read(locationInputControllerProvider.notifier);
      ctrl.setSuggestions(const [city1, city2]);
      ctrl.selectCity(city2);

      final s = c.read(locationInputControllerProvider);
      expect(s.selectedCity, city2);
      expect(s.suggestions, isEmpty);
    });

    test('setSearching toggles isSearching flag', () {
      final c = makeContainer();
      final ctrl = c.read(locationInputControllerProvider.notifier);
      ctrl.setSearching(true);
      expect(c.read(locationInputControllerProvider).isSearching, isTrue);
      ctrl.setSearching(false);
      expect(c.read(locationInputControllerProvider).isSearching, isFalse);
    });

    test('clear resets everything to defaults', () {
      final c = makeContainer();
      final ctrl = c.read(locationInputControllerProvider.notifier);
      ctrl.setSuggestions(const [city1]);
      ctrl.selectCity(city1);
      ctrl.setSearching(true);
      ctrl.clear();

      final s = c.read(locationInputControllerProvider);
      expect(s.inputType, LocationInputType.gps);
      expect(s.suggestions, isEmpty);
      expect(s.selectedCity, isNull);
      expect(s.isSearching, isFalse);
    });
  });
}
