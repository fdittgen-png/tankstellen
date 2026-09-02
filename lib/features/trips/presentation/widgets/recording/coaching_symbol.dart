// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';

/// One permanently-visible eco-coaching cue (#2026) — an icon over a
/// short label that lights up (primary container fill) while its
/// [DrivingCoachingHint] fires and stays greyed out otherwise, so the
/// row of three doubles as a legend.
///
/// #3916 — extracted from `MinimalDriveSummary` so the recording hero
/// reuses the same cue widget without carrying the file over the
/// length cap.
class CoachingSymbol extends StatelessWidget {
  const CoachingSymbol({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.scheme,
  });

  final IconData icon;
  final String label;
  final bool active;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? scheme.primary
        : scheme.onSurfaceVariant.withValues(alpha: 0.4);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: active ? scheme.primaryContainer : Colors.transparent,
        borderRadius: AppRadius.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: color),
          // #2903 — shrink-to-fit so the cue label never overflows its
          // (Expanded) cell at a large text scale / narrow pane.
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
