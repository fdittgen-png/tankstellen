import 'package:freezed_annotation/freezed_annotation.dart';

part 'service_result.freezed.dart';

/// Identifies which service or fallback provided the data.
enum ServiceSource {
  tankerkoenigApi('Tankerkönig API'),
  prixCarburantsApi('Prix-Carburants (gouv.fr)'),
  eControlApi('E-Control Spritpreisrechner'),
  mitecoApi('Geoportal Gasolineras (MITECO)'),
  miseApi('Osservaprezzi (MISE)'),
  denmarkApi('Danish Fuel APIs'),
  argentinaApi('Energía Argentina'),
  portugalApi('DGEG Portugal'),
  ukApi('CMA Fuel Finder'),
  australiaApi('FuelCheck NSW'),
  mexicoApi('CRE México'),
  luxembourgApi('Luxembourg (regulated)'),
  sloveniaApi('goriva.si'),
  openinetApi('OPINET (KNOC)'),
  osrmRouting('OSRM Routing'),
  openChargeMapApi('OpenChargeMap'),
  nominatimGeocoding('Nominatim (OSM)'),
  nativeGeocoding('Device Geocoding'),
  gpsLocation('GPS'),
  cache('Cache');

  final String displayName;
  const ServiceSource(this.displayName);
}

/// Wraps every service response with metadata about where it came from,
/// how fresh it is, and what errors were encountered along the fallback chain.
///
/// The UI uses this to show banners like "Data from cache (12 min ago)"
/// or "Tankerkoenig unavailable, showing cached data".
class ServiceResult<T> {
  final T data;
  final ServiceSource source;
  final DateTime fetchedAt;
  final bool isStale;
  final List<ServiceError> errors;

  const ServiceResult({
    required this.data,
    required this.source,
    required this.fetchedAt,
    this.isStale = false,
    this.errors = const [],
  });

  /// True if any fallback errors were recorded (even if we got data).
  bool get hadFallbacks => errors.isNotEmpty;

  /// Human-readable summary of data freshness (locale-neutral).
  String get freshnessLabel {
    final age = DateTime.now().difference(fetchedAt);
    if (age.inSeconds < 60) return '< 1 min';
    if (age.inMinutes < 60) return '${age.inMinutes} min';
    if (age.inHours < 24) return '${age.inHours} h';
    return '${age.inDays} d';
  }

  /// Summary for UI banners when fallbacks were used.
  String get fallbackSummary {
    if (errors.isEmpty) return '';
    final failedNames = errors.map((e) => e.source.displayName).join(', ');
    return '$failedNames unavailable. Using ${source.displayName}.';
  }
}

/// Records a single service failure in the fallback chain.
@freezed
abstract class ServiceError with _$ServiceError {
  const factory ServiceError({
    required ServiceSource source,
    required String message,
    int? statusCode,
    required DateTime occurredAt,
  }) = _ServiceError;
}
