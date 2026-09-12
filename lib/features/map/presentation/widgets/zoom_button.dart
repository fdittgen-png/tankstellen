// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/dark_mode_colors.dart';

/// Circular zoom / location control button for the map.
///
/// #4093 — it used to share `price_legend.dart` with the legend, which
/// was never its home; when the legend was retired the button had to
/// move somewhere, and its own file is where it belonged all along.
class ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const ZoomButton({super.key, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: AppRadius.md,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.md,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: DarkModeColors.mapOverlay(context),
            borderRadius: AppRadius.md,
          ),
          child: Icon(
            icon,
            size: 20,
            color: DarkModeColors.mapOverlayIcon(context),
          ),
        ),
      ),
    );
  }
}
