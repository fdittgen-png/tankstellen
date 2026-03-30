import 'charging_station.dart';
import 'station.dart';

/// Unified result type for search results that can contain
/// either fuel stations or EV charging stations.
///
/// Enables polymorphic rendering in [SearchResultsList] and map markers.
sealed class SearchResultItem {
  double get lat;
  double get lng;
  double get dist;
  String get displayName;
  String get displayAddress;
  String get id;
}

class FuelStationResult implements SearchResultItem {
  final Station station;
  const FuelStationResult(this.station);

  @override double get lat => station.lat;
  @override double get lng => station.lng;
  @override double get dist => station.dist;
  @override String get displayName => station.brand.isNotEmpty && station.brand != 'Station'
      ? station.brand : station.name;
  @override String get displayAddress => station.street;
  @override String get id => station.id;
}

class EVStationResult implements SearchResultItem {
  final ChargingStation station;
  const EVStationResult(this.station);

  @override double get lat => station.lat;
  @override double get lng => station.lng;
  @override double get dist => station.dist;
  @override String get displayName => station.operator.isNotEmpty
      ? station.operator : station.name;
  @override String get displayAddress => station.address;
  @override String get id => station.id;

  /// Maximum power across all connectors.
  double get maxPowerKW => station.connectors.isEmpty
      ? 0
      : station.connectors.map((c) => c.powerKW).reduce((a, b) => a > b ? a : b);

  /// Unique connector type names.
  List<String> get connectorTypes =>
      station.connectors.map((c) => c.type).toSet().toList();
}
