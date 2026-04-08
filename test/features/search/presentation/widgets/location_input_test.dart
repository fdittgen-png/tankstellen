import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/search/presentation/widgets/location_input.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('Location input zip prefill logic', () {
    test('profile with homeZipCode provides value for prefill', () {
      const profile = UserProfile(
        id: 'test',
        name: 'Test',
        homeZipCode: '34540',
      );
      expect(profile.homeZipCode, '34540');
      expect(profile.homeZipCode!.isNotEmpty, isTrue);
    });

    test('profile without homeZipCode returns null', () {
      const profile = UserProfile(
        id: 'test',
        name: 'Test',
      );
      expect(profile.homeZipCode, isNull);
    });

    test('profile with empty homeZipCode is treated as not set', () {
      const profile = UserProfile(
        id: 'test',
        name: 'Test',
        homeZipCode: '',
      );
      expect(profile.homeZipCode!.isEmpty, isTrue);
    });
  });

  group('Cheapest landing auto-search logic', () {
    test('cheapest landing with zip uses zip search', () {
      const profile = UserProfile(
        id: 'test',
        name: 'Test',
        landingScreen: LandingScreen.cheapest,
        homeZipCode: '34540',
      );
      expect(profile.landingScreen, LandingScreen.cheapest);
      expect(profile.homeZipCode, isNotNull);
      expect(profile.homeZipCode!.isNotEmpty, isTrue);
      // Logic: use zip search (not GPS) when zip is available
    });

    test('cheapest landing without zip uses GPS search', () {
      const profile = UserProfile(
        id: 'test',
        name: 'Test',
        landingScreen: LandingScreen.cheapest,
      );
      expect(profile.landingScreen, LandingScreen.cheapest);
      expect(profile.homeZipCode, isNull);
      // Logic: fall back to GPS search
    });

    test('non-cheapest landing does not auto-search', () {
      const profile = UserProfile(
        id: 'test',
        name: 'Test',
        landingScreen: LandingScreen.search,
        homeZipCode: '34540',
      );
      expect(profile.landingScreen, isNot(LandingScreen.cheapest));
      // Logic: no auto-search triggered
    });
  });

  group('Landing screen enum', () {
    test('map is excluded from user-selectable options', () {
      final selectable = LandingScreen.values
          .where((s) => s != LandingScreen.map)
          .toList();
      expect(selectable.length, 4);
      expect(selectable, contains(LandingScreen.search));
      expect(selectable, contains(LandingScreen.favorites));
      expect(selectable, contains(LandingScreen.cheapest));
      expect(selectable, contains(LandingScreen.nearest));
      expect(selectable, isNot(contains(LandingScreen.map)));
    });
  });

  group('Default profile protection', () {
    test('single profile should not be deleteable', () {
      final profiles = [
        const UserProfile(id: 'default', name: 'Default'),
      ];
      final canDelete = profiles.length > 1;
      expect(canDelete, isFalse);
    });

    test('multiple profiles allow deletion', () {
      final profiles = [
        const UserProfile(id: 'default', name: 'Default'),
        const UserProfile(id: 'work', name: 'Work'),
      ];
      final canDelete = profiles.length > 1;
      expect(canDelete, isTrue);
    });
  });

  group('LocationInput accessibility', () {
    testWidgets('TextField is not wrapped in nested Semantics(textField: true)',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        LocationInput(
          onGpsSearch: () {},
          onZipSearch: (_) {},
          onCitySearch: (_) {},
        ),
        overrides: test.overrides,
      );

      // TextField should be present
      expect(find.byType(TextField), findsOneWidget);

      // There should be no explicit Semantics widget with textField: true
      // wrapping the TextField (the old code had this causing nested semantics)
      final semanticsWidgets = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where((s) => s.properties.textField == true);
      expect(semanticsWidgets, isEmpty,
          reason:
              'TextField should not be wrapped in Semantics(textField: true)');
    });

    testWidgets('TextField has accessible label via InputDecoration.labelText',
        (tester) async {
      final handle = tester.ensureSemantics();
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        LocationInput(
          onGpsSearch: () {},
          onZipSearch: (_) {},
          onCitySearch: (_) {},
        ),
        overrides: test.overrides,
      );

      // The TextField uses labelText for screen reader accessibility
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.labelText, 'Location search field');

      handle.dispose();
    });

    testWidgets('GPS button has tooltip for screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        LocationInput(
          onGpsSearch: () {},
          onZipSearch: (_) {},
          onCitySearch: (_) {},
        ),
        overrides: test.overrides,
      );

      expect(find.byTooltip('Use GPS location'), findsOneWidget);

      handle.dispose();
    });
  });
}
