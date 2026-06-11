// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../data/obd2_breadcrumb_collector.dart';

/// One row in the diagnostic overlay: timestamp + branch + L/h on
/// line 1, AFR/density/displacement/VE on line 2 (smaller). Colour
/// reflects the sanity flag: green = clean, amber = suspicious-low,
/// red = 5E-vs-MAF divergent.
///
/// Extracted from `obd2_breadcrumb_overlay.dart` (#1993) to keep the
/// host overlay file under the 400-line guard — the row widget is a
/// self-contained presentation piece with no dependencies on the
/// overlay's diagnostic-share / scaffolding helpers.
class Obd2BreadcrumbRow extends StatelessWidget {
  const Obd2BreadcrumbRow({super.key, required this.crumb});

  final Obd2Breadcrumb crumb;

  String get _timestamp {
    final h = crumb.at.hour.toString().padLeft(2, '0');
    final m = crumb.at.minute.toString().padLeft(2, '0');
    final s = crumb.at.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get _branchTag {
    switch (crumb.branch) {
      case Obd2BranchTag.pid5E:
        return '5E';
      case Obd2BranchTag.maf:
        return 'MAF';
      case Obd2BranchTag.speedDensity:
        return 'SD';
      case Obd2BranchTag.none:
        return '--';
    }
  }

  Color _color(BuildContext context) {
    switch (crumb.flag) {
      case Obd2BreadcrumbCollector.flagSuspiciousLow:
        return DarkModeColors.warning(context);
      case Obd2BreadcrumbCollector.flag5eVsMafDivergent:
        return DarkModeColors.error(context);
      default:
        return DarkModeColors.success(context);
    }
  }

  String _formatRate(double? r) =>
      r == null ? '--' : r.toStringAsFixed(2);

  String _formatNum(double? v, {int decimals = 1}) =>
      v == null ? '--' : v.toStringAsFixed(decimals);

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    final secondLine = StringBuffer()
      ..write('AFR=${_formatNum(crumb.afr, decimals: 1)} ')
      ..write('ρ=${_formatNum(crumb.fuelDensityGPerL, decimals: 0)} ')
      ..write('cc=${_formatNum(crumb.engineDisplacementCc, decimals: 0)} ')
      ..write('η=${_formatNum(crumb.volumetricEfficiency, decimals: 2)}');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$_timestamp [$_branchTag] ${_formatRate(crumb.fuelRateLPerHour)} L/h',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontFamily: 'monospace',
              height: 1.2,
            ),
          ),
          Text(
            secondLine.toString(),
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 9,
              fontFamily: 'monospace',
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
