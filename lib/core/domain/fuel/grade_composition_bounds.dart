// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'fuel_composition.dart';
import 'fuel_grade.dart';

/// The chemical composition a commercial [grade] GUARANTEES, with the rest
/// left explicitly unknown (#4275).
///
/// A grade label is not a composition — [FuelComposition]'s own contract
/// says "nominal E5/E10/E85 labels alone remain unknown". What a label does
/// carry is the fuel standard's LIMITS, and a limit is evidence of a floor.
/// So each fraction below is the minimum the standard permits, and the band
/// the standard leaves open is [FuelComponent.unknown]. That keeps
/// [FuelComposition.exactFraction] answering null for every ethanol-bearing
/// grade: nobody learns "exactly 10 % ethanol" from a pump sticker.
///
///  * E5 / E98 (EN 228, E5 class): at most 5 % v/v ethanol — petrol ≥ 95 %.
///    E98 is an octane rating on the E5 base, not 98 % ethanol.
///  * E10 (EN 228, E10 class): at most 10 % v/v ethanol — petrol ≥ 90 %.
///  * E85: the seasonal grades run from ~50 % v/v ethanol (EN 15293's
///    lowest-ethanol class; ASTM D5798 specifies 51 %) up to 85 % —
///    ethanol ≥ 50 %, the rest undetermined.
///  * Diesel / premium diesel (EN 590): up to 7 % v/v FAME, which is not a
///    [FuelComponent] — diesel ≥ 93 %.
///  * LPG (EN 589): the whole volume is LPG.
///  * Anything else (unknown, wildcard, non-liquid grades): unknown.
///
/// Every value is a lower bound, so a volume-weighted sum of these over a
/// blend of grades is itself a valid lower bound — which is what
/// `TankBlendSnapshot.composition` relies on.
FuelComposition guaranteedCompositionOf(FuelGrade grade) => switch (grade) {
      FuelGrade.e5 || FuelGrade.e98 => FuelComposition(const {
          FuelComponent.petrol: 0.95,
          FuelComponent.unknown: 0.05,
        }),
      FuelGrade.e10 => FuelComposition(const {
          FuelComponent.petrol: 0.90,
          FuelComponent.unknown: 0.10,
        }),
      FuelGrade.e85 => FuelComposition(const {
          FuelComponent.ethanol: 0.50,
          FuelComponent.unknown: 0.50,
        }),
      FuelGrade.diesel || FuelGrade.dieselPremium => FuelComposition(const {
          FuelComponent.diesel: 0.93,
          FuelComponent.unknown: 0.07,
        }),
      FuelGrade.lpg => FuelComposition(const {FuelComponent.lpg: 1.0}),
      FuelGrade.cng ||
      FuelGrade.hydrogen ||
      FuelGrade.electric ||
      FuelGrade.wildcard ||
      FuelGrade.unknown =>
        FuelComposition.unknown(),
    };
