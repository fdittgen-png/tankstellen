// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/spacing.dart';

/// The shared frame for every station card (#2493).
///
/// Before this widget the fuel `StationCard`, `EvFavoriteCard`,
/// `EVStationCard` and `AllPricesStationCard` each hand-copied the same
/// outer `Card` + `InkWell` + optional left accent stripe, and the copies
/// had quietly drifted (different margins, elevations, radii, and an
/// `EVStationCard` that used `BorderRadius.circular(12)` literals while
/// others used the theme default). `StationCardShell` owns that frame once
/// so the four cards share a single silhouette and only supply their
/// distinct body + stripe colour.
///
/// #3948 (Epic #3947) — the shell carries **primary-card** semantics: a
/// station in the results IS the thing the screen is about, so its frame
/// is the same `surfaceContainerLow` + 1 dp `outlineVariant` + no
/// elevation as `PrimaryCard`. The public API is unchanged; only the frame
/// grammar moved from "elevated filled card" to "outlined primary card".
///
/// Frame grammar:
/// * margin [Spacing.surfaceMargin] (12 horizontal / 8 vertical)
/// * `Clip.antiAlias`
/// * fill `surfaceContainerLow`, 1 dp `outlineVariant` edge, elevation 0
///   (elevation is reserved for things that float)
/// * shape rounded to [AppRadius.lg] (12) — the canonical card radius
/// * an [InkWell] tap target sharing the same radius
/// * an optional left [BorderSide] accent stripe in [stripeColor]
class StationCardShell extends StatelessWidget {
  /// Colour of the left accent stripe. When `null` no stripe is drawn
  /// (e.g. the all-prices card, which carries its colour in the per-fuel
  /// badges instead).
  final Color? stripeColor;

  /// Width of the left accent stripe; ignored when [stripeColor] is null.
  /// The cheapest-fuel card bumps this to `6` to emphasise the winner.
  final double stripeWidth;

  /// The card body. The shell supplies the frame; padding inside the body
  /// is the caller's responsibility (it differs per card).
  final Widget child;

  /// Tap handler forwarded to the [InkWell].
  final VoidCallback? onTap;

  const StationCardShell({
    super.key,
    required this.child,
    this.stripeColor,
    this.stripeWidth = 4,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: Spacing.surfaceMargin,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lg,
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lg,
        child: stripeColor == null
            ? child
            : DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: stripeColor!, width: stripeWidth),
                  ),
                ),
                child: child,
              ),
      ),
    );
  }
}
