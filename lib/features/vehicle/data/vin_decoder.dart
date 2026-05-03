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

  /// When false, [decode] never hits the vPIC network endpoint and
  /// always returns a [VinDataSource.wmiOffline] result with whatever
  /// the offline WMI table + position-10 year decoder can produce
  /// (#1399). The default is `true` to preserve the pre-#1399 contract
  /// (existing call sites that have already shown the user the VIN
  /// dialog do not need the new GDPR-consent gate).
  ///
  /// New auto-population call sites (the adapter-pair flow) wire this
  /// to the value of `gdprConsentProvider.vinOnlineDecode`. When the
  /// user has not opted in, the flag is `false`, the network call is
  /// skipped, and the offline-only path runs.
  final bool allowOnlineLookup;

  VinDecoder({Dio? dio, this.allowOnlineLookup = true})
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
  ///   - [VinDataSource.wmiOffline] → make + country + (#1399) decoded
  ///     model year from position 10. Engine fields stay null.
  ///   - [VinDataSource.invalid]    → nothing; input failed validation.
  ///
  /// When [allowOnlineLookup] is false (#1399 — user has not consented
  /// to sending the VIN to NHTSA), the vPIC tier is skipped entirely
  /// and the result is always either [VinDataSource.wmiOffline] or
  /// [VinDataSource.invalid].
  ///
  /// Always returns a non-null result (the `?` in the signature is
  /// kept for forward-compatibility should a future caller want to
  /// signal "decoder disabled").
  Future<VinData?> decode(String vin) async {
    final cleaned = _cleanVin(vin);
    if (cleaned == null) {
      return VinData(vin: vin, source: VinDataSource.invalid);
    }

    if (allowOnlineLookup) {
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
      } on DioException catch (e, st) {
        debugPrint(
            'VinDecoder: vPIC failed (${e.type}): falling back to WMI\n$st');
      } on Object catch (e, st) {
        debugPrint('VinDecoder: unexpected error $e — falling back to WMI\n$st');
      }
    } else {
      debugPrint(
          'VinDecoder: online decode disabled by GDPR consent — '
          'using offline WMI + position-10 year only');
    }

    return _fallbackFromWmi(cleaned);
  }

  /// Decode the model year from position 10 of a 17-character VIN per
  /// ISO 3779 (#1399). Returns null when the position-10 character is
  /// not in the alphabet or when the input is too short.
  ///
  /// Two 30-year cycles share the same characters. The decoder picks
  /// the cycle whose year is within ±1 of the current year — for a
  /// 2026 user, "L" decodes to 2020 (current cycle) rather than 1990
  /// (prior cycle). Edge cases at the boundary fall back to the latest
  /// cycle.
  static int? decodeModelYearFromPosition10(
    String vin, {
    DateTime? now,
  }) {
    if (vin.length < 10) return null;
    final ch = vin[9].toUpperCase();
    final cycleYear = _vinYearCycle[ch];
    if (cycleYear == null) return null;
    // The character maps to two candidate years — `cycleYear` and
    // `cycleYear + 30`. Pick whichever is closer to "now without
    // skewing into the future" — anything within 2 years ahead of
    // `now` is plausible (model-year 2027 cars sell in late 2026).
    final currentYear = (now ?? DateTime.now()).year;
    final older = cycleYear;
    final newer = cycleYear + 30;
    if (newer <= currentYear + 1) return newer;
    if (older <= currentYear + 1) return older;
    // Both candidates are in the future — fall back to the older one.
    return older;
  }

  /// ISO 3779 model-year code table. Each character maps to the
  /// earliest year in its 30-year cycle. The decoder picks the most
  /// recent year that's within +1 of "now".
  static const Map<String, int> _vinYearCycle = {
    'A': 1980, 'B': 1981, 'C': 1982, 'D': 1983, 'E': 1984,
    'F': 1985, 'G': 1986, 'H': 1987, 'J': 1988, 'K': 1989,
    'L': 1990, 'M': 1991, 'N': 1992, 'P': 1993, 'R': 1994,
    'S': 1995, 'T': 1996, 'V': 1997, 'W': 1998, 'X': 1999,
    'Y': 2000, '1': 2001, '2': 2002, '3': 2003, '4': 2004,
    '5': 2005, '6': 2006, '7': 2007, '8': 2008, '9': 2009,
  };

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

  /// WMI-only decode. Returns a [VinData] with make + country + (when
  /// position 10 is a recognised year code) model year. Returns an
  /// otherwise-empty [VinData] with [VinDataSource.wmiOffline] when
  /// the WMI prefix is unknown so the caller still knows the decoder
  /// ran (and didn't just fail validation).
  static VinData _fallbackFromWmi(String vin) {
    final entry = wmi.lookup(vin);
    final year = decodeModelYearFromPosition10(vin);
    if (entry == null) {
      return VinData(
        vin: vin,
        modelYear: year,
        source: VinDataSource.wmiOffline,
      );
    }
    return VinData(
      vin: vin,
      make: entry.brand,
      country: entry.country,
      modelYear: year,
      source: VinDataSource.wmiOffline,
    );
  }
}
