// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../domain/driving_score.dart';

/// Export actual computed contributions, not a second scoring implementation.
/// Keep full precision so summing the export reproduces clamp then round.
Map<String, Object?> drivingScoreEvidence(DrivingScore s) {
  final deductions = <String, double>{
    'idlingPenalty': s.idlingPenalty,
    'highRpmPenalty': s.highRpmPenalty,
    'hardAccelPenalty': s.hardAccelPenalty,
    'hardBrakePenalty': s.hardBrakePenalty,
    'fullThrottlePenalty': s.fullThrottlePenalty,
    'pedalVelocityPenalty': s.pedalVelocityPenalty,
    'luggingPenalty': s.luggingPenalty,
    'hardShiftPenalty': s.hardShiftPenalty,
    'revWhileStationaryPenalty': s.revWhileStationaryPenalty,
    'smoothnessPenalty': s.smoothnessPenalty,
    'speedEfficiencyPenalty': s.speedEfficiencyPenalty,
    'lambdaEnrichmentPenalty': s.lambdaEnrichmentPenalty,
  };
  final total = deductions.values.fold(0.0, (a, b) => a + b);
  // Preserve the calculator's exact floating-point operation order.
  var raw = 100.0;
  for (final penalty in deductions.values) {
    raw -= penalty;
  }
  raw += s.ecoCreditCoast;
  return {
    'overall': s.score,
    'styleClass': s.styleClass.name,
    'hardAccelCount': s.hardAccelEvents,
    'hardBrakeCount': s.hardBrakeEvents,
    ...deductions,
    'ecoCreditCoast': s.ecoCreditCoast,
    'calculation': {
      'base': 100,
      'totalDeductions': total,
      'totalCredits': s.ecoCreditCoast,
      'unclampedScore': raw,
      'reconstructedScore': raw.clamp(0, 100).round(),
      'matchesExportedScore': raw.clamp(0, 100).round() == s.score,
      'formula':
          'round(clamp(sequentialSubtract(100, penaltiesInExportOrder) + ecoCreditCoast, 0, 100))',
    },
    'interpretation':
        'Heuristic driving score, not a mechanical diagnosis. '
        'The legacy luggingPenalty uses inferred low-gear exposure, not verified '
        'low-RPM lugging. High-RPM exposure uses a uniform 3000 rpm threshold. '
        'A missing coast credit is not a deduction for unavailable fuel-cut data.',
  };
}
