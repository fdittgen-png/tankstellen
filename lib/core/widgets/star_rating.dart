// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/dark_mode_colors.dart';

/// Interactive 5-star rating widget.
class StarRating extends StatelessWidget {
  final int? rating;
  final ValueChanged<int> onRatingChanged;
  final double starSize;

  const StarRating({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.starSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // #1687 — each star is an icon-only tappable affordance. The icon
    // glyph stays at [starSize], but the tap target is padded out to
    // at least 48 dp (the Material / WCAG minimum) so it is reliably
    // hittable. Each star also carries a semantic label so a screen
    // reader announces the rating action instead of silence.
    final tapTarget = math.max(48.0, starSize);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        final isFilled = rating != null && starNumber <= rating!;
        return Semantics(
          button: true,
          label: l10n?.ratingStarLabel(starNumber) ?? 'Rate $starNumber stars',
          child: GestureDetector(
            onTap: () => onRatingChanged(starNumber),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: tapTarget,
              height: tapTarget,
              child: Center(
                child: Icon(
                  isFilled ? Icons.star : Icons.star_border,
                  // #2526 — the amber/gold `warning` token clears AA on
                  // both surfaces (3.4:1 light, 8.7:1 dark) where plain
                  // `Colors.amber` was only ~1.6:1 on a light card; the
                  // empty star uses the theme hint colour.
                  color: isFilled
                      ? DarkModeColors.warning(context)
                      : DarkModeColors.hintText(context),
                  size: starSize,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
