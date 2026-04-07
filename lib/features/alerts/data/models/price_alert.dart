import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../search/domain/entities/fuel_type.dart';

part 'price_alert.freezed.dart';
part 'price_alert.g.dart';

@freezed
abstract class PriceAlert with _$PriceAlert {
  const factory PriceAlert({
    required String id,
    required String stationId,
    required String stationName,
    @FuelTypeJsonConverter() required FuelType fuelType,
    required double targetPrice,
    @Default(true) bool isActive,
    DateTime? lastTriggeredAt,
    required DateTime createdAt,
  }) = _PriceAlert;

  factory PriceAlert.fromJson(Map<String, dynamic> json) =>
      _$PriceAlertFromJson(json);
}
