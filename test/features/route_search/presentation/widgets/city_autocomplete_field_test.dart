import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/services/location_search_service.dart';
import 'package:tankstellen/features/route_search/presentation/widgets/city_autocomplete_field.dart';

import 'package:dio/dio.dart';

class _MockCache extends Mock implements CacheManager {}

/// Programmable fake [LocationSearchService]: tests inject results or a
/// [Completer] to control timing for the loading-indicator path.
class _FakeLocationSearchService extends LocationSearchService {
  _FakeLocationSearchService(super.cache);

  /// Static results returned by [searchCities] when [completer] is null.
  List<ResolvedLocation> results = const [];

  /// When set, [searchCities] awaits this completer's future before
  /// returning. Tests use this to assert the loading indicator is shown
  /// while the async call is in flight.
  Completer<List<ResolvedLocation>>? completer;

  /// Records every query passed to [searchCities] for assertions.
  final List<String> queries = [];

  @override
  Future<List<ResolvedLocation>> searchCities(
    String query, {
    List<String> countryCodes = const [],
    CancelToken? cancelToken,
  }) async {
    queries.add(query);
    if (completer != null) {
      return completer!.future;
    }
    return results;
  }
}

Widget _harness({
  required TextEditingController controller,
  required LocationSearchService service,
  void Function(ResolvedLocation city)? onCitySelected,
  VoidCallback? onTextChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: CityAutocompleteField(
        controller: controller,
        searchService: service,
        label: 'Start',
        hint: 'Enter city',
        prefixIcon: Icons.place,
        onCitySelected: onCitySelected ?? (_) {},
        onTextChanged: onTextChanged ?? () {},
      ),
    ),
  );
}

void main() {
  late _MockCache cache;
  late _FakeLocationSearchService service;
  late TextEditingController controller;

  const berlin = ResolvedLocation(
    name: 'Berlin, Germany',
    lat: 52.52,
    lng: 13.405,
    postcode: '10115',
  );
  const bremen = ResolvedLocation(
    name: 'Bremen, Germany',
    lat: 53.07,
    lng: 8.80,
  );

  setUp(() {
    cache = _MockCache();
    service = _FakeLocationSearchService(cache);
    controller = TextEditingController();
  });

  tearDown(() => controller.dispose());

  testWidgets('renders TextField with label, hint and prefix icon',
      (tester) async {
    await tester.pumpWidget(
      _harness(controller: controller, service: service),
    );

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Enter city'), findsOneWidget);
    expect(find.byIcon(Icons.place), findsOneWidget);
  });

  testWidgets('debounced search fires after 800ms with the trimmed query',
      (tester) async {
    service.results = const [berlin];

    await tester.pumpWidget(
      _harness(controller: controller, service: service),
    );

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '  Berlin  ');

    // Right after typing, no search should have fired.
    expect(service.queries, isEmpty);

    // Wait past the 800ms debounce.
    await tester.pump(const Duration(milliseconds: 850));
    await tester.pumpAndSettle();

    expect(service.queries, ['Berlin']);
  });

  testWidgets('shows suggestion overlay after results return', (tester) async {
    service.results = const [berlin, bremen];

    await tester.pumpWidget(
      _harness(controller: controller, service: service),
    );

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Br');
    await tester.pump(const Duration(milliseconds: 850));
    await tester.pumpAndSettle();

    expect(find.text('Berlin, Germany'), findsOneWidget);
    expect(find.text('Bremen, Germany'), findsOneWidget);
  });

  testWidgets(
      'tapping a suggestion fills controller and invokes onCitySelected',
      (tester) async {
    service.results = const [berlin];
    ResolvedLocation? selected;

    await tester.pumpWidget(
      _harness(
        controller: controller,
        service: service,
        onCitySelected: (city) => selected = city,
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Berl');
    await tester.pump(const Duration(milliseconds: 850));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Berlin, Germany'));
    await tester.pumpAndSettle();

    expect(selected, isNotNull);
    expect(selected!.name, 'Berlin, Germany');
    expect(selected!.lat, 52.52);
    expect(selected!.lng, 13.405);
    expect(controller.text, 'Berlin, Germany');
    // Overlay closes after selection.
    expect(find.text('Berlin, Germany'), findsOneWidget); // still in field
  });

  testWidgets('query under 2 characters never calls searchCities',
      (tester) async {
    service.results = const [berlin];

    await tester.pumpWidget(
      _harness(controller: controller, service: service),
    );

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'a');
    await tester.pump(const Duration(milliseconds: 850));
    await tester.pumpAndSettle();

    expect(service.queries, isEmpty);
  });

  testWidgets('all-digit input (postal code) skips searchCities',
      (tester) async {
    service.results = const [berlin];

    await tester.pumpWidget(
      _harness(controller: controller, service: service),
    );

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '10115');
    await tester.pump(const Duration(milliseconds: 850));
    await tester.pumpAndSettle();

    expect(service.queries, isEmpty);
  });

  testWidgets('rapid typing only fires one search after settling',
      (tester) async {
    service.results = const [berlin];

    await tester.pumpWidget(
      _harness(controller: controller, service: service),
    );

    await tester.tap(find.byType(TextField));

    // Simulate rapid typing — each keystroke restarts the debounce timer.
    await tester.enterText(find.byType(TextField), 'B');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byType(TextField), 'Be');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byType(TextField), 'Ber');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byType(TextField), 'Berl');

    // Only after the last keystroke + 800ms should the search fire.
    await tester.pump(const Duration(milliseconds: 850));
    await tester.pumpAndSettle();

    expect(service.queries, ['Berl']);
  });

  testWidgets('onTextChanged fires for every keystroke', (tester) async {
    service.results = const [];
    var changes = 0;

    await tester.pumpWidget(
      _harness(
        controller: controller,
        service: service,
        onTextChanged: () => changes++,
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'B');
    await tester.enterText(find.byType(TextField), 'Be');
    await tester.enterText(find.byType(TextField), 'Ber');
    await tester.pump();

    expect(changes, 3);
  });

  testWidgets('shows CircularProgressIndicator while search is in flight',
      (tester) async {
    final pending = Completer<List<ResolvedLocation>>();
    service.completer = pending;

    await tester.pumpWidget(
      _harness(controller: controller, service: service),
    );

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Berl');

    // No spinner before the debounce fires.
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pump(const Duration(milliseconds: 850));
    // Don't pumpAndSettle — the search is still pending and the spinner
    // would never settle.

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Complete the pending search so the test can finish cleanly.
    pending.complete(const [berlin]);
    await tester.pump();
  });
}
