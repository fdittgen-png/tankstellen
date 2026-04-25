import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/impl/greece_parsers.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

/// One row in the `data` array of a `PriceResponse`. Mirrors the
/// Pydantic `PriceData` model from the community
/// [fuelpricesgr](https://github.com/mavroprovato/fuelpricesgr) FastAPI
/// wrapper:
/// `{ "fuel_type": "UNLEADED_95", "price": 1.721 }`.
///
/// Intentionally duplicated from `greece_station_service_test.dart` so
/// the parser suite stands alone — no shared fixture should make this
/// file's failure mode depend on the service file's tests.
Map<String, dynamic> _priceRow(String fuelType, dynamic price) =>
    <String, dynamic>{'fuel_type': fuelType, 'price': price};

/// Build a `PriceResponse`-shaped envelope for a given date.
Map<String, dynamic> _priceResponse({
  String date = '2026-04-21',
  List<Map<String, dynamic>>? rows,
}) {
  return <String, dynamic>{
    'date': date,
    'data': rows ??
        <Map<String, dynamic>>[
          _priceRow('UNLEADED_95', 1.721),
          _priceRow('UNLEADED_100', 1.969),
          _priceRow('DIESEL', 1.528),
          _priceRow('DIESEL_HEATING', 1.165),
          _priceRow('GAS', 0.978),
        ],
  };
}

/// The community API returns `list[PriceResponse]`. Wrap responses in
/// a list for the happy path.
List<Map<String, dynamic>> _envelope(List<Map<String, dynamic>> responses) =>
    responses;

void main() {
  group('fuelForObservatoryKey', () {
    test('canonical observatory keys map to fuel slots', () {
      expect(fuelForObservatoryKey('UNLEADED_95'), FuelType.e5);
      expect(fuelForObservatoryKey('UNLEADED_100'), FuelType.e98);
      expect(fuelForObservatoryKey('DIESEL'), FuelType.diesel);
      expect(fuelForObservatoryKey('GAS'), FuelType.lpg);
    });

    test('case-insensitive', () {
      expect(fuelForObservatoryKey('unleaded_95'), FuelType.e5);
      expect(fuelForObservatoryKey('Diesel'), FuelType.diesel);
      expect(fuelForObservatoryKey('Gas'), FuelType.lpg);
    });

    test('DIESEL_HEATING + SUPER are intentionally unmapped', () {
      expect(fuelForObservatoryKey('DIESEL_HEATING'), isNull);
      expect(fuelForObservatoryKey('SUPER'), isNull);
      expect(droppedObservatoryKeys, contains('diesel_heating'));
      expect(droppedObservatoryKeys, contains('super'));
    });

    test('unknown keys return null without throwing', () {
      expect(fuelForObservatoryKey('hydrogen'), isNull);
      expect(fuelForObservatoryKey(''), isNull);
    });
  });

  group('parsePrefectureResponse', () {
    const attica = {
      'stationId': 'gr-attica',
      'displayName': 'Αττική / Attica',
      'place': 'Αθήνα',
      'lat': 37.9838,
      'lng': 23.7275,
    };

    Station? Function(dynamic) parseFor({
      double fromLat = 37.98,
      double fromLng = 23.73,
    }) {
      return (dynamic body) => parsePrefectureResponse(
            body,
            stationId: attica['stationId']! as String,
            displayName: attica['displayName']! as String,
            place: attica['place']! as String,
            prefectureLat: attica['lat']! as double,
            prefectureLng: attica['lng']! as double,
            fromLat: fromLat,
            fromLng: fromLng,
          );
    }

    test('happy path stamps all four supported fuels', () {
      final s = parseFor()(_envelope([_priceResponse()]));
      expect(s, isNotNull);
      expect(s!.id, 'gr-attica');
      expect(s.brand, 'Paratiritirio');
      expect(s.e5, closeTo(1.721, 0.0001));
      expect(s.e98, closeTo(1.969, 0.0001));
      expect(s.diesel, closeTo(1.528, 0.0001));
      expect(s.lpg, closeTo(0.978, 0.0001));
      expect(s.isOpen, isTrue);
    });

    test('picks the newest entry by ISO-8601 lexicographic order', () {
      final s = parseFor()(_envelope([
        _priceResponse(date: '2026-04-19', rows: [
          _priceRow('UNLEADED_95', 1.700),
        ]),
        _priceResponse(date: '2026-04-21', rows: [
          _priceRow('UNLEADED_95', 1.721),
        ]),
        _priceResponse(date: '2026-04-20', rows: [
          _priceRow('UNLEADED_95', 1.710),
        ]),
      ]));
      expect(s, isNotNull);
      expect(s!.e5, closeTo(1.721, 0.0001));
      expect(s.updatedAt, '2026-04-21');
    });

    test('empty list → null station (no synthetic pin)', () {
      expect(parseFor()(const <Map<String, dynamic>>[]), isNull);
    });

    test('non-list body raises ApiException', () {
      expect(
        () => parseFor()(<String, dynamic>{'oops': 'not a list'}),
        throwsA(isA<ApiException>()),
      );
    });

    test('null body raises ApiException', () {
      expect(
        () => parseFor()(null),
        throwsA(isA<ApiException>()),
      );
    });

    test('DIESEL_HEATING and SUPER are silently dropped', () {
      final s = parseFor()(_envelope([
        _priceResponse(rows: [
          _priceRow('DIESEL', 1.528),
          _priceRow('DIESEL_HEATING', 1.165),
          _priceRow('SUPER', 1.950),
        ]),
      ]));
      expect(s, isNotNull);
      expect(s!.diesel, closeTo(1.528, 0.0001));
      expect(s.e5, isNull);
      expect(s.e98, isNull);
    });

    test('zero or negative prices are rejected', () {
      final s = parseFor()(_envelope([
        _priceResponse(rows: [
          _priceRow('UNLEADED_95', 0),
          _priceRow('DIESEL', -1.0),
          _priceRow('GAS', 0.978),
        ]),
      ]));
      expect(s, isNotNull);
      expect(s!.e5, isNull);
      expect(s.diesel, isNull);
      expect(s.lpg, closeTo(0.978, 0.0001));
    });

    test('numeric price strings are accepted', () {
      final s = parseFor()(_envelope([
        _priceResponse(rows: [
          _priceRow('UNLEADED_95', '1.721'),
        ]),
      ]));
      expect(s, isNotNull);
      expect(s!.e5, closeTo(1.721, 0.0001));
    });

    test('non-numeric price strings drop only that price', () {
      final s = parseFor()(_envelope([
        _priceResponse(rows: [
          _priceRow('UNLEADED_95', 1.721),
          _priceRow('DIESEL', 'N/A'),
        ]),
      ]));
      expect(s, isNotNull);
      expect(s!.e5, closeTo(1.721, 0.0001));
      expect(s.diesel, isNull);
    });

    test('zero recognised fuels → null station', () {
      final s = parseFor()(_envelope([
        _priceResponse(rows: [
          _priceRow('DIESEL_HEATING', 1.165),
          _priceRow('SUPER', 1.950),
        ]),
      ]));
      expect(s, isNull);
    });

    test('updatedAt reflects the newest response date', () {
      final s = parseFor()(_envelope([
        _priceResponse(date: '2026-04-21'),
      ]));
      expect(s, isNotNull);
      expect(s!.updatedAt, '2026-04-21');
    });

    test('stationId is threaded through unchanged (gr- prefix preserved)',
        () {
      final s = parseFor()(_envelope([_priceResponse()]));
      expect(s, isNotNull);
      expect(s!.id, startsWith('gr-'));
    });

    test('distance is rounded to 1 decimal', () {
      final s = parseFor(fromLat: 37.50, fromLng: 23.30)(
        _envelope([_priceResponse()]),
      );
      expect(s, isNotNull);
      final dist = s!.dist;
      expect(dist >= 0, isTrue);
      // Rounded to 1 decimal — re-rounding must equal itself.
      expect(double.parse(dist.toStringAsFixed(1)), dist);
    });
  });

  group('greekPrefectures catalog', () {
    test('contains the documented 8 entries', () {
      expect(greekPrefectures, hasLength(8));
    });

    test('every prefecture has a gr- prefixed id', () {
      for (final p in greekPrefectures) {
        expect(p.id, startsWith('gr-'),
            reason: '${p.apiName} must use the gr- prefix.');
      }
    });

    test('apiNames are the upstream observatory enum values', () {
      final names = greekPrefectures.map((p) => p.apiName).toSet();
      expect(names, contains('ATTICA'));
      expect(names, contains('THESSALONIKI'));
      expect(names, contains('CHANIA'));
    });

    test('every prefecture has plausible Greek mainland/island coords', () {
      // Greece sits roughly in lat 34..42, lng 19..30.
      for (final p in greekPrefectures) {
        expect(p.lat, inInclusiveRange(34.0, 42.0),
            reason: '${p.apiName} latitude out of Greek range.');
        expect(p.lng, inInclusiveRange(19.0, 30.0),
            reason: '${p.apiName} longitude out of Greek range.');
      }
    });
  });
}
