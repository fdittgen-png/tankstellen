import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/dio_factory.dart';
import '../domain/entities/vin_data.dart';
import 'wmi_table.dart' as wmi;

/// Decodes Vehicle Identification Numbers into structured [VinData].
///
/// ## Tiers
///
/// Primary: **NHTSA vPIC** (`vpic.nhtsa.dot.gov`). Public, free, no
/// auth. Covers every WMI globally because the database is keyed on
/// the standard VIN structure (SAE J272 / ISO 3779). Returns make,
/// model, year, displacement, cylinders, fuel type, horsepower, GVWR.
///
/// Fallback: **offline WMI table** ([wmi.wmiTable]). Maps the first 3
/// VIN characters to `(country, brand)` for the ~50 globally-common
/// manufacturers. Make + country only — no engine data. Used when
/// the device is offline or vPIC is unreachable.
///
/// Invalid input: returns a [VinData] with [VinDataSource.invalid] and
/// every field null. The onboarding UI falls through to fully-manual
/// vehicle entry.
///
/// [decode] never throws — every path yields a [VinData] that callers
/// inspect via [VinData.source] to decide how much to trust the
/// returned fields.
class VinDecoder {
  final Dio _dio;

  VinDecoder({Dio? dio})
      : _dio = dio ??
            DioFactory.create(
              baseUrl: 'https://vpic.nhtsa.dot.gov',
              // vPIC has no published rate limit; play nice anyway.
              rateLimit: const Duration(milliseconds: 500),
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
            );

  /// Decode [vin]. Never throws.
  ///
  /// The returned [VinData.source] tells callers which tier produced
  /// the data:
  ///
  ///   - [VinDataSource.vpic]       → full network response.
  ///   - [VinDataSource.wmiOffline] → make + country only (offline).
  ///   - [VinDataSource.invalid]    → nothing; input failed validation.
  ///
  /// Always returns a non-null result (the `?` in the signature is
  /// kept for forward-compatibility should a future caller want to
  /// signal "decoder disabled").
  Future<VinData?> decode(String vin) async {
    final cleaned = _cleanVin(vin);
    if (cleaned == null) {
      return VinData(vin: vin, source: VinDataSource.invalid);
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/vehicles/decodevin/$cleaned',
        queryParameters: const {'format': 'json'},
      );
      final data = response.data;
      if (data != null) {
        final parsed = _parseVpic(cleaned, data);
        if (parsed != null) return parsed;
      }
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

  /// Parse a vPIC response body. vPIC returns
  /// `{Results: [{Variable, Value}, ...]}` — flatten into a map and
  /// extract the fields we care about. Returns null on an empty or
  /// unrecognised response so the caller falls through to the WMI
  /// fallback.
  static VinData? _parseVpic(String vin, Map<String, dynamic> body) {
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
    final hpRaw = flat['Engine Brake (hp) From'] ?? flat['Engine HP'];
    final gvwrRaw = flat['Gross Vehicle Weight Rating From'] ?? flat['GVWR'];

    // vPIC returns nothing useful for a completely unrecognised VIN —
    // treat as a decode failure and let the WMI fallback try.
    if (make == null && model == null) return null;

    return VinData(
      vin: vin,
      make: make,
      model: model,
      modelYear: yearRaw != null ? int.tryParse(yearRaw) : null,
      displacementL:
          displacementRaw != null ? double.tryParse(displacementRaw) : null,
      cylinderCount: cylindersRaw != null ? int.tryParse(cylindersRaw) : null,
      fuelTypePrimary: fuel,
      engineHp: hpRaw != null ? int.tryParse(hpRaw) : null,
      gvwrLbs: gvwrRaw != null ? _parseGvwrLbs(gvwrRaw) : null,
      source: VinDataSource.vpic,
    );
  }

  /// vPIC's GVWR field is usually a bucket label like "Class 1A: 3,000
  /// lb or less (1,360 kg or less)". Try a plain int first (some vPIC
  /// responses use a bare number) and otherwise pull the first integer
  /// out of the bucket string.
  static int? _parseGvwrLbs(String raw) {
    final direct = int.tryParse(raw);
    if (direct != null) return direct;
    final match = RegExp(r'(\d[\d,]*)').firstMatch(raw);
    if (match == null) return null;
    return int.tryParse(match.group(1)!.replaceAll(',', ''));
  }

  /// WMI-only decode. Returns a [VinData] with make + country when the
  /// prefix is known; otherwise returns an empty [VinData] with
  /// [VinDataSource.wmiOffline] so the caller still knows the decoder
  /// ran (and didn't just fail validation).
  static VinData _fallbackFromWmi(String vin) {
    final entry = wmi.lookup(vin);
    if (entry == null) {
      return VinData(vin: vin, source: VinDataSource.wmiOffline);
    }
    return VinData(
      vin: vin,
      make: entry.brand,
      country: entry.country,
      source: VinDataSource.wmiOffline,
    );
  }
}
