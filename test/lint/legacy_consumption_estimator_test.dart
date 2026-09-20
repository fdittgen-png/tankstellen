// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// #4234 — the **static half** of the legacy-estimator audit: which files
/// in `lib/` may so much as *name* a legacy consumption estimator.
///
/// The executable half
/// (`test/features/consumption/legacy_estimator_consumer_audit_test.dart`)
/// drives the real consumers and proves none of them *selects* a legacy
/// path. It can only drive code it can call, so it cannot see a widget, a
/// provider or a lifecycle file. This scan covers the rest of the tree by
/// a weaker but total rule: **every** file naming a legacy symbol is
/// enumerated here with the role that entitles it to.
///
/// A source scan proves the text, not the code — four regex guards in this
/// repository once reported green while never running at all. So:
///
///  * the scan asserts a **non-empty** match set and names files it must
///    have found, so a pattern that stops matching fails instead of
///    passing vacuously;
///  * the allowlist is **exact both ways** — an entry whose file no longer
///    names a legacy symbol fails, so the list can only shrink;
///  * every rule is mutation-checked against an injected offender.
///
/// Nothing here permits or forbids *behaviour*; it pins the surface area.
/// Retirement of these paths is gated on #4231's replay corpus — see
/// `docs/decisions/0027-legacy-consumption-estimator-deprecation.md`.
void main() {
  /// The legacy vocabulary: the GPS matrix, the physics scale, the two
  /// road-load estimators, their calibrators, and the `rule | fuzzy`
  /// setting.
  final legacySymbol = RegExp(
    r'\b(GpsCalibrationMatrix|GpsMatrixReconciler|PhysicsScaleCalibrator'
    r'|GpsFuelEstimator|GpsLiveFuelEstimator|VehicleCalibrationModeSelector'
    r'|VehicleCalibrationMode|gpsCalibration|physicsScale|calibrationMode)\b',
  );

  /// Why each file is entitled to name one.
  ///
  /// The role vocabulary is deliberately small, and **`consumer` is not in
  /// it**: that is the audit's finding. Every remaining use is a legacy
  /// implementation, a producer that integrates the figure, persistence
  /// that must keep reading old records, or the UI of the retained
  /// `rule | fuzzy` setting. Each is covered by ADR 0027.
  const implementation = 'legacy implementation (ADR 0010 / 0012)';
  const producer = 'producer — integrates the figure at recording time';
  const persistence = 'persistence — historical values must stay readable';
  const settingUi = 'UI of the retained rule|fuzzy baseline-vote setting';
  const maturityUi = 'renders the matrix maturity, not a consumption figure';

  const allowed = <String, String>{
    // ── the legacy estimators and their calibrators ──────────────────
    'lib/core/domain/gps_calibration_matrix.dart': implementation,
    'lib/features/trips/domain/services/gps_fuel_estimator.dart':
        implementation,
    'lib/features/trips/domain/services/gps_live_fuel_estimator.dart':
        implementation,
    'lib/features/trips/domain/services/gps_live_estimate_folder.dart':
        implementation,
    'lib/features/trips/domain/services/gps_matrix_reconciler.dart':
        implementation,
    'lib/features/trips/domain/services/physics_scale_calibrator.dart':
        implementation,

    // ── producers: they integrate, stamp and store; they do not read
    //    a finished figure back out of a legacy path ──────────────────
    'lib/features/obd2/domain/services/obd2_gps_estimate_fallback.dart':
        producer,
    'lib/features/obd2/providers/obd2_recording_pipeline.dart': producer,
    'lib/features/trips/providers/gps_only_recording_pipeline.dart': producer,
    'lib/features/trips/providers/gps_trip_fuel_backfill.dart': producer,
    'lib/features/trips/providers/trip_recording_provider_persist.dart':
        producer,
    'lib/features/fill_ups/providers/consumption_providers_calibration.dart':
        producer,

    // ── persistence: the fields themselves, and the backup codec ─────
    'lib/core/domain/vehicle_profile.dart': persistence,
    'lib/core/domain/vehicle_enums.dart': persistence,
    'lib/features/fill_ups/data/exporters/backup/backup_xml_reader.dart':
        persistence,
    'lib/features/fill_ups/data/exporters/backup/backup_xml_writer.dart':
        persistence,

    // ── the rule|fuzzy setting, which selects a driving-SITUATION
    //    baseline vote, not a consumption estimator (ADR 0022) ────────
    'lib/features/trips/providers/trip_baseline_recorder.dart': settingUi,
    'lib/features/vehicle/providers/calibration_mode_providers.dart':
        settingUi,
    'lib/features/vehicle/presentation/widgets/'
        'vehicle_calibration_mode_selector.dart': settingUi,
    'lib/features/vehicle/presentation/widgets/vehicle_topic_tiles.dart':
        settingUi,
    'lib/features/vehicle/presentation/screens/topics/'
        'vehicle_calibration_topic_screen.dart': settingUi,

    // ── maturity chrome ──────────────────────────────────────────────
    'lib/features/trips/presentation/widgets/gps_matrix_maturity_badge.dart':
        maturityUi,
    'lib/features/trips/presentation/widgets/trip_avg_consumption_card.dart':
        maturityUi,
  };

  /// Files the scan MUST find, or its pattern has rotted.
  const sentinels = [
    'lib/features/trips/domain/services/gps_live_fuel_estimator.dart',
    'lib/core/domain/vehicle_profile.dart',
    'lib/features/vehicle/providers/calibration_mode_providers.dart',
  ];

  /// Strips `//` line comments, so a docstring naming a retired path is
  /// documentation rather than a use.
  String code(String source) => source
      .split('\n')
      .map((l) => l.contains('//') ? l.substring(0, l.indexOf('//')) : l)
      .join('\n');

  Map<String, String> libSources() => {
        for (final f in Directory('lib').listSync(recursive: true))
          if (f is File &&
              f.path.endsWith('.dart') &&
              !f.path.endsWith('.g.dart') &&
              !f.path.endsWith('.freezed.dart') &&
              !f.path.startsWith('lib/l10n/'))
            f.path.replaceAll(r'\', '/'): f.readAsStringSync(),
      };

  /// Paths that name a legacy symbol in real code.
  Set<String> naming(Map<String, String> sources) => {
        for (final e in sources.entries)
          if (legacySymbol.hasMatch(code(e.value))) e.key,
      };

  late Map<String, String> real;
  late Set<String> found;
  setUpAll(() {
    real = libSources();
    found = naming(real);
  });

  group('the real tree', () {
    test('the scan examined lib/ and found the legacy paths', () {
      expect(real.length, greaterThan(500),
          reason: 'the source walk collected almost nothing — it is not '
              'looking at lib/');
      expect(found, isNotEmpty,
          reason: 'no file names a legacy estimator at all: either they are '
              'gone (delete this gate) or the pattern has rotted');
      expect(found, containsAll(sentinels),
          reason: 'a file that certainly names one was not found — the '
              'pattern or the comment stripper is broken');
    });

    test('no file outside the allowlist names a legacy estimator', () {
      expect(found.difference(allowed.keys.toSet()), isEmpty,
          reason: 'a new consumer reached for a legacy consumption '
              'estimator. Route it through ConsumptionEstimate; only add an '
              'allowlist entry if it is a producer, persistence or the '
              'retained setting UI (ADR 0027).');
    });

    test('the allowlist is exact — no stale entry', () {
      expect(allowed.keys.toSet().difference(found), isEmpty,
          reason: 'an allowlisted file no longer names a legacy estimator. '
              'Delete its entry in the same commit — the list may only '
              'shrink.');
    });

    test('no entry is justified as a consumer', () {
      // The audit's finding, pinned: every retained use is a producer,
      // persistence, the setting UI or the legacy implementation itself.
      expect(allowed.values.any((r) => r.toLowerCase().contains('consumer')),
          isFalse);
    });
  });

  group('each rule can fail (mutation check)', () {
    test('an injected consumer that reads physicsScale is caught', () {
      const victim = 'lib/features/trips/presentation/widgets/trajet_row.dart';
      final mutated = {
        ...real,
        victim: '${real[victim]!}\n'
            'double f(v) => v.gpsCalibration.physicsScale;',
      };
      expect(naming(mutated).difference(allowed.keys.toSet()), {victim});
    });

    test('an injected consumer that branches on calibrationMode is caught',
        () {
      const victim =
          'lib/features/fill_ups/domain/services/monthly_insights_'
          'aggregator.dart';
      final mutated = {
        ...real,
        victim: '${real[victim]!}\nbool f(v) => v.calibrationMode == 1;',
      };
      expect(naming(mutated).difference(allowed.keys.toSet()), {victim});
    });

    test('a stale allowlist entry is caught', () {
      const victim =
          'lib/features/trips/presentation/widgets/gps_matrix_maturity_'
          'badge.dart';
      final mutated = {...real, victim: '// nothing legacy here\n'};
      expect(allowed.keys.toSet().difference(naming(mutated)), {victim});
    });

    test('a comment-only mention is not a use', () {
      const victim = 'lib/features/trips/presentation/widgets/trajet_row.dart';
      final mutated = {
        ...real,
        victim: '${real[victim]!}\n// GpsFuelEstimator used to live here',
      };
      expect(naming(mutated).contains(victim), isFalse);
    });
  });
}
