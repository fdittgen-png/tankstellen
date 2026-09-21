// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/consumption_estimate.dart';
import 'package:tankstellen/core/domain/data_value.dart';

/// #4230 — the contract tests the issue's last acceptance item asks for:
/// "contract tests prove provenance and measured-vs-estimated semantics".
///
/// The invariant worth the most here is the pump-gain rule. Epic #4222's
/// *Source semantics* is binding: a native ECU read is measured and is
/// **never** scaled by the gain; MAF / speed-density is estimated and
/// carries it exactly once; GPS-only is modelled but from an input set
/// the gain does not calibrate. `consumption_source_class_gates_test.dart`
/// asserts those three facts against the trip layer — these assert them
/// against the contract, so the two layers cannot disagree.
void main() {
  const v1 = ConsumptionModelVersion(model: 1, rules: 1);

  ConsumptionEstimate estimate(
    ConsumptionSourceClass sourceClass, {
    double? pumpGain,
    double litres = 6.4,
  }) =>
      ConsumptionEstimate(
        litresPer100Km: DataValue<double>.measured(litres),
        sourceClass: sourceClass,
        version: v1,
        pumpGain: pumpGain,
      );

  group('the pump-gain rule is a property of the source class', () {
    test('only the estimated class may carry a gain', () {
      expect(ConsumptionSourceClass.estimated.pumpGainApplies, isTrue);
      for (final other in [
        ConsumptionSourceClass.measured,
        ConsumptionSourceClass.gpsOnly,
        ConsumptionSourceClass.none,
      ]) {
        expect(other.pumpGainApplies, isFalse,
            reason: '${other.name} must never be rescaled by the pump gain');
      }
    });

    test('a gain on a MEASURED figure is inconsistent', () {
      // The corruption this exists to catch: rescaling an ECU reading by
      // a gain learned for the estimated branch turns a measurement into
      // a guess while it still claims to be measured.
      expect(
        estimate(ConsumptionSourceClass.measured, pumpGain: 1.05).isConsistent,
        isFalse,
      );
    });

    test('a gain on a GPS-ONLY figure is inconsistent', () {
      // The gain anchors an engine-derived estimate against the pump. A
      // GPS figure comes from the road-load model and was never
      // multiplied by it, so applying one would double-count.
      expect(
        estimate(ConsumptionSourceClass.gpsOnly, pumpGain: 0.92).isConsistent,
        isFalse,
      );
    });

    test('a gain on an ESTIMATED figure is consistent', () {
      expect(
        estimate(ConsumptionSourceClass.estimated, pumpGain: 1.05).isConsistent,
        isTrue,
      );
    });

    test('no gain at all is consistent on every class', () {
      for (final c in ConsumptionSourceClass.values) {
        expect(estimate(c).isConsistent, isTrue,
            reason: 'an unscaled ${c.name} figure is always legal');
      }
    });
  });

  group('measured-vs-estimated reads the source class, not the value', () {
    test('only measured is measured', () {
      expect(estimate(ConsumptionSourceClass.measured).isMeasured, isTrue);
      for (final other in [
        ConsumptionSourceClass.estimated,
        ConsumptionSourceClass.gpsOnly,
        ConsumptionSourceClass.none,
      ]) {
        expect(estimate(other).isMeasured, isFalse);
      }
    });

    test('a STALE measured figure is still measured provenance', () {
      // Staleness is the DataValue's business; it does not demote a
      // measurement to a model. Reading provenance off the DataValue case
      // would say "not measured" here, which is wrong.
      const stale = ConsumptionEstimate(
        litresPer100Km: DataValue<double>.stale(6.4, age: Duration(days: 3)),
        sourceClass: ConsumptionSourceClass.measured,
        version: v1,
      );

      expect(stale.isMeasured, isTrue);
      expect(stale.litresPer100Km.isQualified, isTrue,
          reason: 'the caveat belongs to the value, not to the provenance');
    });
  });

  group('an absent figure is stated, never defaulted', () {
    test('unavailable carries its reason and classifies as none', () {
      final gone = ConsumptionEstimate.unavailable(
        reason: DataUnknownReason.notMeasuredYet,
        version: v1,
      );

      expect(gone.sourceClass, ConsumptionSourceClass.none);
      expect(gone.litresPer100Km.isKnown, isFalse);
      expect(gone.litresPer100Km.valueOrNull, isNull);
      expect(
        gone.litresPer100Km,
        const Unknown<double>(reason: DataUnknownReason.notMeasuredYet),
        reason: 'trust rule 1 — a missing input says WHY, so the UI can '
            'explain rather than render a dash',
      );
    });

    test('an unversioned figure says so instead of claiming model 1 (#4233)',
        () {
      // Legacy trips and the batch GPS estimator carry no version (ADR 0024
      // §6): the contract must be able to state that.
      const legacy = ConsumptionEstimate(
        litresPer100Km:
            DataValue<double>.estimated(5.5, basis: DataBasis.derived),
        sourceClass: ConsumptionSourceClass.gpsOnly,
      );
      expect(legacy.version, isNull);
      expect(
        ConsumptionEstimate.unavailable(
                reason: DataUnknownReason.notMeasuredYet)
            .version,
        isNull,
      );
    });

    test('mapping an unknown cannot launder it into a value', () {
      final gone = ConsumptionEstimate.unavailable(
        reason: DataUnknownReason.missingVehicleData,
        version: v1,
      );

      final doubled = gone.litresPer100Km.map((v) => v * 2);

      expect(doubled.isKnown, isFalse);
      expect(doubled, isA<Unknown<double>>());
    });
  });

  group('versions are first-class (#4230 acceptance)', () {
    test('a newer model is not older', () {
      const older = ConsumptionModelVersion(model: 1, rules: 9);
      const newer = ConsumptionModelVersion(model: 2, rules: 1);

      expect(older.isOlderThan(newer), isTrue,
          reason: 'the model dominates: a retuned rulebase on an old model '
              'is still an old model');
      expect(newer.isOlderThan(older), isFalse);
    });

    test('within one model, the rulebase version orders', () {
      const older = ConsumptionModelVersion(model: 3, rules: 1);
      const newer = ConsumptionModelVersion(model: 3, rules: 4);

      expect(older.isOlderThan(newer), isTrue);
      expect(newer.isOlderThan(older), isFalse);
    });

    test('an identical version is not older than itself', () {
      expect(v1.isOlderThan(v1), isFalse);
    });

    test('the calibration generation does NOT affect ordering', () {
      // Calibration advances per vehicle, every time a full-to-full fill
      // re-anchors the gain. It says nothing about which build produced
      // the figure, so it must not make one figure "older" than another.
      const a = ConsumptionModelVersion(model: 2, rules: 2, calibration: 1);
      const b = ConsumptionModelVersion(model: 2, rules: 2, calibration: 57);

      expect(a.isOlderThan(b), isFalse);
      expect(b.isOlderThan(a), isFalse);
    });

    test('never calibrated is null, not zero', () {
      const raw = ConsumptionModelVersion(model: 1, rules: 1);

      expect(raw.calibration, isNull,
          reason: '"never calibrated" is a different claim from '
              '"calibrated at generation 0" — the same distinction '
              'PumpGainSource.uncalibrated already draws');
      expect(raw.toJson().containsKey('calibration'), isFalse,
          reason: 'and it stays absent on the wire rather than encoding 0');
    });

    group('JSON', () {
      test('round-trips every field', () {
        const original =
            ConsumptionModelVersion(model: 4, rules: 7, calibration: 12);

        final decoded = ConsumptionModelVersion.tryDecode(original.toJson());

        expect(decoded, original);
        expect(decoded!.calibration, 12);
      });

      test('round-trips an uncalibrated version', () {
        const original = ConsumptionModelVersion(model: 2, rules: 3);

        expect(ConsumptionModelVersion.tryDecode(original.toJson()), original);
      });

      test('an unversioned record decodes to null, not to a default', () {
        // A figure persisted before versions existed has no version
        // object. Inventing model 1 for it would claim a provenance it
        // does not have — the same reasoning TankBlendState uses.
        expect(ConsumptionModelVersion.tryDecode(null), isNull);
        expect(ConsumptionModelVersion.tryDecode(const <String, Object?>{}),
            isNull);
      });

      test('a malformed or out-of-range version decodes to null', () {
        expect(ConsumptionModelVersion.tryDecode('not a map'), isNull);
        expect(
            ConsumptionModelVersion.tryDecode(
                const {'model': 0, 'rules': 1}),
            isNull,
            reason: 'versions start at 1; 0 is not a version');
        expect(
            ConsumptionModelVersion.tryDecode(
                const {'model': 1, 'rules': 'two'}),
            isNull);
        expect(
            ConsumptionModelVersion.tryDecode(const {'model': 1}), isNull,
            reason: 'a half-written version is not a version');
      });

      test('an unreadable calibration degrades to null, not to a throw', () {
        final decoded = ConsumptionModelVersion.tryDecode(
            const {'model': 1, 'rules': 1, 'calibration': 'soon'});

        expect(decoded, isNotNull);
        expect(decoded!.calibration, isNull,
            reason: 'the model and rules are readable, so the record is '
                'usable; only the calibration is unknown');
      });
    });
  });

  group('the contract offers no way to pick an estimator', () {
    test('recording identity travels with the figure', () {
      final at = DateTime.utc(2026, 9, 16, 9, 30);
      final e = ConsumptionEstimate(
        litresPer100Km: const DataValue<double>.estimated(7.1,
            basis: DataBasis.derived),
        sourceClass: ConsumptionSourceClass.estimated,
        version: v1,
        confidence: 0.72,
        pumpGain: 1.04,
        recordedAt: at,
        recordingId: 'trip-42',
      );

      expect(e.recordedAt, at);
      expect(e.recordingId, 'trip-42');
      expect(e.confidence, 0.72);
    });

    test('confidence is a [0,1] fraction or absent', () {
      expect(
        () => ConsumptionEstimate(
          litresPer100Km: const DataValue<double>.measured(6.0),
          sourceClass: ConsumptionSourceClass.measured,
          version: v1,
          confidence: 1.4,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('a measurement carries no confidence figure rather than 1.0', () {
      // "No confidence number" and "perfectly confident" are different
      // claims. An ECU read is not a probability.
      expect(estimate(ConsumptionSourceClass.measured).confidence, isNull);
    });
  });
}
