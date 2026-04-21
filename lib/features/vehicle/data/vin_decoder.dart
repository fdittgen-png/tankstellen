import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/dio_factory.dart';

/// Decoded fields pulled from a VIN. All nullable because decoding has
/// three tiers and each tier produces a different subset:
///
///   - **NHTSA vPIC**: every field — make, model, year, displacement,
///     cylinders, fuel type.
///   - **Offline WMI fallback**: make (and sometimes country) only —
///     the first three VIN characters don't encode engine data.
///   - **Invalid / unreadable VIN**: nothing — all fields null.
class VinDecodeResult {
  final String? make;
  final String? model;
  final int? modelYear;
  final double? displacementLitres;
  final int? cylinders;
  final String? fuelType;
  final String? country;

  /// Which tier produced this result. Useful for telemetry and for
  /// the onboarding UI to decide whether to ask the user to confirm
  /// the fields or fill the missing ones manually.
  final VinDecodeSource source;

  const VinDecodeResult({
    this.make,
    this.model,
    this.modelYear,
    this.displacementLitres,
    this.cylinders,
    this.fuelType,
    this.country,
    required this.source,
  });

  /// `true` when we have enough to auto-fill the core vehicle profile
  /// (make + model + displacement are all set).
  bool get isComplete =>
      make != null && model != null && displacementLitres != null;
}

enum VinDecodeSource {
  /// Full vPIC response (network path, every field resolved).
  nhtsa,

  /// Only the first 3 VIN characters (WMI lookup) — offline path when
  /// the network call failed. Make + country, nothing else.
  wmiFallback,

  /// VIN didn't validate or no decoder tier produced data.
  invalid,
}

/// Decodes Vehicle Identification Numbers into structured data.
///
/// Primary path: NHTSA vPIC public API (`vpic.nhtsa.dot.gov`).
/// Covers every WMI globally because the database is keyed on the
/// standard VIN structure (SAE J272 / ISO 3779). Free, no auth.
///
/// Fallback path: a curated table of the first-3-character WMI
/// prefixes for the ~30 brands most likely to show up in the
/// European / North-American market. Make-only, no engine data, but
/// enough for the onboarding UI to at least say "Your car is a
/// Peugeot" and prompt for the rest.
///
/// Invalid-VIN path: empty result with [VinDecodeSource.invalid]. The
/// onboarding UI falls through to fully-manual vehicle entry.
class VinDecoder {
  final Dio _dio;

  VinDecoder({Dio? dio})
      : _dio = dio ??
            DioFactory.create(
              baseUrl: 'https://vpic.nhtsa.dot.gov',
              // vPIC has no published rate limit; play nice anyway.
              rateLimit: const Duration(milliseconds: 500),
            );

  /// Decode [vin]. Never throws — fall-through paths always yield a
  /// [VinDecodeResult]. Callers inspect [VinDecodeResult.source] to
  /// know how much trust to place in the returned fields.
  Future<VinDecodeResult> decode(String vin) async {
    final cleaned = _cleanVin(vin);
    if (cleaned == null) {
      return const VinDecodeResult(source: VinDecodeSource.invalid);
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/vehicles/decodevin/$cleaned',
        queryParameters: const {'format': 'json'},
      );
      final data = response.data;
      if (data == null) return _fallbackFromWmi(cleaned);
      final parsed = _parseVpic(data);
      if (parsed != null) return parsed;
    } on DioException catch (e) {
      debugPrint('VinDecoder: vPIC failed (${e.type}): falling back to WMI');
    } on Object catch (e) {
      debugPrint('VinDecoder: unexpected error $e — falling back to WMI');
    }

    return _fallbackFromWmi(cleaned);
  }

  /// Validate the VIN — must be exactly 17 characters of the SAE VIN
  /// alphabet (A–Z + 0–9, minus I, O, Q which VINs never contain).
  /// Case-insensitive; upper-cases the result so callers don't need
  /// to normalise separately. Returns null on invalid input.
  static String? _cleanVin(String vin) {
    final upper = vin.trim().toUpperCase();
    if (upper.length != 17) return null;
    final pattern = RegExp(r'^[A-HJ-NPR-Z0-9]{17}$');
    if (!pattern.hasMatch(upper)) return null;
    return upper;
  }

  /// Parse a vPIC response body. vPIC returns `{Results: [{Variable, Value}, ...]}`
  /// — flatten into a map, extract the fields we care about.
  static VinDecodeResult? _parseVpic(Map<String, dynamic> body) {
    final results = body['Results'];
    if (results is! List || results.isEmpty) return null;
    final flat = <String, String>{};
    for (final entry in results) {
      if (entry is Map && entry['Variable'] is String) {
        final value = entry['Value'];
        if (value is String && value.isNotEmpty && value != 'Not Applicable') {
          flat[entry['Variable'] as String] = value;
        }
      }
    }
    if (flat.isEmpty) return null;

    final make = flat['Make'];
    final model = flat['Model'];
    final yearRaw = flat['Model Year'];
    final displacementRaw = flat['Displacement (L)'];
    final cylindersRaw = flat['Engine Number of Cylinders'];
    final fuel = flat['Fuel Type - Primary'];

    // vPIC returns nothing for a completely unrecognised VIN — treat as a
    // decode failure and let the WMI fallback try.
    if (make == null && model == null) return null;

    return VinDecodeResult(
      make: make,
      model: model,
      modelYear: yearRaw != null ? int.tryParse(yearRaw) : null,
      displacementLitres:
          displacementRaw != null ? double.tryParse(displacementRaw) : null,
      cylinders: cylindersRaw != null ? int.tryParse(cylindersRaw) : null,
      fuelType: fuel,
      source: VinDecodeSource.nhtsa,
    );
  }

  /// WMI (first-3) fallback table. Covers the ~30 prefixes most
  /// likely to appear in the European + North American market. This
  /// is deliberately a subset of the full IMPORT-level WMI database
  /// (which has thousands of entries for every assembly plant): the
  /// onboarding UI only needs the make to show "Your car is a X —
  /// please confirm the rest", which cuts down to the prefix
  /// patterns that cover > 95% of users.
  ///
  /// Entries cover the first 3 characters (WMI). Where a brand uses
  /// multiple assembly-plant prefixes that share the first 3 chars,
  /// we list just the common ones.
  static final Map<String, _WmiBrand> _wmiTable = {
    // PSA group (Peugeot/Citroën/DS/Opel-Vauxhall post-2017)
    'VF3': const _WmiBrand('Peugeot', 'FR'),
    'VF7': const _WmiBrand('Citroën', 'FR'),
    'VR3': const _WmiBrand('Peugeot', 'FR'),
    'VR1': const _WmiBrand('Citroën', 'FR'),
    'W0L': const _WmiBrand('Opel', 'DE'),
    'W0V': const _WmiBrand('Opel', 'DE'),
    // Renault / Dacia
    'VF1': const _WmiBrand('Renault', 'FR'),
    'VF6': const _WmiBrand('Renault', 'FR'),
    'VF8': const _WmiBrand('Dacia', 'RO'),
    'UU1': const _WmiBrand('Dacia', 'RO'),
    // VW Group
    'WVW': const _WmiBrand('Volkswagen', 'DE'),
    'WV1': const _WmiBrand('Volkswagen', 'DE'),
    'WV2': const _WmiBrand('Volkswagen', 'DE'),
    'WAU': const _WmiBrand('Audi', 'DE'),
    'TMB': const _WmiBrand('Škoda', 'CZ'),
    'VSS': const _WmiBrand('SEAT', 'ES'),
    // BMW / Mini
    'WBA': const _WmiBrand('BMW', 'DE'),
    'WBS': const _WmiBrand('BMW M', 'DE'),
    'WMW': const _WmiBrand('MINI', 'DE'),
    // Mercedes-Benz
    'WDB': const _WmiBrand('Mercedes-Benz', 'DE'),
    'WDD': const _WmiBrand('Mercedes-Benz', 'DE'),
    'W1K': const _WmiBrand('Mercedes-Benz', 'DE'),
    // Ford
    'WF0': const _WmiBrand('Ford', 'DE'),
    '1FA': const _WmiBrand('Ford', 'US'),
    '1FM': const _WmiBrand('Ford', 'US'),
    '1FT': const _WmiBrand('Ford', 'US'),
    // Toyota (also Peugeot 107 / Aygo / C1 when built in Kolín plant → TMB VINs)
    'JTD': const _WmiBrand('Toyota', 'JP'),
    'JTE': const _WmiBrand('Toyota', 'JP'),
    'JTN': const _WmiBrand('Toyota', 'JP'),
    'VNK': const _WmiBrand('Toyota', 'FR'),
    // Fiat / Alfa / Jeep
    'ZFA': const _WmiBrand('Fiat', 'IT'),
    'ZAR': const _WmiBrand('Alfa Romeo', 'IT'),
    '1J4': const _WmiBrand('Jeep', 'US'),
    // Honda
    'JHM': const _WmiBrand('Honda', 'JP'),
    // Hyundai / Kia
    'KMH': const _WmiBrand('Hyundai', 'KR'),
    'KNA': const _WmiBrand('Kia', 'KR'),
    'KNB': const _WmiBrand('Kia', 'KR'),
    // Tesla
    '5YJ': const _WmiBrand('Tesla', 'US'),
    '7SA': const _WmiBrand('Tesla', 'US'),
    'XP7': const _WmiBrand('Tesla', 'DE'),
  };

  /// WMI-only decode. Returns an [VinDecodeResult] with just make +
  /// country when the prefix is known; otherwise returns an
  /// [VinDecodeSource.invalid] result so the caller falls through to
  /// manual entry.
  static VinDecodeResult _fallbackFromWmi(String vin) {
    final wmi = vin.substring(0, 3);
    final brand = _wmiTable[wmi];
    if (brand == null) {
      return const VinDecodeResult(source: VinDecodeSource.invalid);
    }
    return VinDecodeResult(
      make: brand.make,
      country: brand.country,
      source: VinDecodeSource.wmiFallback,
    );
  }
}

class _WmiBrand {
  final String make;
  final String country;
  const _WmiBrand(this.make, this.country);
}
