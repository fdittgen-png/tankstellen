// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

/// A titled chart row inside the trip-detail charts [ExpansionTile].
///
/// Renders the section [title] above its [chart]. Extracted from
/// `trip_detail_body.dart` (#2490) so the body stays under the 400-line
/// file cap; the body composes one [TripChartSection] per available
/// telemetry series (speed, fuel-rate, RPM, engine-load, throttle,
/// coolant, altitude, λ).
class TripChartSection extends StatelessWidget {
  final String title;
  final Widget chart;

  const TripChartSection({
    super.key,
    required this.title,
    required this.chart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          chart,
        ],
      ),
    );
  }
}
