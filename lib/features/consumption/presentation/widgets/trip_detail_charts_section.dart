// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'trip_chart_section.dart';
import 'trip_detail_charts.dart';

/// The per-trip telemetry charts, folded into one collapsed-by-default
/// [ExpansionTile] (#1895) so the summary and insight cards above stay the
/// focus. `maintainState` keeps the chart widgets in the tree while collapsed
/// — the Share-to-PNG boundary and the widget tests both rely on every section
/// being present regardless of fold state.
///
/// Each chart section gates on its own if-any-non-null signal: cars (and legacy
/// trips) without the relevant PID emit null on every sample, so the section
/// header is silently skipped rather than rendering an empty card. Extracted
/// from `trip_detail_body.dart` (#2804) to keep that file under the 400-line
/// norm.
class TripDetailChartsSection extends StatelessWidget {
  const TripDetailChartsSection({super.key, required this.samples});

  final List<TripDetailSample> samples;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    final hasRpmSamples = samples.any((s) => s.rpm != null);
    final hasFuelRateSamples = samples.any(
      (s) => s.fuelRateLPerHour != null || s.estimatedFuelRateLPerHour != null,
    );
    final hasEngineLoadSamples = samples.any((s) => s.engineLoadPercent != null);
    final hasThrottleSamples = samples.any(
      (s) => s.pedalPercent != null || s.throttlePercent != null,
    );
    final hasCoolantSamples = samples.any((s) => s.coolantTempC != null);
    final hasAltitudeSamples = samples.any((s) => s.altitudeM != null);
    final hasLambdaSamples = samples.any((s) => s.lambda != null);

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(l?.trajetDetailChartsSection ?? 'Charts'),
        initiallyExpanded: false,
        maintainState: true,
        shape: const Border(),
        collapsedShape: const Border(),
        childrenPadding: const EdgeInsets.only(bottom: 4),
        children: [
          TripChartSection(
            title: l?.trajetDetailChartSpeed ?? 'Speed (km/h)',
            chart: TripDetailSpeedChart(samples: samples),
          ),
          if (hasFuelRateSamples)
            TripChartSection(
              title: l?.trajetDetailChartFuelRate ?? 'Fuel rate (L/h)',
              chart: TripDetailFuelRateChart(samples: samples),
            ),
          if (hasRpmSamples)
            TripChartSection(
              title: l?.trajetDetailChartRpm ?? 'RPM',
              chart: TripDetailRpmChart(samples: samples),
            ),
          if (hasEngineLoadSamples)
            TripChartSection(
              title: l?.trajetDetailChartEngineLoad ?? 'Engine load (%)',
              chart: TripDetailEngineLoadChart(samples: samples),
            ),
          // #2461 — driving-signal charts, each gated on its own
          // if-any-non-null signal (mirrors RPM / engine-load).
          if (hasThrottleSamples)
            TripChartSection(
              title: l?.trajetDetailChartThrottle ?? 'Throttle / pedal (%)',
              chart: TripDetailThrottleChart(samples: samples),
            ),
          if (hasCoolantSamples)
            TripChartSection(
              title: l?.trajetDetailChartCoolant ?? 'Coolant (°C)',
              chart: TripDetailCoolantChart(samples: samples),
            ),
          if (hasAltitudeSamples)
            TripChartSection(
              title: l?.trajetDetailChartAltitude ?? 'Altitude (m)',
              chart: TripDetailAltitudeChart(samples: samples),
            ),
          if (hasLambdaSamples)
            TripChartSection(
              title: l?.trajetDetailChartLambda ?? 'Commanded λ',
              chart: TripDetailLambdaChart(samples: samples),
            ),
        ],
      ),
    );
  }
}
