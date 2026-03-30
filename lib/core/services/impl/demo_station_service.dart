import 'dart:math';

import 'package:dio/dio.dart';

import '../../../features/search/data/models/search_params.dart';
import '../../../features/search/domain/entities/station.dart';
import '../service_result.dart';
import '../station_service.dart';

/// Demo data provider — works without any API key or network.
/// Returns realistic sample stations near the search coordinates.
/// Stores generated stations so detail lookups return consistent data.
class DemoStationService implements StationService {
  final String countryCode;
  DemoStationService({this.countryCode = 'DE'});

  // Cache generated stations so detail view returns the same data
  final Map<String, Station> _generatedStations = {};

  static final _random = Random(42);

  static const _brandsByCountry = {
    'DE': ['ARAL', 'Shell', 'TOTAL', 'JET', 'ESSO', 'Star', 'HEM'],
    'FR': ['TotalEnergies', 'Leclerc', 'Carrefour', 'Intermarché', 'Auchan', 'BP', 'Shell'],
    'AT': ['OMV', 'BP', 'Shell', 'Jet', 'Eni', 'Avanti'],
    'ES': ['Repsol', 'Cepsa', 'BP', 'Shell', 'Galp'],
    'IT': ['Eni', 'IP', 'Q8', 'TotalErg', 'Tamoil', 'Shell'],
  };

  static const _streetsByCountry = {
    'DE': ['Hauptstraße', 'Bahnhofstr.', 'Berliner Allee', 'Industriestr.'],
    'FR': ['Avenue de la République', 'Rue du Commerce', 'Boulevard Victor Hugo', 'Route Nationale', 'Rue de la Gare'],
    'AT': ['Hauptstraße', 'Wiener Straße', 'Grazer Straße'],
    'ES': ['Calle Mayor', 'Avenida de la Constitución', 'Carretera Nacional'],
    'IT': ['Via Roma', 'Via Garibaldi', 'Corso Italia'],
  };

  List<String> get _brands => _brandsByCountry[countryCode] ?? _brandsByCountry['DE']!;
  List<String> get _streets => _streetsByCountry[countryCode] ?? _streetsByCountry['DE']!;

  @override
  Future<ServiceResult<List<Station>>> searchStations(SearchParams params, {CancelToken? cancelToken}) async {
    await Future<void>.delayed(Duration(milliseconds: 200 + _random.nextInt(300)));

    final count = 5 + _random.nextInt(8);
    final stations = List.generate(count, (i) {
      final latOffset = (_random.nextDouble() - 0.5) * params.radiusKm / 55.0;
      final lngOffset = (_random.nextDouble() - 0.5) * params.radiusKm / 55.0;
      final dist = (latOffset.abs() + lngOffset.abs()) * 55.0;
      final brand = _brands[i % _brands.length];
      final basePrice = 1.35 + _random.nextDouble() * 0.25;

      final station = Station(
        id: 'demo-${params.lat.toStringAsFixed(3)}-${params.lng.toStringAsFixed(3)}-$i',
        name: '$brand Station',
        brand: brand,
        street: '${_streets[i % _streets.length]} ${1 + _random.nextInt(200)}',
        postCode: params.postalCode ?? '',
        place: params.locationName ?? 'Demo',
        lat: params.lat + latOffset,
        lng: params.lng + lngOffset,
        dist: double.parse(dist.toStringAsFixed(1)),
        e5: double.parse((basePrice + 0.02).toStringAsFixed(3)),
        e10: double.parse(basePrice.toStringAsFixed(3)),
        diesel: double.parse((basePrice - 0.08).toStringAsFixed(3)),
        isOpen: _random.nextDouble() > 0.15,
      );

      _generatedStations[station.id] = station;
      return station;
    });

    if (params.sortBy == SortBy.price) {
      stations.sort((a, b) => (a.e10 ?? 99).compareTo(b.e10 ?? 99));
    } else {
      stations.sort((a, b) => a.dist.compareTo(b.dist));
    }

    return ServiceResult(
      data: stations,
      source: ServiceSource.cache,
      fetchedAt: DateTime.now(),
    );
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String stationId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));

    // Return cached station from search results
    final cached = _generatedStations[stationId];
    if (cached != null) {
      return ServiceResult(
        data: StationDetail(
          station: cached,
          openingTimes: const [
            OpeningTime(text: 'Mon-Fri', start: '06:00:00', end: '22:00:00'),
            OpeningTime(text: 'Sat', start: '07:00:00', end: '22:00:00'),
            OpeningTime(text: 'Sun', start: '08:00:00', end: '20:00:00'),
          ],
        ),
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
      );
    }

    // Fallback: generate a basic station
    final basePrice = 1.35 + _random.nextDouble() * 0.25;
    return ServiceResult(
      data: StationDetail(
        station: Station(
          id: stationId,
          name: '${_brands[0]} Station',
          brand: _brands[0],
          street: _streets[0],
          postCode: '',
          place: 'Demo',
          lat: 0, lng: 0,
          isOpen: true,
          e5: double.parse((basePrice + 0.02).toStringAsFixed(3)),
          e10: double.parse(basePrice.toStringAsFixed(3)),
          diesel: double.parse((basePrice - 0.08).toStringAsFixed(3)),
        ),
      ),
      source: ServiceSource.cache,
      fetchedAt: DateTime.now(),
    );
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(List<String> ids) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final prices = <String, StationPrices>{};
    for (final id in ids) {
      final cached = _generatedStations[id];
      prices[id] = StationPrices(
        e5: cached?.e5 ?? 1.459,
        e10: cached?.e10 ?? 1.439,
        diesel: cached?.diesel ?? 1.359,
        status: cached?.isOpen == true ? 'open' : 'closed',
      );
    }
    return ServiceResult(data: prices, source: ServiceSource.cache, fetchedAt: DateTime.now());
  }
}
