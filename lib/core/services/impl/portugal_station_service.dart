import 'package:dio/dio.dart';

import '../../../features/search/data/models/search_params.dart';
import '../../../features/search/domain/entities/station.dart';
import '../../error/exceptions.dart';
import '../../utils/geo_utils.dart';
import '../dio_factory.dart';
import '../service_result.dart';
import '../station_service.dart';
import '../mixins/station_service_helpers.dart';

/// DGEG (Direção-Geral de Energia e Geologia) Portuguese fuel price service.
///
/// Uses Portugal's open data portal for fuel station prices.
/// Free, no API key required. Data updated daily by DGEG.
///
/// API: https://precoscombustiveis.dgeg.gov.pt/api/PrecoComb/PesquisarPostos
/// Station detail: https://precoscombustiveis.dgeg.gov.pt/api/PrecoComb/GetDadosPosto?id={id}
/// No API key required. Reverse-engineered from the DGEG portal.
class PortugalStationService with StationServiceHelpers implements StationService {
  final Dio _dio = DioFactory.create(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  );

  static const _baseUrl = 'https://precoscombustiveis.dgeg.gov.pt/api/PrecoComb';

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    try {
      // DGEG provides a bulk dataset — fetch all stations and filter by distance
      final response = await _dio.get(
        '$_baseUrl/ListarDadosPostos',
        queryParameters: {
          'idsTiposComb': '', // All fuel types
          'idMarca': '',
          'idTipoPosto': '',
          'idDistrito': '',
          'idsMunicipios': '',
          'qtdPorPagina': 5000,
          'pagina': 1,
        },
        cancelToken: cancelToken,
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ApiException(message: 'Invalid DGEG response');
      }

      final resultado = data['resultado'] as List<dynamic>? ?? [];
      final stations = <Station>[];

      for (final item in resultado) {
        try {
          final lat = double.tryParse(item['Latitude']?.toString() ?? '');
          final lng = double.tryParse(item['Longitude']?.toString() ?? '');
          if (lat == null || lng == null) continue;

          final dist = distanceKm(params.lat, params.lng, lat, lng);
          if (dist > params.radiusKm) continue;

          // Parse prices from combustiveis array
          final combustiveis = item['Combustiveis'] as List<dynamic>? ?? [];
          double? gasolina95, gasolina98, gasoleo, gpl;
          for (final c in combustiveis) {
            final tipo = c['DescritivoCombustivel']?.toString() ?? '';
            final preco = double.tryParse(c['Preco']?.toString() ?? '');
            if (tipo.contains('95')) gasolina95 = preco;
            if (tipo.contains('98')) gasolina98 = preco;
            if (tipo.contains('asóleo') || tipo.contains('Diesel')) gasoleo = preco;
            if (tipo.contains('GPL')) gpl = preco;
          }

          stations.add(Station(
            id: 'pt-${item['Id'] ?? item['CodPosto'] ?? stations.length}',
            name: item['Nome']?.toString() ?? '',
            brand: item['Marca']?.toString() ?? '',
            street: item['Morada']?.toString() ?? '',
            postCode: item['CodPostal']?.toString() ?? '',
            place: item['Localidade']?.toString() ?? '',
            lat: lat,
            lng: lng,
            dist: dist,
            e5: gasolina95,
            e10: gasolina95, // Portugal uses 95 as standard
            e98: gasolina98,
            diesel: gasoleo,
            lpg: gpl,
            isOpen: true,
          ));
        } catch (_) {
          continue;
        }
      }

      // Sort by distance
      stations.sort((a, b) => a.dist.compareTo(b.dist));

      return ServiceResult(
        data: stations.take(50).toList(),
        source: ServiceSource.portugalApi,
        fetchedAt: DateTime.now(),
      );
    } on DioException catch (e) {
      throw ApiException(
        message: e.message ?? 'DGEG API error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String stationId) async {
    throw const ApiException(message: 'Station detail not supported for Portugal');
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(List<String> ids) async {
    return ServiceResult(data: {}, source: ServiceSource.portugalApi, fetchedAt: DateTime.now());
  }
}
