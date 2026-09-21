// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel/fuel_composition.dart';
import 'package:tankstellen/core/domain/fuel/tank_blend_state.dart';

/// #4274 — the versioned derived tank snapshot.
///
/// Two distinctions this type exists to keep, and which these cases pin:
///
///  * **A null [TankBlendState.totalLitres] is not zero litres.** The app
///    routinely starts observing a tank that already has fuel in it, and
///    "I do not know how much is in there" must not become "the tank is
///    empty" — that would make every derived litre figure a fabrication.
///  * **The state is derived and versioned.** `modelVersion` travels with
///    the snapshot so a stored state computed by an older model can be
///    recognised and recomputed rather than trusted blindly.
void main() {
  /// A fully characterised 85/15 petrol-ethanol blend.
  FuelComposition e10ish() => FuelComposition({
        FuelComponent.petrol: 0.85,
        FuelComponent.ethanol: 0.15,
      });

  TankBlendState stateWith({
    FuelComposition? composition,
    double? totalLitres,
    double confidence = 0.8,
    List<String> provenance = const ['fill-up'],
    int modelVersion = TankBlendState.currentModelVersion,
  }) =>
      TankBlendState(
        composition: composition ?? e10ish(),
        totalLitres: totalLitres,
        confidence: confidence,
        provenance: provenance,
        modelVersion: modelVersion,
      );

  group('construction validates the invariant', () {
    test('a negative volume is rejected', () {
      expect(() => stateWith(totalLitres: -1), throwsArgumentError);
    });

    test('a non-finite volume is rejected', () {
      expect(() => stateWith(totalLitres: double.infinity),
          throwsArgumentError);
      expect(() => stateWith(totalLitres: double.nan), throwsArgumentError);
    });

    test('zero litres is a legitimate state — a tank can be empty', () {
      expect(stateWith(totalLitres: 0).totalLitres, 0,
          reason: 'an empty tank is a fact; an unknown volume is null');
    });

    test('confidence outside [0,1] is rejected', () {
      expect(() => stateWith(confidence: -0.1), throwsArgumentError);
      expect(() => stateWith(confidence: 1.1), throwsArgumentError);
      expect(() => stateWith(confidence: double.nan), throwsArgumentError);
    });

    test('confidence at either bound is accepted', () {
      expect(stateWith(confidence: 0).confidence, 0);
      expect(stateWith(confidence: 1).confidence, 1);
    });

    test('a model version below one is rejected', () {
      expect(() => stateWith(modelVersion: 0), throwsArgumentError);
      expect(() => stateWith(modelVersion: -1), throwsArgumentError);
    });

    test('the provenance list is unmodifiable', () {
      final state = stateWith();

      expect(() => state.provenance.add('tampered'), throwsUnsupportedError);
    });
  });

  group('unknown volume is not zero volume (#4274)', () {
    test('componentLitres is null when the volume is unknown', () {
      final state = stateWith(totalLitres: null);

      expect(state.totalLitres, isNull);
      expect(state.componentLitres, isNull,
          reason: 'fractions without a volume cannot yield litres; returning '
              'zeros would invent a measurement');
    });

    test('componentLitres scales the fractions when the volume is known', () {
      final state = stateWith(totalLitres: 40);

      final litres = state.componentLitres;
      expect(litres, isNotNull);
      expect(litres![FuelComponent.petrol], closeTo(34, 1e-9));
      expect(litres[FuelComponent.ethanol], closeTo(6, 1e-9));
    });

    test('an empty tank yields zero litres per component, not null', () {
      final litres = stateWith(totalLitres: 0).componentLitres;

      expect(litres, isNotNull,
          reason: 'zero is a measurement — only null volume is unknown');
      expect(litres![FuelComponent.petrol], 0);
    });

    test('componentLitres is unmodifiable', () {
      final litres = stateWith(totalLitres: 40).componentLitres!;

      expect(() => litres[FuelComponent.diesel] = 1, throwsUnsupportedError);
    });

    test('an unknown composition with a known volume still has litres', () {
      // We know there are 30 litres in there; we do not know what they are.
      // Both halves of that sentence must survive.
      final state = stateWith(
        composition: FuelComposition.unknown(),
        totalLitres: 30,
      );

      expect(state.componentLitres![FuelComponent.unknown], closeTo(30, 1e-9));
      expect(state.composition.exactFraction(FuelComponent.ethanol), isNull);
    });
  });

  group('JSON', () {
    test('round-trips a known state', () {
      final original = stateWith(
        totalLitres: 42.5,
        confidence: 0.6,
        provenance: const ['fill-up', 'recording'],
      );

      final decoded = TankBlendState.fromJson(original.toJson());

      expect(decoded.totalLitres, 42.5);
      expect(decoded.confidence, 0.6);
      expect(decoded.provenance, ['fill-up', 'recording']);
      expect(decoded.modelVersion, TankBlendState.currentModelVersion);
      expect(decoded.composition.exactFraction(FuelComponent.ethanol), 0.15);
    });

    test('round-trips an unknown volume as null, never as zero', () {
      final decoded = TankBlendState.fromJson(stateWith().toJson());

      expect(decoded.totalLitres, isNull,
          reason: 'a null that decodes as 0 would silently claim an empty '
              'tank across every persistence round trip');
      expect(decoded.componentLitres, isNull);
    });

    test('round-trips a fully unknown composition', () {
      final decoded = TankBlendState.fromJson(
          stateWith(composition: FuelComposition.unknown()).toJson());

      expect(decoded.composition.unknownFraction, 1);
    });

    test('a state from a NEWER model version decodes rather than throwing',
        () {
      // The point of carrying modelVersion: an older build must be able to
      // read the record and see that it is newer, instead of failing to
      // read it at all. Recomputation is the consumer's decision.
      final json = stateWith(totalLitres: 20).toJson()
        ..['modelVersion'] = TankBlendState.currentModelVersion + 1;

      final decoded = TankBlendState.fromJson(json);

      expect(decoded.modelVersion, TankBlendState.currentModelVersion + 1);
      expect(decoded.modelVersion, greaterThan(TankBlendState.currentModelVersion),
          reason: 'the consumer can now tell this state is not ours');
    });

    test('the current model version is recorded explicitly', () {
      expect(stateWith().toJson()['modelVersion'],
          TankBlendState.currentModelVersion,
          reason: 'a snapshot with no version cannot be invalidated later');
    });
  });
}
