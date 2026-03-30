import 'package:freezed_annotation/freezed_annotation.dart';

part 'saved_itinerary.freezed.dart';
part 'saved_itinerary.g.dart';

/// A saved route itinerary, synced to the cloud for cross-device access.
@freezed
abstract class SavedItinerary with _$SavedItinerary {
  const factory SavedItinerary({
    required String id,
    required String name,
    required List<Map<String, dynamic>> waypoints,
    required double distanceKm,
    required double durationMinutes,
    @Default(false) bool avoidHighways,
    @Default('e10') String fuelType,
    @Default([]) List<String> selectedStationIds,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SavedItinerary;

  factory SavedItinerary.fromJson(Map<String, dynamic> json) =>
      _$SavedItineraryFromJson(json);
}
