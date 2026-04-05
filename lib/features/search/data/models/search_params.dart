import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/fuel_type.dart';
// Re-export SearchMode so existing data-layer callers keep working while
// presentation imports it straight from domain/.
export '../../domain/entities/search_mode.dart';

part 'search_params.freezed.dart';

@freezed
abstract class SearchParams with _$SearchParams {
  const factory SearchParams({
    required double lat,
    required double lng,
    @Default(10.0) double radiusKm,
    @Default(FuelType.all) FuelType fuelType,
    @Default(SortBy.price) SortBy sortBy,
    String? postalCode,
    String? locationName,
  }) = _SearchParams;
}

enum SortBy {
  price('price', 'Price'),
  distance('dist', 'Distance');

  final String apiValue;
  final String displayName;

  const SortBy(this.apiValue, this.displayName);
}

