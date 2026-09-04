// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

/// The app's type scale — **four roles**, one accessor each, no ad-hoc
/// sizes downstream (#3948, Epic #3947).
///
/// Before this helper every screen picked its own size
/// (`theme.textTheme.titleSmall?.copyWith(...)`), which is why nothing
/// read as more important than anything else. A screen now names the
/// *role* of a string and never its size:
///
/// | Role | Slot | Rule — use it for |
/// | --- | --- | --- |
/// | [display] | `displaySmall` w600, tabular | The ONE number a card is about |
/// | [title]   | `titleMedium` w600            | Card titles, station names |
/// | [body]    | `bodyMedium`                  | Everything that is a sentence |
/// | [label]   | `labelSmall`, `onSurfaceVariant` | Units, captions, chip text, freshness |
///
/// [unit] is the label role re-sized to sit on the baseline beside a
/// [display] number ("35,0" + "L", "1,689" + "€/L").
///
/// The roles are strictly ordered by size (display > title > body ≥ label)
/// so the eye lands on the display number first, then the title, then
/// reads — `test/core/theme/app_text_test.dart` pins that order.
///
/// Colour is inherited from the theme (`onSurface`) except for [label] /
/// [unit], which are `onSurfaceVariant` by contract; override with
/// `.copyWith(color: …)` only for a semantic colour (price band, status).
abstract final class AppText {
  /// **Display** — the one number the card exists to show: the price on a
  /// station card, the litres on the tank card, the month's L/100 km.
  ///
  /// Rule: at most **one** display-role value per card, placed top-left;
  /// everything else on the card is subordinate to it. Never use it for
  /// text. Tabular figures keep columns of numbers aligned when several
  /// cards stack.
  static TextStyle display(BuildContext context) {
    final theme = Theme.of(context);
    return _withTabular(theme.textTheme.displaySmall!).copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface,
    );
  }

  /// **Title** — the name of the thing: a station name, a card heading, a
  /// section title inside a sheet.
  ///
  /// Rule: one per card or section; if two things on a card both want to
  /// be the title, one of them is [body]. Weight 600 is what separates it
  /// from body at the same colour.
  static TextStyle title(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.titleMedium!.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface,
    );
  }

  /// **Body** — sentences, addresses, descriptions, list-item text.
  ///
  /// Rule: the default; anything that is neither the focal number, the
  /// title nor a caption is body. Don't bold body to make it "important" —
  /// promote it to [title] instead.
  static TextStyle body(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodyMedium!.copyWith(
      color: theme.colorScheme.onSurface,
    );
  }

  /// **Label** — units, captions, chip text, "updated 3 min ago", table
  /// column headers, secondary metadata.
  ///
  /// Rule: label is *read second*. It is muted (`onSurfaceVariant`) so it
  /// never competes with [body]; it is the right style for a distance +
  /// freshness line under a station name, or the text inside a
  /// `SummaryPill`.
  static TextStyle label(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.labelSmall!.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
  }

  /// **Unit** — the label role sized to sit beside a [display] number.
  ///
  /// Rule: only ever adjacent to a display value, aligned on the
  /// alphabetic baseline:
  ///
  /// ```dart
  /// Row(
  ///   crossAxisAlignment: CrossAxisAlignment.baseline,
  ///   textBaseline: TextBaseline.alphabetic,
  ///   children: [
  ///     Text(value, style: AppText.display(context)),
  ///     const SizedBox(width: Spacing.sm),
  ///     Text(unit, style: AppText.unit(context)),
  ///   ],
  /// )
  /// ```
  ///
  /// It uses `labelLarge` (14 sp) rather than `labelSmall` because 11 sp
  /// next to a 36 sp number disappears; the muted colour keeps it
  /// subordinate.
  static TextStyle unit(BuildContext context) {
    final theme = Theme.of(context);
    return _withTabular(theme.textTheme.labelLarge!).copyWith(
      fontWeight: FontWeight.w500,
      color: theme.colorScheme.onSurfaceVariant,
    );
  }

  /// The tabular-figure feature shared by every numeric role, so digits
  /// take equal width and `1,689` lines up under `1,701`.
  static const FontFeature tabularFigures = FontFeature.tabularFigures();

  static TextStyle _withTabular(TextStyle base) {
    final features = <FontFeature>[
      ...?base.fontFeatures?.where((f) => f.feature != 'tnum'),
      tabularFigures,
    ];
    return base.copyWith(fontFeatures: features);
  }
}
