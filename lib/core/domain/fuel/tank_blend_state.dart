// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'fuel_composition.dart';

/// Versioned derived tank snapshot. Null volume means the residual quantity
/// is unknown, including when recording starts with fuel already in the tank.
final class TankBlendState {
  TankBlendState({
    required this.composition,
    required this.totalLitres,
    required this.confidence,
    required Iterable<String> provenance,
    this.modelVersion = currentModelVersion,
  }) : provenance = List.unmodifiable(provenance) {
    if (totalLitres != null && (!totalLitres!.isFinite || totalLitres! < 0)) {
      throw ArgumentError.value(totalLitres, 'totalLitres');
    }
    if (!confidence.isFinite || confidence < 0 || confidence > 1) {
      throw ArgumentError.value(confidence, 'confidence');
    }
    if (modelVersion < 1) throw ArgumentError.value(modelVersion, 'modelVersion');
  }

  static const currentModelVersion = 1;
  final FuelComposition composition;
  final double? totalLitres;
  final double confidence;
  final List<String> provenance;
  final int modelVersion;

  Map<FuelComponent, double>? get componentLitres => totalLitres == null
      ? null
      : Map.unmodifiable({
          for (final entry in composition.fractions.entries)
            entry.key: entry.value * totalLitres!,
        });

  Map<String, Object?> toJson() => {
        'composition': composition.toJson(),
        'totalLitres': totalLitres,
        'confidence': confidence,
        'provenance': provenance,
        'modelVersion': modelVersion,
      };

  factory TankBlendState.fromJson(Map<String, Object?> json) => TankBlendState(
        composition: FuelComposition.fromJson(
            Map<String, Object?>.from(json['composition'] as Map)),
        totalLitres: (json['totalLitres'] as num?)?.toDouble(),
        confidence: (json['confidence'] as num).toDouble(),
        provenance: (json['provenance'] as List<Object?>).cast<String>(),
        modelVersion: json['modelVersion'] as int,
      );
}
