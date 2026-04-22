import 'package:freezed_annotation/freezed_annotation.dart';

part 'vin_data.freezed.dart';
part 'vin_data.g.dart';

/// Which tier of the VIN decoder produced the [VinData].
///
/// - [vpic] — full NHTSA vPIC response. Every field that vPIC returned
///   is populated; the rest are null.
/// - [wmiOffline] — offline WMI fallback. Make (and country) only, no
///   engine fields. Happens when the device is offline or vPIC is
///   unreachable.
/// - [invalid] — the input wasn't a valid VIN (length != 17, contained
///   I/O/Q, or failed the cleaner). No fields are populated.
enum VinDataSource {
  vpic,
  wmiOffline,
  invalid,
}

/// Structured data pulled from a VIN by [VinDecoder].
///
/// Every field is nullable — the three tiers of decoding
/// ([VinDataSource]) each produce a different subset:
///
///   - [VinDataSource.vpic]    → the full field set (make, model, year,
///     displacement, cylinders, fuel, horsepower, GVWR).
///   - [VinDataSource.wmiOffline] → make + country only. Offline
///     fallback from the first 3 VIN characters.
///   - [VinDataSource.invalid] → nothing. Input didn't validate.
///
/// `source` is required so callers can decide how much to trust the
/// returned fields without running `== null` on every one of them.
@freezed
abstract class VinData with _$VinData {
  const VinData._();

  const factory VinData({
    required String vin,
    String? make,
    String? model,
    int? modelYear,
    double? displacementL,
    int? cylinderCount,
    String? fuelTypePrimary,
    int? engineHp,
    int? gvwrLbs,
    // ISO country or human-readable country name from the WMI offline
    // table. Only populated on the wmiOffline path — vPIC doesn't
    // expose a country field directly in the decoded variables we
    // parse.
    String? country,
    @Default(VinDataSource.invalid)
    @VinDataSourceJsonConverter()
    VinDataSource source,
  }) = _VinData;

  factory VinData.fromJson(Map<String, dynamic> json) =>
      _$VinDataFromJson(json);

  /// True when we have enough to auto-fill the core vehicle profile
  /// (make + model + displacement are all set). The onboarding UI can
  /// skip the "please confirm" prompt in this case.
  bool get isComplete =>
      make != null && model != null && displacementL != null;
}

/// Serializes [VinDataSource] as its string name so the field round-
/// trips cleanly through JSON/Hive storage.
class VinDataSourceJsonConverter
    implements JsonConverter<VinDataSource, String> {
  const VinDataSourceJsonConverter();

  @override
  VinDataSource fromJson(String json) {
    for (final v in VinDataSource.values) {
      if (v.name == json) return v;
    }
    return VinDataSource.invalid;
  }

  @override
  String toJson(VinDataSource object) => object.name;
}
