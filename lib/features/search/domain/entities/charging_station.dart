import 'package:freezed_annotation/freezed_annotation.dart';

part 'charging_station.freezed.dart';
part 'charging_station.g.dart';

/// An EV charging station from OpenChargeMap.
///
/// Separate from [Station] because charging stations have fundamentally
/// different data (connectors, power, network) vs fuel stations (price per liter).
@freezed
abstract class ChargingStation with _$ChargingStation {
  const factory ChargingStation({
    required String id,
    required String name,
    required String operator,
    required double lat,
    required double lng,
    @Default(0) double dist,
    required String address,
    @Default('') String postCode,
    @Default('') String place,
    required List<Connector> connectors,
    @Default(0) int totalPoints,
    bool? isOperational,
    String? usageCost,
    String? updatedAt,
    String? countryCode,
  }) = _ChargingStation;

  factory ChargingStation.fromJson(Map<String, dynamic> json) =>
      _$ChargingStationFromJson(json);
}

/// A single charging connector at an EV station.
@freezed
abstract class Connector with _$Connector {
  const factory Connector({
    required String type,     // "CCS", "Type 2", "CHAdeMO", "Tesla"
    @Default(0) double powerKW,
    @Default(0) int quantity,
    String? currentType,      // "AC", "DC"
    String? status,           // "Available", "In Use", "Unknown"
  }) = _Connector;

  factory Connector.fromJson(Map<String, dynamic> json) =>
      _$ConnectorFromJson(json);
}
