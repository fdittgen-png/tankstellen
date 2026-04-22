import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Per-field regex override for a single receipt layout.
///
/// Each field describes a regex + capture-group index. When a field is
/// populated the corresponding parsed value wins over the brand-layout
/// default (see [ReceiptParser.parse] dispatch). A `null` field on the
/// owning [OverrideSpec] means "fall through to the brand layout".
@immutable
class OverrideFieldSpec {
  /// Regex pattern to evaluate against the OCR text.
  final String pattern;

  /// Capture-group index whose contents become the field value.
  /// Group `0` is the whole match; `1` is the first parenthesised group.
  final int group;

  const OverrideFieldSpec({required this.pattern, required this.group});

  /// Build an [OverrideFieldSpec] from a JSON map. Returns `null` if the
  /// entry is malformed (missing pattern, non-string pattern, bad group,
  /// or invalid regex) — callers log and skip the entry.
  static OverrideFieldSpec? fromJson(Object? raw) {
    if (raw == null) return null;
    if (raw is! Map) return null;
    final pattern = raw['pattern'];
    final group = raw['group'];
    if (pattern is! String || pattern.isEmpty) return null;
    if (group is! int || group < 0) return null;
    // Validate the regex compiles so the parser doesn't throw later.
    try {
      RegExp(pattern);
    } on FormatException catch (e) {
      debugPrint(
        'ReceiptOverrideRegistry: invalid regex "$pattern" skipped: $e',
      );
      return null;
    }
    return OverrideFieldSpec(pattern: pattern, group: group);
  }

  /// Run the regex against [text] and return the captured group as a
  /// trimmed string, or `null` when the match or the group index misses.
  String? extract(String text) {
    final re = RegExp(pattern);
    final match = re.firstMatch(text);
    if (match == null) return null;
    if (group > match.groupCount) return null;
    return match.group(group)?.trim();
  }
}

/// Per-station parser override. Every field is optional — when a field is
/// `null` the parser falls through to the brand layout it would normally
/// use. Fields like [liters], [pricePerLiter], and [totalCost] are
/// decimal; [date] is DD/MM/YYYY-ish text fed through the generic parser's
/// date builder; [stationName] and [fuelType] are captured as strings.
@immutable
class OverrideSpec {
  final OverrideFieldSpec? liters;
  final OverrideFieldSpec? pricePerLiter;
  final OverrideFieldSpec? totalCost;
  final OverrideFieldSpec? stationName;
  final OverrideFieldSpec? fuelType;
  final OverrideFieldSpec? date;

  const OverrideSpec({
    this.liters,
    this.pricePerLiter,
    this.totalCost,
    this.stationName,
    this.fuelType,
    this.date,
  });

  /// `true` when at least one field would override the brand layout.
  bool get isEmpty =>
      liters == null &&
      pricePerLiter == null &&
      totalCost == null &&
      stationName == null &&
      fuelType == null &&
      date == null;

  /// Parse an [OverrideSpec] from a JSON map. Individual malformed fields
  /// are dropped (logged via [OverrideFieldSpec.fromJson]) and the rest
  /// of the spec survives — a single bad regex shouldn't hide the whole
  /// override for a station.
  static OverrideSpec? fromJson(Object? raw) {
    if (raw == null) return null;
    if (raw is! Map) return null;
    return OverrideSpec(
      liters: OverrideFieldSpec.fromJson(raw['liters']),
      pricePerLiter: OverrideFieldSpec.fromJson(raw['pricePerLiter']),
      totalCost: OverrideFieldSpec.fromJson(raw['totalCost']),
      stationName: OverrideFieldSpec.fromJson(raw['stationName']),
      fuelType: OverrideFieldSpec.fromJson(raw['fuelType']),
      date: OverrideFieldSpec.fromJson(raw['date']),
    );
  }
}

/// Registry of per-station receipt parser overrides (phase 1 of #759).
///
/// The registry loads `assets/receipt_overrides/index.json` once on
/// demand. The JSON is a top-level object mapping `stationId` to an
/// [OverrideSpec] JSON. Missing asset, malformed JSON, or unparseable
/// entries are logged and the registry behaves as empty — the app keeps
/// running with default parser behaviour.
///
/// Intended use: a small catalogue of independent stations whose receipt
/// layout doesn't match any known brand. The per-station override lets
/// us fix a single pump without adding yet another brand branch to the
/// parser.
class ReceiptOverrideRegistry {
  /// Default asset path, relative to the bundle root.
  static const String defaultAssetPath = 'assets/receipt_overrides/index.json';

  final String _assetPath;
  final AssetBundle? _bundle;
  final Map<String, OverrideSpec> _entries = <String, OverrideSpec>{};
  bool _loaded = false;

  /// Construct a registry that pulls from [assetPath] (defaults to the
  /// shipped override catalogue). [bundle] is mainly for tests — when
  /// `null`, [rootBundle] is used.
  ReceiptOverrideRegistry({
    String assetPath = defaultAssetPath,
    AssetBundle? bundle,
  })  : _assetPath = assetPath,
        _bundle = bundle;

  /// Build a registry from an in-memory JSON string. Handy for tests and
  /// for feature flags that source overrides from something other than
  /// the shipped asset (e.g. Supabase-delivered JSON in a later phase).
  factory ReceiptOverrideRegistry.fromJsonString(String source) {
    final registry = ReceiptOverrideRegistry();
    registry._ingest(source);
    registry._loaded = true;
    return registry;
  }

  /// Load and cache the override catalogue. Safe to call multiple times —
  /// subsequent calls are no-ops. Missing / malformed data falls back to
  /// an empty registry; the error is logged via [debugPrint].
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;

    String raw;
    try {
      final bundle = _bundle ?? rootBundle;
      raw = await bundle.loadString(_assetPath);
    } catch (e) {
      // rootBundle throws `FlutterError` (an Error subclass) on a missing
      // asset. We deliberately use a wide catch so the app keeps running
      // with no overrides rather than crashing when the catalogue has
      // not been shipped in a given build — the same pattern
      // `CommunityConfig.load()` uses for `tanksync_config.json`.
      debugPrint('ReceiptOverrideRegistry: asset load failed: $e');
      return;
    }

    _ingest(raw);
  }

  /// Return the override spec for [stationId], or `null` when the station
  /// has no override registered. Returns `null` before [load] is called.
  OverrideSpec? lookup(String stationId) {
    final spec = _entries[stationId];
    if (spec == null) return null;
    if (spec.isEmpty) return null;
    return spec;
  }

  /// Number of active override entries — exposed for tests and telemetry.
  @visibleForTesting
  int get entryCount => _entries.length;

  /// Clear cached state. Tests that reuse a registry instance across
  /// assertions can call this to reset between fixture swaps.
  @visibleForTesting
  void reset() {
    _entries.clear();
    _loaded = false;
  }

  void _ingest(String raw) {
    dynamic decoded;
    try {
      decoded = json.decode(raw);
    } on FormatException catch (e) {
      debugPrint(
        'ReceiptOverrideRegistry: malformed JSON in $_assetPath: $e',
      );
      return;
    }

    if (decoded is! Map) {
      debugPrint(
        'ReceiptOverrideRegistry: top-level JSON is not an object in '
        '$_assetPath (got ${decoded.runtimeType}) — skipping.',
      );
      return;
    }

    decoded.forEach((key, value) {
      if (key is! String || key.isEmpty) {
        debugPrint(
          'ReceiptOverrideRegistry: skipping non-string key $key',
        );
        return;
      }
      final spec = OverrideSpec.fromJson(value);
      if (spec == null) {
        debugPrint(
          'ReceiptOverrideRegistry: skipping malformed entry for $key',
        );
        return;
      }
      _entries[key] = spec;
    });
  }
}
