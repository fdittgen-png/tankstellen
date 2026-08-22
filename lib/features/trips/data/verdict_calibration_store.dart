// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';

import '../../../core/data/storage_repository.dart';
import '../../../core/logging/error_logger.dart';
import '../domain/gps_driving_features.dart';
import '../domain/gps_kpi_verdict.dart';
import '../domain/trip_verdict.dart';

/// One (verdict, energy-KPI) observation appended when the driver answers
/// the #3501 post-trip prompt.
class VerdictCalibrationRow {
  final String verdict; // TripVerdict.name (never `skipped` — filtered out)
  final double rpa;
  final double pke;
  final double vapos;
  final double coast;

  const VerdictCalibrationRow({
    required this.verdict,
    required this.rpa,
    required this.pke,
    required this.vapos,
    required this.coast,
  });

  Map<String, Object?> toJson() =>
      {'v': verdict, 'rpa': rpa, 'pke': pke, 'va': vapos, 'co': coast};

  static VerdictCalibrationRow? fromJson(Map<String, dynamic> json) {
    final v = json['v'];
    final rpa = json['rpa'], pke = json['pke'], va = json['va'], co = json['co'];
    if (v is! String || rpa is! num || pke is! num || va is! num || co is! num) {
      return null;
    }
    return VerdictCalibrationRow(
      verdict: v,
      rpa: rpa.toDouble(),
      pke: pke.toDouble(),
      vapos: va.toDouble(),
      coast: co.toDouble(),
    );
  }
}

/// #3503 (epic #3498) — the verdict-driven KPI calibration store.
///
/// The default RPA/PKE/VAPOS/coasting bands ([GpsKpiBands.defaults]) are
/// literature-anchored guesses; the drivingAnalysis export used to beg for
/// labelled trips to tune them. The #3501 prompt now collects those labels
/// in-app; this store accumulates (verdict, KPI) rows and derives a
/// personal band set with two conservative rules:
///
///  * **Widen "good"** — when ≥ [kMinSmoothRows] SMOOTH-labelled trips
///    exist and their 75th-percentile KPI sits ABOVE the default good
///    ceiling, the ceiling widens to it (a heavier car / hillier commute
///    legitimately shifts where smooth sits). Never narrows below default.
///  * **Tighten "aggressive"** — when ≥ [kMinAggressiveRows]
///    AGGRESSIVE-labelled trips exist and their 25th percentile sits BELOW
///    the default moderate ceiling, the ceiling tightens to it. Never
///    loosens above default, and never crosses under goodMax × 1.2 (the
///    bands stay monotonic).
///
/// Below the row minimums the defaults stand untouched — exactly the
/// "gate constants stay the defaults until enough verdicts accumulate"
/// contract on #3503. Coasting (inverted polarity) mirrors the rules.
class VerdictCalibrationStore {
  final SettingsStorage _storage;

  const VerdictCalibrationStore(this._storage);

  static const String _key = 'verdictCalibration.rows.v1';

  /// Rolling cap — old labels age out so a driver's style change (or a new
  /// car) re-converges instead of being outvoted by history.
  static const int kMaxRows = 60;

  static const int kMinSmoothRows = 5;
  static const int kMinAggressiveRows = 3;

  /// Append the (verdict, KPI) row for an answered prompt. `skipped` and
  /// null-feature trips are ignored. Best-effort — a write failure is
  /// logged and swallowed.
  Future<void> record(TripVerdict verdict, GpsDrivingFeatures? features) async {
    if (verdict == TripVerdict.skipped || features == null) return;
    try {
      final rows = loadRows()
        ..add(VerdictCalibrationRow(
          verdict: verdict.name,
          rpa: features.relativePositiveAcceleration,
          pke: features.positiveKineticEnergy,
          vapos: features.meanPositiveVa,
          coast: features.coastShare,
        ));
      final capped = rows.length > kMaxRows
          ? rows.sublist(rows.length - kMaxRows)
          : rows;
      await _storage.putSetting(
        _key,
        jsonEncode([for (final r in capped) r.toJson()]),
      );
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: const {'where': 'VerdictCalibrationStore.record'}));
    }
  }

  /// All persisted rows (oldest first). Corrupt rows are skipped.
  List<VerdictCalibrationRow> loadRows() {
    try {
      final raw = _storage.getSetting(_key);
      if (raw is! String || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return [
        for (final e in decoded)
          if (e is Map)
            ?VerdictCalibrationRow.fromJson(e.cast<String, dynamic>()),
      ];
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: const {'where': 'VerdictCalibrationStore.loadRows'}));
      return [];
    }
  }

  /// The personal band set derived from the persisted rows (defaults when
  /// too few labels exist).
  GpsKpiBands deriveBands() => deriveBandsFrom(loadRows());

  /// Pure derivation — unit-testable without storage.
  static GpsKpiBands deriveBandsFrom(List<VerdictCalibrationRow> rows) {
    final smooth =
        rows.where((r) => r.verdict == TripVerdict.smooth.name).toList();
    final aggressive =
        rows.where((r) => r.verdict == TripVerdict.aggressive.name).toList();
    const d = GpsKpiBands.defaults;
    if (smooth.length < kMinSmoothRows &&
        aggressive.length < kMinAggressiveRows) {
      return d;
    }

    double goodMax(double def, double Function(VerdictCalibrationRow) of) {
      if (smooth.length < kMinSmoothRows) return def;
      final p75 = _percentile([for (final r in smooth) of(r)], 0.75);
      return p75 > def ? p75 : def; // widen only
    }

    double moderateMax(
        double def, double good, double Function(VerdictCalibrationRow) of) {
      var out = def;
      if (aggressive.length >= kMinAggressiveRows) {
        final p25 = _percentile([for (final r in aggressive) of(r)], 0.25);
        if (p25 < out) out = p25; // tighten only
      }
      final floor = good * 1.2; // monotonic bands
      return out < floor ? floor : out;
    }

    final rpaGood = goodMax(d.rpaGoodMax, (r) => r.rpa);
    final pkeGood = goodMax(d.pkeGoodMax, (r) => r.pke);
    final vaposGood = goodMax(d.vaposGoodMax, (r) => r.vapos);

    // Coasting is inverted (higher = better): smooth trips' p25 may LOWER
    // the good floor (the driver's smooth trips coast less than assumed);
    // aggressive trips' p75 may RAISE the moderate floor. Same
    // conservative one-direction rules, mirrored.
    var coastGood = d.coastGoodMin;
    if (smooth.length >= kMinSmoothRows) {
      final p25 = _percentile([for (final r in smooth) r.coast], 0.25);
      if (p25 < coastGood) coastGood = p25;
    }
    var coastModerate = d.coastModerateMin;
    if (aggressive.length >= kMinAggressiveRows) {
      final p75 = _percentile([for (final r in aggressive) r.coast], 0.75);
      if (p75 > coastModerate) coastModerate = p75;
    }
    final coastCap = coastGood / 1.2;
    if (coastModerate > coastCap) coastModerate = coastCap;

    return GpsKpiBands(
      rpaGoodMax: rpaGood,
      rpaModerateMax: moderateMax(d.rpaModerateMax, rpaGood, (r) => r.rpa),
      pkeGoodMax: pkeGood,
      pkeModerateMax: moderateMax(d.pkeModerateMax, pkeGood, (r) => r.pke),
      vaposGoodMax: vaposGood,
      vaposModerateMax:
          moderateMax(d.vaposModerateMax, vaposGood, (r) => r.vapos),
      coastGoodMin: coastGood,
      coastModerateMin: coastModerate,
    );
  }

  static double _percentile(List<double> values, double p) {
    final sorted = [...values]..sort();
    final idx = ((sorted.length - 1) * p).round();
    return sorted[idx];
  }
}
