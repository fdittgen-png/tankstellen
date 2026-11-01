// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../../trips/api.dart';
import '../lessons/rules/combustion_health_rule.dart';

/// The actual rule result and gates behind the displayed trim magnitude.
/// This deliberately names the pre-fuel-context scan, not a second verdict.
Map<String, Object?> mixtureLessonEvidence(List<TripSample> samples) {
  final signal = combustionHealthSignal(samples);
  return {
    'stage': 'rawSignalBeforeEthanolContextSuppression',
    'fired': signal.fired,
    'kind': signal.kind?.name,
    'reportedMagnitudePct': signal.magnitudePct,
    'sustainedSamples': signal.sustainedSamples,
    'marked': signal.marked,
    'magnitudeDefinition':
        'For trim signals: mean absolute LTFT of compensating '
        'paired warm-running samples, not the mean STFT+LTFT or a MAP inference. '
        'Direction comes from signed STFT+LTFT. For enrichment: percent of warm samples.',
    'gates': {
      'coolantMinimumC': kCombustionWarmCoolantC,
      'minimumQualifyingSamples': kCombustionMinSustainedSamples,
      'combinedTrimMagnitudeMinimumPct': kCombustionTrimBorderlinePct,
      'minimumCompensatingShareOfPairedSamples': 0.5,
      'commandedRichLambdaThreshold': kCombustionRichLambda,
    },
    'limits':
        'Warm coolant is a proxy, not proof of closed-loop operation. '
        'A positive correction does not prove the final mixture remains lean. '
        'Fuel estimates can use the same trim and MAP inputs, so estimated '
        'consumption and this lesson are not independent mechanical evidence.',
  };
}
