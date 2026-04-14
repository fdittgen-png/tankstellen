import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/providers/station_rating_provider.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/station_status_row.dart';

ServiceResult<dynamic> _result({DateTime? fetchedAt}) {
  return ServiceResult(
    data: const Object(),
    source: ServiceSource.tankerkoenigApi,
    fetchedAt: fetchedAt ?? DateTime.now().subtract(const Duration(seconds: 10)),
  );
}

Station _station({bool isOpen = true}) {
  return Station(
    id: 'st-1',
    name: 'Test',
    brand: 'JET',
    street: 'Hauptstr.',
    houseNumber: '12',
    postCode: '10115',
    place: 'Berlin',
    lat: 52.5,
    lng: 13.4,
    dist: 1.0,
    e5: 1.79,
    e10: 1.74,
    diesel: 1.65,
    isOpen: isOpen,
  );
}

/// Test stub for the keep-alive [StationRatings] notifier so we can seed
/// the rating without touching real Hive storage.
class _FakeStationRatings extends StationRatings {
  _FakeStationRatings(this._initial);
  final Map<String, int> _initial;
  @override
  Map<String, int> build() => _initial;
}

void main() {
  group('StationStatusRow', () {
    Future<void> pumpRow(
      WidgetTester tester, {
      required Station station,
      required ServiceResult<dynamic> serviceResult,
      int? rating,
    }) {
      final ratings = <String, int>{};
      if (rating != null) ratings[station.id] = rating;
      return tester.pumpWidget(
        ProviderScope(
          overrides: [
            stationRatingsProvider
                .overrideWith(() => _FakeStationRatings(ratings)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: StationStatusRow(
                station: station,
                serviceResult: serviceResult,
                stationId: station.id,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders the open status text when station is open',
        (tester) async {
      await pumpRow(
        tester,
        station: _station(isOpen: true),
        serviceResult: _result(),
      );
      expect(find.textContaining('Open —'), findsOneWidget);
    });

    testWidgets('renders the closed status text when station is closed',
        (tester) async {
      await pumpRow(
        tester,
        station: _station(isOpen: false),
        serviceResult: _result(),
      );
      expect(find.textContaining('Closed —'), findsOneWidget);
    });

    testWidgets('shows 5 star icons when a rating is present', (tester) async {
      await pumpRow(
        tester,
        station: _station(),
        serviceResult: _result(),
        rating: 4,
      );
      // Total icons = 1 status dot Container (not Icon) + 4 filled stars +
      // 1 outline star = 5 Icons.
      final filled = find.byIcon(Icons.star);
      final empty = find.byIcon(Icons.star_border);
      expect(filled, findsNWidgets(4));
      expect(empty, findsNWidgets(1));
    });

    testWidgets('hides star row when no rating is present', (tester) async {
      await pumpRow(
        tester,
        station: _station(),
        serviceResult: _result(),
        rating: null,
      );
      expect(find.byIcon(Icons.star), findsNothing);
      expect(find.byIcon(Icons.star_border), findsNothing);
    });
  });
}
