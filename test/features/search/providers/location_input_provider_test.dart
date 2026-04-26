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
  const city3 = ResolvedLocation(
    name: 'Sete',
    lat: 43.4,
    lng: 3.7,
    postcode: '34200',
  );

  group('LocationInputState', () {
    test('default constructor yields GPS type, empty suggestions, no city, '
        'not searching', () {
      const s = LocationInputState();
      expect(s.inputType, LocationInputType.gps);
      expect(s.suggestions, isEmpty);
      expect(s.selectedCity, isNull);
      expect(s.isSearching, isFalse);
    });

    test('copyWith(inputType:) overrides only inputType', () {
      const base = LocationInputState(
        suggestions: [city1],
        selectedCity: city2,
        isSearching: true,
      );
      final next = base.copyWith(inputType: LocationInputType.zip);
      expect(next.inputType, LocationInputType.zip);
      expect(next.suggestions, base.suggestions);
      expect(next.selectedCity, city2);
      expect(next.isSearching, isTrue);
    });

    test('copyWith(suggestions:) overrides only suggestions', () {
      const base = LocationInputState(
        inputType: LocationInputType.city,
        suggestions: [city1],
        selectedCity: city2,
        isSearching: true,
      );
      final next = base.copyWith(suggestions: const [city3]);
      expect(next.suggestions, const [city3]);
      expect(next.inputType, LocationInputType.city);
      expect(next.selectedCity, city2);
      expect(next.isSearching, isTrue);
    });

    test('copyWith(selectedCity:) overrides only selectedCity', () {
      const base = LocationInputState(
        inputType: LocationInputType.city,
        suggestions: [city1],
        isSearching: true,
      );
      final next = base.copyWith(selectedCity: city2);
      expect(next.selectedCity, city2);
      expect(next.inputType, LocationInputType.city);
      expect(next.suggestions, const [city1]);
      expect(next.isSearching, isTrue);
    });

    test('copyWith(isSearching:) overrides only isSearching', () {
      const base = LocationInputState(
        inputType: LocationInputType.city,
        suggestions: [city1],
        selectedCity: city2,
      );
      final next = base.copyWith(isSearching: true);
      expect(next.isSearching, isTrue);
      expect(next.inputType, LocationInputType.city);
      expect(next.suggestions, const [city1]);
      expect(next.selectedCity, city2);
    });

    test('copyWith() with no args returns equal-by-value snapshot', () {
      const base = LocationInputState(
        inputType: LocationInputType.city,
        suggestions: [city1, city2],
        selectedCity: city2,
        isSearching: true,
      );
      final next = base.copyWith();
      expect(next.inputType, base.inputType);
      expect(next.suggestions, base.suggestions);
      expect(next.selectedCity, base.selectedCity);
      expect(next.isSearching, base.isSearching);
    });

    test('copyWith(clearSelectedCity: true) nulls out a non-null city', () {
      const base = LocationInputState(selectedCity: city1);
      final next = base.copyWith(clearSelectedCity: true);
      expect(next.selectedCity, isNull);
    });

    test('copyWith(clearSelectedCity: true) wins over a passed selectedCity',
        () {
      const base = LocationInputState(selectedCity: city1);
      final next = base.copyWith(
        clearSelectedCity: true,
        selectedCity: city2,
      );
      expect(next.selectedCity, isNull);
    });
  });

  group('LocationInputController', () {
    test('build() returns default LocationInputState', () {
      final c = makeContainer();
      final s = c.read(locationInputControllerProvider);
      expect(s.inputType, LocationInputType.gps);
      expect(s.suggestions, isEmpty);
      expect(s.selectedCity, isNull);
      expect(s.isSearching, isFalse);
    });

    test('initial state: GPS type, empty suggestions', () {
      final c = makeContainer();
      final s = c.read(locationInputControllerProvider);
      expect(s.inputType, LocationInputType.gps);
      expect(s.suggestions, isEmpty);
      expect(s.selectedCity, isNull);
      expect(s.isSearching, isFalse);
    });

    test('setInputType(city) keeps suggestions and clears selectedCity', () {
      final c = makeContainer();
      final ctrl = c.read(locationInputControllerProvider.notifier);
      ctrl.setSuggestions(const [city1, city2]);
      ctrl.selectCity(city1);
      // selectCity also clears suggestions, so re-seed before flipping type.
      ctrl.setSuggestions(const [city1, city2]);
      ctrl.setInputType(LocationInputType.city);

      final s = c.read(locationInputControllerProvider);
      expect(s.inputType, LocationInputType.city);
      expect(s.suggestions, hasLength(2));
      expect(s.selectedCity, isNull);
    });

    test('setInputType(zip) clears suggestions and selectedCity', () {
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

    test('setInputType(gps) clears suggestions and selectedCity', () {
      final c = makeContainer();
      final ctrl = c.read(locationInputControllerProvider.notifier);
      ctrl.setSuggestions(const [city1, city2]);
      ctrl.selectCity(city1);
      ctrl.setInputType(LocationInputType.gps);

      final s = c.read(locationInputControllerProvider);
      expect(s.inputType, LocationInputType.gps);
      expect(s.suggestions, isEmpty);
      expect(s.selectedCity, isNull);
    });

    test('setSearching(true) sets the flag and leaves other fields intact', () {
      final c = makeContainer();
      final ctrl = c.read(locationInputControllerProvider.notifier);
      ctrl.setSuggestions(const [city1]);
      ctrl.setInputType(LocationInputType.city);
      // setInputType(city) preserves suggestions but clears selectedCity, so
      // re-seed selectedCity afterwards to test that setSearching leaves it
      // untouched.
      ctrl.selectCity(city1);
      // selectCity wipes suggestions, restore them so we can verify they
      // survive setSearching.
      ctrl.setSuggestions(const [city1]);
      ctrl.setSearching(true);

      final s = c.read(locationInputControllerProvider);
      expect(s.isSearching, isTrue);
      expect(s.inputType, LocationInputType.city);
      expect(s.suggestions, hasLength(1));
      expect(s.selectedCity, city1);
    });

    test('setSearching(false) clears the flag and leaves other fields intact',
        () {
      final c = makeContainer();
      final ctrl = c.read(locationInputControllerProvider.notifier);
      ctrl.setInputType(LocationInputType.city);
      ctrl.setSuggestions(const [city1, city2]);
      ctrl.setSearching(true);
      ctrl.setSearching(false);

      final s = c.read(locationInputControllerProvider);
      expect(s.isSearching, isFalse);
      expect(s.inputType, LocationInputType.city);
      expect(s.suggestions, hasLength(2));
    });

    test('setSuggestions replaces the suggestions list', () {
      final c = makeContainer();
      final ctrl = c.read(locationInputControllerProvider.notifier);
      ctrl.setSuggestions(const [city1]);
      ctrl.setSuggestions(const [city2, city3]);

      final s = c.read(locationInputControllerProvider);
      expect(s.suggestions, const [city2, city3]);
    });

    test('selectCity sets selectedCity and clears suggestions', () {
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
      ctrl.setInputType(LocationInputType.city);
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
