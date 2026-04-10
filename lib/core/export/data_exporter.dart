import 'dart:convert';

import '../data/storage_repository.dart';

/// Categories of user data that can be exported individually.
///
/// Each category maps to a CSV table with a stable column layout.
/// The JSON export always contains all categories.
enum ExportCategory {
  favorites,
  priceHistory,
  alerts,
  fillUps,
  ratings,
  ignoredStations,
  profiles,
  itineraries,
}

/// Service that exports user data (GDPR data portability) to JSON and CSV.
///
/// The exporter is a pure function of a [StorageRepository] snapshot — it
/// performs no I/O and contains no tracking metadata. API keys are never
/// included in the output.
///
/// JSON output is a single document containing all categories. CSV output
/// is per-category because CSV has no native support for heterogeneous
/// tables. Callers can use [exportAllAsCsv] to get a map of
/// `{categoryName: csvString}` for batch export.
class DataExporter {
  final StorageRepository _storage;
  final String _appVersion;
  final DateTime Function() _now;

  DataExporter(
    this._storage, {
    String appVersion = '4.3.0',
    DateTime Function()? now,
  })  : _appVersion = appVersion,
        _now = now ?? DateTime.now;

  // --------------------------------------------------------------------------
  // JSON
  // --------------------------------------------------------------------------

  /// Returns all user data as a pretty-printed JSON document.
  ///
  /// Excludes API keys (security) and cache entries (ephemeral).
  String exportToJson() {
    final data = <String, dynamic>{
      'exportedAt': _now().toUtc().toIso8601String(),
      'appVersion': _appVersion,
      'favorites': _storage.getFavoriteIds(),
      'favoriteStationData': _storage.getAllFavoriteStationData(),
      'ignoredStations': _storage.getIgnoredIds(),
      'ratings': _storage.getRatings(),
      'profiles': _storage.getAllProfiles(),
      'alerts': _storage.getAlerts(),
      'fillUps': _readFillUps(),
      'itineraries': _storage.getItineraries(),
      'priceHistory': _readPriceHistory(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  // --------------------------------------------------------------------------
  // CSV
  // --------------------------------------------------------------------------

  /// Returns a single CSV string for a given category.
  ///
  /// All CSVs use RFC 4180 escaping: fields containing commas, quotes, CR,
  /// or LF are wrapped in double quotes and embedded quotes are doubled.
  String exportToCsv(ExportCategory category) {
    switch (category) {
      case ExportCategory.favorites:
        return _favoritesCsv();
      case ExportCategory.priceHistory:
        return _priceHistoryCsv();
      case ExportCategory.alerts:
        return _alertsCsv();
      case ExportCategory.fillUps:
        return _fillUpsCsv();
      case ExportCategory.ratings:
        return _ratingsCsv();
      case ExportCategory.ignoredStations:
        return _ignoredCsv();
      case ExportCategory.profiles:
        return _profilesCsv();
      case ExportCategory.itineraries:
        return _itinerariesCsv();
    }
  }

  /// Returns a map of `{categoryName: csvString}` for every category.
  Map<String, String> exportAllAsCsv() {
    return {
      for (final c in ExportCategory.values) c.name: exportToCsv(c),
    };
  }

  // --------------------------------------------------------------------------
  // Category encoders
  // --------------------------------------------------------------------------

  String _favoritesCsv() {
    final ids = _storage.getFavoriteIds();
    final data = _storage.getAllFavoriteStationData();
    const header = ['station_id', 'name', 'brand', 'street', 'place', 'postcode', 'lat', 'lng'];
    final rows = <List<Object?>>[header];
    for (final id in ids) {
      final d = data[id];
      final m = d is Map ? d.cast<String, dynamic>() : const <String, dynamic>{};
      rows.add([
        id,
        m['name'],
        m['brand'],
        m['street'],
        m['place'],
        m['postCode'] ?? m['postcode'],
        m['lat'],
        m['lng'] ?? m['lon'],
      ]);
    }
    return _encodeCsv(rows);
  }

  String _priceHistoryCsv() {
    const header = ['station_id', 'timestamp', 'fuel_type', 'price'];
    final rows = <List<Object?>>[header];
    for (final key in _storage.getPriceHistoryKeys()) {
      for (final record in _storage.getPriceRecords(key)) {
        final ts = record['timestamp'] ?? record['recordedAt'];
        final fuel = record['fuelType'] ?? record['fuel'];
        final price = record['price'];
        if (fuel is Map) {
          for (final entry in fuel.entries) {
            rows.add([key, ts, entry.key, entry.value]);
          }
        } else if (price is Map) {
          for (final entry in price.entries) {
            rows.add([key, ts, entry.key, entry.value]);
          }
        } else {
          rows.add([key, ts, fuel, price]);
        }
      }
    }
    return _encodeCsv(rows);
  }

  String _alertsCsv() {
    const header = [
      'id',
      'station_id',
      'fuel_type',
      'threshold_price',
      'direction',
      'enabled',
      'created_at',
    ];
    final rows = <List<Object?>>[header];
    for (final a in _storage.getAlerts()) {
      rows.add([
        a['id'],
        a['stationId'] ?? a['station_id'],
        a['fuelType'] ?? a['fuel_type'],
        a['thresholdPrice'] ?? a['threshold'] ?? a['price'],
        a['direction'],
        a['enabled'],
        a['createdAt'] ?? a['created_at'],
      ]);
    }
    return _encodeCsv(rows);
  }

  String _fillUpsCsv() {
    const header = [
      'id',
      'station_id',
      'station_name',
      'timestamp',
      'fuel_type',
      'liters',
      'price_per_liter',
      'total_cost',
      'odometer_km',
      'notes',
    ];
    final rows = <List<Object?>>[header];
    for (final f in _readFillUps()) {
      rows.add([
        f['id'],
        f['stationId'] ?? f['station_id'],
        f['stationName'] ?? f['station_name'],
        f['timestamp'] ?? f['date'],
        f['fuelType'] ?? f['fuel_type'],
        f['liters'] ?? f['volume'],
        f['pricePerLiter'] ?? f['price_per_liter'] ?? f['price'],
        f['totalCost'] ?? f['total'] ?? f['total_cost'],
        f['odometer'] ?? f['odometer_km'],
        f['notes'],
      ]);
    }
    return _encodeCsv(rows);
  }

  String _ratingsCsv() {
    const header = ['station_id', 'rating'];
    final rows = <List<Object?>>[header];
    _storage.getRatings().forEach((k, v) => rows.add([k, v]));
    return _encodeCsv(rows);
  }

  String _ignoredCsv() {
    const header = ['station_id'];
    final rows = <List<Object?>>[header];
    for (final id in _storage.getIgnoredIds()) {
      rows.add([id]);
    }
    return _encodeCsv(rows);
  }

  String _profilesCsv() {
    const header = ['id', 'name', 'fuel_type', 'radius_km', 'sort_by'];
    final rows = <List<Object?>>[header];
    for (final p in _storage.getAllProfiles()) {
      rows.add([
        p['id'],
        p['name'],
        p['fuelType'] ?? p['fuel_type'],
        p['radius'] ?? p['radiusKm'] ?? p['radius_km'],
        p['sortBy'] ?? p['sort_by'],
      ]);
    }
    return _encodeCsv(rows);
  }

  String _itinerariesCsv() {
    const header = ['id', 'name', 'origin', 'destination', 'created_at'];
    final rows = <List<Object?>>[header];
    for (final it in _storage.getItineraries()) {
      rows.add([
        it['id'],
        it['name'],
        it['origin'],
        it['destination'],
        it['createdAt'] ?? it['created_at'],
      ]);
    }
    return _encodeCsv(rows);
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  /// Reads fill-ups from the settings box if present. Fill-ups are not yet
  /// a first-class storage category (#148) — this reader tolerates either an
  /// eventual dedicated interface or the current settings-based storage.
  List<Map<String, dynamic>> _readFillUps() {
    final raw = _storage.getSetting('fillUps');
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList(growable: false);
    }
    return const [];
  }

  Map<String, List<Map<String, dynamic>>> _readPriceHistory() {
    final result = <String, List<Map<String, dynamic>>>{};
    for (final key in _storage.getPriceHistoryKeys()) {
      result[key] = _storage.getPriceRecords(key);
    }
    return result;
  }

  /// RFC 4180 CSV encoder — no dependency on the `csv` package.
  ///
  /// - Uses `,` separator and `\r\n` line ending (Excel-friendly).
  /// - Wraps fields in `"` when they contain `,`, `"`, `\r`, or `\n`.
  /// - Doubles embedded `"` characters inside quoted fields.
  /// - `null` renders as an empty cell.
  String _encodeCsv(List<List<Object?>> rows) {
    final buf = StringBuffer();
    for (final row in rows) {
      for (var i = 0; i < row.length; i++) {
        if (i > 0) buf.write(',');
        buf.write(_encodeCell(row[i]));
      }
      buf.write('\r\n');
    }
    return buf.toString();
  }

  String _encodeCell(Object? value) {
    if (value == null) return '';
    final s = value.toString();
    final needsQuoting = s.contains(',') ||
        s.contains('"') ||
        s.contains('\n') ||
        s.contains('\r');
    if (!needsQuoting) return s;
    return '"${s.replaceAll('"', '""')}"';
  }
}
