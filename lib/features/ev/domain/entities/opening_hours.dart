import 'package:freezed_annotation/freezed_annotation.dart';

part 'opening_hours.freezed.dart';
part 'opening_hours.g.dart';

/// A single opening period on one weekday.
///
/// `weekday` is 1 (Monday) through 7 (Sunday) to match ISO 8601 and
/// `DateTime.weekday`. `periodBegin` / `periodEnd` use 24h local `HH:mm`
/// strings as in OCPI.
@freezed
abstract class RegularHours with _$RegularHours {
  const factory RegularHours({
    required int weekday,
    required String periodBegin,
    required String periodEnd,
  }) = _RegularHours;

  factory RegularHours.fromJson(Map<String, dynamic> json) =>
      _$RegularHoursFromJson(json);
}

/// Station opening hours, OCPI-style.
///
/// Either [twentyFourSeven] is true and [regularHours] is ignored, or the
/// station advertises a list of weekday windows in [regularHours].
@freezed
abstract class OpeningHours with _$OpeningHours {
  const factory OpeningHours({
    @Default(false) bool twentyFourSeven,
    @Default(<RegularHours>[])
    @RegularHoursListConverter()
    List<RegularHours> regularHours,
  }) = _OpeningHours;

  factory OpeningHours.fromJson(Map<String, dynamic> json) =>
      _$OpeningHoursFromJson(json);
}

/// Serializes a list of [RegularHours] as plain JSON maps so the parent
/// does not embed object instances directly in its `toJson` output.
class RegularHoursListConverter
    implements JsonConverter<List<RegularHours>, List<dynamic>> {
  const RegularHoursListConverter();

  @override
  List<RegularHours> fromJson(List<dynamic> json) => json
      .whereType<Map<dynamic, dynamic>>()
      .map((e) => RegularHours.fromJson(Map<String, dynamic>.from(e)))
      .toList();

  @override
  List<Map<String, dynamic>> toJson(List<RegularHours> object) =>
      object.map((c) => c.toJson()).toList();
}
