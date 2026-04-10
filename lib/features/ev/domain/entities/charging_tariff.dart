import 'package:freezed_annotation/freezed_annotation.dart';

part 'charging_tariff.freezed.dart';
part 'charging_tariff.g.dart';

/// OCPI-style tariff type.
///
/// Mirrors the OCPI 2.2.1 `TariffType` enum loosely, reduced to the
/// categories that actually appear in the sources we ingest.
enum TariffType {
  regular('regular'),
  adHocPayment('ad_hoc_payment'),
  profileCheap('profile_cheap'),
  profileFast('profile_fast'),
  profileGreen('profile_green');

  final String key;
  const TariffType(this.key);

  static TariffType fromKey(String? value) {
    if (value == null) return TariffType.regular;
    for (final v in TariffType.values) {
      if (v.key == value) return v;
    }
    return TariffType.regular;
  }
}

/// Type of a single price component inside a tariff element.
///
/// Matches the OCPI 2.2.1 `PriceComponent.type` enumeration:
/// - [energy] — price per kWh delivered
/// - [flat] — fixed session fee, charged once
/// - [time] — price per second of charging (we expose it per-minute)
/// - [parkingTime] — price per second of parking while not charging
/// - [blockingTime] — price per second after charging completes
enum PriceComponentType {
  energy('energy'),
  flat('flat'),
  time('time'),
  parkingTime('parking_time'),
  blockingTime('blocking_time');

  final String key;
  const PriceComponentType(this.key);

  static PriceComponentType fromKey(String? value) {
    if (value == null) return PriceComponentType.energy;
    for (final v in PriceComponentType.values) {
      if (v.key == value) return v;
    }
    return PriceComponentType.energy;
  }
}

/// A single OCPI price component inside a [TariffElement].
///
/// `price` is denominated in the parent [ChargingTariff.currency]. `stepSize`
/// is the billing granularity in the unit of the component type (Wh for
/// energy, seconds for time/parkingTime/blockingTime, 1 for flat).
@freezed
abstract class TariffComponent with _$TariffComponent {
  const factory TariffComponent({
    @PriceComponentTypeJsonConverter()
    @Default(PriceComponentType.energy)
    PriceComponentType type,
    @Default(0) double price,
    @Default(1) int stepSize,
  }) = _TariffComponent;

  factory TariffComponent.fromJson(Map<String, dynamic> json) =>
      _$TariffComponentFromJson(json);
}

/// Restrictions that may limit when a [TariffElement] applies.
///
/// All fields are optional. An element with no restrictions always applies.
/// Time fields use 24h `HH:mm` local time; weekday is 1 (Mon) - 7 (Sun).
@freezed
abstract class TariffRestriction with _$TariffRestriction {
  const factory TariffRestriction({
    String? startTime,
    String? endTime,
    @Default(<int>[]) List<int> daysOfWeek,
    double? minKwh,
    double? maxKwh,
  }) = _TariffRestriction;

  factory TariffRestriction.fromJson(Map<String, dynamic> json) =>
      _$TariffRestrictionFromJson(json);
}

/// A tariff element bundles [TariffComponent]s that share the same
/// [TariffRestriction]. A [ChargingTariff] may contain multiple elements
/// so that time-of-day pricing can switch between them.
@freezed
abstract class TariffElement with _$TariffElement {
  const factory TariffElement({
    @Default(<TariffComponent>[])
    @TariffComponentListConverter()
    List<TariffComponent> priceComponents,
    @TariffRestrictionNullableConverter()
    TariffRestriction? restrictions,
  }) = _TariffElement;

  factory TariffElement.fromJson(Map<String, dynamic> json) =>
      _$TariffElementFromJson(json);
}

/// OCPI charging tariff.
///
/// A tariff groups one or more [TariffElement]s that together describe how
/// a charging session is priced. The calculator in
/// `EvPriceCalculator` picks the right element based on
/// [TariffRestriction]s and sums the resulting component costs.
@freezed
abstract class ChargingTariff with _$ChargingTariff {
  const ChargingTariff._();

  const factory ChargingTariff({
    required String id,
    @Default('EUR') String currency,
    @TariffTypeJsonConverter() @Default(TariffType.regular) TariffType type,
    @Default(<TariffElement>[])
    @TariffElementListConverter()
    List<TariffElement> elements,
    DateTime? validFrom,
    DateTime? validTo,
  }) = _ChargingTariff;

  factory ChargingTariff.fromJson(Map<String, dynamic> json) =>
      _$ChargingTariffFromJson(json);

  /// Headline price used for map marker display: the first energy component
  /// we find, regardless of restrictions. Returns `null` if the tariff has
  /// no energy component (e.g. free or time-only).
  double? get headlinePricePerKwh {
    for (final element in elements) {
      for (final component in element.priceComponents) {
        if (component.type == PriceComponentType.energy) {
          return component.price;
        }
      }
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// JSON converters
// ---------------------------------------------------------------------------

/// Serializes [PriceComponentType] as its string key.
class PriceComponentTypeJsonConverter
    implements JsonConverter<PriceComponentType, String> {
  const PriceComponentTypeJsonConverter();

  @override
  PriceComponentType fromJson(String json) => PriceComponentType.fromKey(json);

  @override
  String toJson(PriceComponentType object) => object.key;
}

/// Serializes [TariffType] as its string key.
class TariffTypeJsonConverter implements JsonConverter<TariffType, String> {
  const TariffTypeJsonConverter();

  @override
  TariffType fromJson(String json) => TariffType.fromKey(json);

  @override
  String toJson(TariffType object) => object.key;
}

/// Serializes a list of [TariffComponent] as plain JSON maps so that the
/// parent freezed class does not embed the object instances directly.
class TariffComponentListConverter
    implements JsonConverter<List<TariffComponent>, List<dynamic>> {
  const TariffComponentListConverter();

  @override
  List<TariffComponent> fromJson(List<dynamic> json) => json
      .whereType<Map<dynamic, dynamic>>()
      .map((e) => TariffComponent.fromJson(Map<String, dynamic>.from(e)))
      .toList();

  @override
  List<Map<String, dynamic>> toJson(List<TariffComponent> object) =>
      object.map((c) => c.toJson()).toList();
}

/// Serializes a list of [TariffElement] as plain JSON maps.
class TariffElementListConverter
    implements JsonConverter<List<TariffElement>, List<dynamic>> {
  const TariffElementListConverter();

  @override
  List<TariffElement> fromJson(List<dynamic> json) => json
      .whereType<Map<dynamic, dynamic>>()
      .map((e) => TariffElement.fromJson(Map<String, dynamic>.from(e)))
      .toList();

  @override
  List<Map<String, dynamic>> toJson(List<TariffElement> object) =>
      object.map((c) => c.toJson()).toList();
}

/// Serializes a nullable [TariffRestriction] as a plain JSON map.
class TariffRestrictionNullableConverter
    implements JsonConverter<TariffRestriction?, Map<String, dynamic>?> {
  const TariffRestrictionNullableConverter();

  @override
  TariffRestriction? fromJson(Map<String, dynamic>? json) =>
      json == null ? null : TariffRestriction.fromJson(json);

  @override
  Map<String, dynamic>? toJson(TariffRestriction? object) => object?.toJson();
}
