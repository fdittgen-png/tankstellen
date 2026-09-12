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
/// #3948 (Epic #3947) — the shell carried **primary-card** semantics: a
/// `surfaceContainerLow` fill with a 1 dp `outlineVariant` edge.
///
/// #4094 — it is a LIST ROW now. Every element was individually
/// reasonable and the problem was cumulative: a rounded, filled, outlined
/// card inside a rounded control inside a rounded navigation, twenty
/// times down a screen, each row announcing its own boundary twice (a
/// fill AND an outline AND a gap). The row now has no fill and no
/// outline; a hairline `outlineVariant` separator divides it from the
/// next, which is one boundary instead of three.
///
/// **Elevation is reserved for the selected row.** A list where nothing
/// floats and one thing does says which one the user picked without
/// spending any colour on it — the #2531 wide layout's selected station
/// is the case this exists for.
///
/// Frame grammar:
/// * margin [Spacing.listCardMargin] (12 horizontal / 4 vertical — #4091)
/// * `Clip.antiAlias`
/// * transparent, elevation 0, a bottom hairline — or, when [selected],
///   `surfaceContainerHigh` at elevation 2 and no separator
/// * shape rounded to [AppRadius.lg] (12) — the canonical card radius
/// * an [InkWell] tap target sharing the same radius
/// * an optional left [BorderSide] accent stripe in [stripeColor], which
///   since #4091 is spent only where it means something
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

  /// #4094 — the one row allowed to float. Elevation is the whole
  /// signal, so it costs no colour.
  final bool selected;

  /// #4094 — draw the hairline that divides this row from the next.
  /// Suppressed on the last row of a list, and on a [selected] row,
  /// which is already separated by floating.
  final bool separator;

  const StationCardShell({
    super.key,
    required this.child,
    this.stripeColor,
    this.stripeWidth = 4,
    this.onTap,
    this.selected = false,
    this.separator = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: Spacing.listCardMargin,
      clipBehavior: Clip.antiAlias,
      elevation: selected ? 2 : 0,
      color: selected ? scheme.surfaceContainerHigh : Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lg,
        // One box carries both edges. The left stripe is the semantic
        // accent (#4091, spent only on the cheapest row); the bottom
        // hairline is the row separator (#4094) — a line UNDER the row
        // rather than a ring around it, so two neighbours share one
        // boundary instead of drawing two.
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: stripeColor == null
                  ? BorderSide.none
                  : BorderSide(color: stripeColor!, width: stripeWidth),
              bottom: (separator && !selected)
                  ? BorderSide(color: scheme.outlineVariant)
                  : BorderSide.none,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
