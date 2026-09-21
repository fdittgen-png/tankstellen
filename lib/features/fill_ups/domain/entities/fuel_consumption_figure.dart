// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../../../core/domain/data_value.dart';

/// Where a per-fuel litres/100 km figure comes from (#3945).
enum FuelConsumptionProvenance {
  /// Measured on the pump: a PURE plein-to-plein window of that very grade
  /// (ADR 0015 — dominant share ≥ 85 %).
  measured,

  /// Modelled: the vehicle's measured consumption on ANOTHER fuel (or its
  /// all-fuel average) converted by the two fuels' energy content. Never
  /// the litres of a blended window credited to a grade — that is the
  /// ADR 0014 collapse ADR 0015 rejected.
  estimated,
}

/// One per-fuel consumption figure together with its provenance, so a
/// surface can render a modelled number VISIBLY as a model (≈, italic,
/// its own semantics) and never pass it off as a measurement.
class FuelConsumptionFigure {
  final double litersPer100km;
  final FuelConsumptionProvenance provenance;

  const FuelConsumptionFigure.measured(this.litersPer100km)
      : provenance = FuelConsumptionProvenance.measured;

  const FuelConsumptionFigure.estimated(this.litersPer100km)
      : provenance = FuelConsumptionProvenance.estimated;

  bool get isEstimated => provenance == FuelConsumptionProvenance.estimated;
  bool get isMeasured => provenance == FuelConsumptionProvenance.measured;

  /// The same fact in the app-wide shape (#4160).
  ///
  /// This type predates [DataValue] and keeps its own enum — it is the
  /// shape the fill-up layer and its tests speak, and rewriting them to
  /// prove a generalisation would be churn. What the generalisation buys
  /// is that a figure crossing into a rendering path arrives as a
  /// [DataValue], where the `≈` of `docs/specs/refuel-economics.md`
  /// trust rule 2 is a property of the type rather than of the widget
  /// author remembering.
  ///
  /// An estimated consumption is a class average, not a figure for this
  /// particular car — [DataBasis.fleetAverage] says so.
  DataValue<double> get asDataValue => isMeasured
      ? DataValue.measured(litersPer100km)
      : DataValue.estimated(litersPer100km, basis: DataBasis.fleetAverage);

  @override
  bool operator ==(Object other) =>
      other is FuelConsumptionFigure &&
      other.litersPer100km == litersPer100km &&
      other.provenance == provenance;

  @override
  int get hashCode => Object.hash(litersPer100km, provenance);

  @override
  String toString() =>
      'FuelConsumptionFigure(${provenance.name}, $litersPer100km L/100 km)';
}
