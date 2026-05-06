/// One observation in the price-prediction feature space.
///
/// **This is the input contract for the future TFLite phase-2 model
/// (#1117).** Phase 2 will load training data as `List<FeatureVector>`,
/// run gradient-boost training offline, and ship a `.tflite` artifact
/// that consumes the dictionary returned by [toFeatureMap]. **Do not
/// rename, retype, or remove existing field keys without bumping
/// [schemaVersion]** — every change forces a model retrain.
///
/// Phase 1 (this file) only enriches the on-device heuristic predictor
/// — it builds vectors but never feeds them to a model.
///
/// ## Fields
///
/// - [hourOfDay] — `0..23`
/// - [dayOfWeek] — `1..7` (1 = Monday, 7 = Sunday — matches
///   [DateTime.weekday])
/// - [brand] — canonical brand from [Station.brand], or `null` when
///   the station is unknown
/// - [countryCode] — ISO-3166 alpha-2 (e.g. `'DE'`, `'FR'`), or `null`
///   when unresolvable
/// - [isHoliday] — public-holiday flag from [PublicHolidayCalendar]
/// - [priceEur] — observed price per unit (EUR/L for liquid fuels,
///   EUR/kg for CNG/H2, EUR/kWh for electric); this is the **label**
///   for supervised training in phase 2
/// - [observedAt] — UTC timestamp of the observation, kept for
///   ordering, debugging, and time-window splits during training
class FeatureVector {
  /// Schema version of the feature dictionary returned by
  /// [toFeatureMap]. Bump this whenever a key is added, renamed, or
  /// retyped — the phase-2 model file embeds this number to guard
  /// against silent skew.
  static const int schemaVersion = 1;

  final int hourOfDay;
  final int dayOfWeek;
  final String? brand;
  final String? countryCode;
  final bool isHoliday;
  final double priceEur;
  final DateTime observedAt;

  const FeatureVector({
    required this.hourOfDay,
    required this.dayOfWeek,
    required this.brand,
    required this.countryCode,
    required this.isHoliday,
    required this.priceEur,
    required this.observedAt,
  });

  /// Stable map representation passed to the phase-2 TFLite model.
  ///
  /// Keys are ordered alphabetically for deterministic JSON output.
  /// Phase 2 must read each key by name (not position).
  Map<String, dynamic> toFeatureMap() => <String, dynamic>{
        'brand': brand,
        'country_code': countryCode,
        'day_of_week': dayOfWeek,
        'hour_of_day': hourOfDay,
        'is_holiday': isHoliday,
        'observed_at': observedAt.toUtc().toIso8601String(),
        'price_eur': priceEur,
      };

  /// JSON encoding used for on-device training-set persistence and
  /// upload. Mirrors [toFeatureMap] but is keyed for round-trip with
  /// [FeatureVector.fromJson].
  Map<String, dynamic> toJson() => toFeatureMap();

  /// Reconstructs a [FeatureVector] from a [toJson] / [toFeatureMap]
  /// dictionary. Throws [FormatException] when a required key is
  /// missing or the wrong type.
  factory FeatureVector.fromJson(Map<String, dynamic> json) {
    return FeatureVector(
      hourOfDay: _requireInt(json, 'hour_of_day'),
      dayOfWeek: _requireInt(json, 'day_of_week'),
      brand: json['brand'] as String?,
      countryCode: json['country_code'] as String?,
      isHoliday: _requireBool(json, 'is_holiday'),
      priceEur: _requireDouble(json, 'price_eur'),
      observedAt: _requireDateTime(json, 'observed_at'),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeatureVector &&
        other.hourOfDay == hourOfDay &&
        other.dayOfWeek == dayOfWeek &&
        other.brand == brand &&
        other.countryCode == countryCode &&
        other.isHoliday == isHoliday &&
        other.priceEur == priceEur &&
        other.observedAt == observedAt;
  }

  @override
  int get hashCode => Object.hash(
        hourOfDay,
        dayOfWeek,
        brand,
        countryCode,
        isHoliday,
        priceEur,
        observedAt,
      );

  @override
  String toString() {
    return 'FeatureVector(hourOfDay: $hourOfDay, dayOfWeek: $dayOfWeek, '
        'brand: $brand, countryCode: $countryCode, isHoliday: $isHoliday, '
        'priceEur: $priceEur, observedAt: $observedAt)';
  }
}

int _requireInt(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is int) return v;
  throw FormatException('FeatureVector.fromJson: missing or non-int "$key"');
}

bool _requireBool(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is bool) return v;
  throw FormatException('FeatureVector.fromJson: missing or non-bool "$key"');
}

double _requireDouble(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is num) return v.toDouble();
  throw FormatException('FeatureVector.fromJson: missing or non-num "$key"');
}

DateTime _requireDateTime(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is String) return DateTime.parse(v);
  throw FormatException(
      'FeatureVector.fromJson: missing or non-ISO-8601-string "$key"');
}
