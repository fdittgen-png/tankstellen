import '../domain/entities/vehicle_profile.dart';
import '../domain/entities/vin_data.dart';

/// Outcome of [VinAutoPopulator.populate] (#1399). The caller persists
/// [profile], surfaces [conflictSummary] in a snackbar when non-null,
/// and tracks [appliedAny] / [didDecodeOnline] for analytics + UI.
class VinAutoPopulationResult {
  /// The freshly-merged profile. Always non-null. When the input had
  /// every field already populated and no detected fields were stored,
  /// this equals the input.
  final VehicleProfile profile;

  /// One-line summary of detected fields that DIFFER from values the
  /// user has already entered (e.g. "Peugeot 208 2019"). Null when no
  /// conflict exists. The UI surfaces a snackbar with an "Apply" CTA
  /// when this is non-null — never silently overwrites.
  final String? conflictSummary;

  /// True when the populator actually wrote at least one user-facing
  /// field on top of [profile] (i.e. some user field was empty AND the
  /// decoded value was non-null). The detected-* fields are always
  /// updated when the decoded value is non-null, regardless.
  final bool appliedAny;

  /// True when the result includes a vPIC-decoded snapshot (online
  /// path was taken). The UI uses this for opt-in nudge analytics —
  /// when the user hasn't consented and we only have offline WMI data,
  /// we may surface a "want fuller details? enable VIN online decode"
  /// hint.
  final bool didDecodeOnline;

  const VinAutoPopulationResult({
    required this.profile,
    required this.conflictSummary,
    required this.appliedAny,
    required this.didDecodeOnline,
  });
}

/// Pure function that merges VIN-decoded fields into a [VehicleProfile]
/// with the auto-population semantics from #1399:
///
///   1. Always update the `detectedX` fields when the decoded value
///      is non-null, regardless of what the user entered. This is what
///      drives the "(detected)" badge.
///   2. When a user-entered field is null OR empty, populate it from
///      the decoded value.
///   3. When a user-entered field is non-null AND differs from the
///      decoded value, leave it alone and surface a snackbar offering
///      to apply.
///   4. PID 0x51 (`pidFuelType`) wins over both offline WMI and online
///      vPIC for the fuel type field — it's the live ECU truth.
///
/// Stateless / testable. The orchestrator (Riverpod service or widget)
/// owns the side effects (Hive write, snackbar, navigation).
class VinAutoPopulator {
  const VinAutoPopulator();

  /// Merge [vin] + [decoded] + [pidFuelType] into [profile] per the
  /// rules in the class doc.
  ///
  /// [now] is injectable for tests; production passes
  /// [DateTime.now] via the default.
  VinAutoPopulationResult populate({
    required VehicleProfile profile,
    required String vin,
    required VinData? decoded,
    required String? pidFuelType,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();

    // Always start from the loaded profile and stamp the read.
    var next = profile.copyWith(
      lastReadVin: vin,
      lastVinReadAt: timestamp,
    );

    // Decoded fields — pull individual values out, defaulting to the
    // existing detected-* on the profile when the freshest decode
    // didn't include them. This means a subsequent offline-only re-read
    // doesn't lose a field a previous vPIC read had populated.
    final detectedMake = decoded?.make ?? profile.detectedMake;
    final detectedModel = decoded?.model ?? profile.detectedModel;
    final detectedYear = decoded?.modelYear ?? profile.detectedYear;
    final detectedDisplacementCc = decoded?.displacementL != null
        ? (decoded!.displacementL! * 1000).round()
        : profile.detectedEngineDisplacementCc;
    // PID 0x51 wins over decoded fuel type. Fall back to the decoded
    // value, then to the previously-stored detected value.
    final detectedFuelType = pidFuelType ??
        _normaliseFuelType(decoded?.fuelTypePrimary) ??
        profile.detectedFuelType;

    next = next.copyWith(
      detectedMake: detectedMake,
      detectedModel: detectedModel,
      detectedYear: detectedYear,
      detectedEngineDisplacementCc: detectedDisplacementCc,
      detectedFuelType: detectedFuelType,
    );

    // Auto-populate empty user fields. "Empty" here means null or
    // empty-string for strings, null for ints. We never overwrite
    // a populated user field — that's surfaced via [conflictSummary]
    // instead.
    var appliedAny = false;
    final conflicts = <String>[];

    if (_isEmpty(profile.make) && detectedMake != null) {
      next = next.copyWith(make: detectedMake);
      appliedAny = true;
    } else if (!_isEmpty(profile.make) &&
        detectedMake != null &&
        profile.make != detectedMake) {
      conflicts.add(detectedMake);
    } else if (!_isEmpty(profile.make) && detectedMake != null) {
      // User value matches decoded — no conflict, no apply.
    } else if (detectedMake != null && conflicts.isEmpty) {
      // detectedMake known but user already had it (or no user value);
      // we still want to surface the summary if other fields conflict.
    }

    if (_isEmpty(profile.model) && detectedModel != null) {
      next = next.copyWith(model: detectedModel);
      appliedAny = true;
    } else if (!_isEmpty(profile.model) &&
        detectedModel != null &&
        profile.model != detectedModel) {
      conflicts.add(detectedModel);
    }

    if (profile.year == null && detectedYear != null) {
      next = next.copyWith(year: detectedYear);
      appliedAny = true;
    } else if (profile.year != null &&
        detectedYear != null &&
        profile.year != detectedYear) {
      conflicts.add(detectedYear.toString());
    }

    if (profile.engineDisplacementCc == null &&
        detectedDisplacementCc != null) {
      next = next.copyWith(engineDisplacementCc: detectedDisplacementCc);
      appliedAny = true;
    }

    if (_isEmpty(profile.preferredFuelType) && detectedFuelType != null) {
      next = next.copyWith(preferredFuelType: detectedFuelType);
      appliedAny = true;
    } else if (!_isEmpty(profile.preferredFuelType) &&
        detectedFuelType != null &&
        profile.preferredFuelType != detectedFuelType) {
      conflicts.add(detectedFuelType);
    }

    // Persist the VIN itself when the user hadn't typed one.
    if (_isEmpty(profile.vin)) {
      next = next.copyWith(vin: vin);
    }

    final summary = _buildConflictSummary(
      conflicts: conflicts,
      detectedMake: detectedMake,
      detectedModel: detectedModel,
      detectedYear: detectedYear,
    );

    return VinAutoPopulationResult(
      profile: next,
      conflictSummary: summary,
      appliedAny: appliedAny,
      didDecodeOnline: decoded?.source == VinDataSource.vpic,
    );
  }

  static bool _isEmpty(String? value) => value == null || value.trim().isEmpty;

  /// Map a vPIC `Fuel Type - Primary` string to the project's
  /// `preferredFuelType` enum keys. Returns null for unrecognised
  /// values so the caller falls back to the offline / PID-0x51 signal.
  static String? _normaliseFuelType(String? value) {
    if (value == null) return null;
    final lower = value.toLowerCase();
    if (lower.contains('diesel')) return 'diesel';
    if (lower.contains('gasoline') ||
        lower.contains('petrol') ||
        lower.contains('e85') ||
        lower.contains('e10') ||
        lower.contains('flex')) {
      return 'petrol';
    }
    if (lower.contains('lpg') || lower.contains('propane')) return 'lpg';
    if (lower.contains('cng') || lower.contains('natural')) return 'cng';
    if (lower.contains('electric')) return 'electric';
    return null;
  }

  /// Build a one-line summary of the detected fields that conflict
  /// with the user's existing entries. Returns null when the conflicts
  /// list is empty — no snackbar is shown in that case.
  static String? _buildConflictSummary({
    required List<String> conflicts,
    required String? detectedMake,
    required String? detectedModel,
    required int? detectedYear,
  }) {
    if (conflicts.isEmpty) return null;
    final parts = <String>[];
    if (detectedMake != null) parts.add(detectedMake);
    if (detectedModel != null) parts.add(detectedModel);
    if (detectedYear != null) parts.add(detectedYear.toString());
    return parts.isEmpty ? conflicts.join(' ') : parts.join(' ');
  }
}
