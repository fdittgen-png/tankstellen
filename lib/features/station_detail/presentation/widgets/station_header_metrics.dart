// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/domain/station.dart';
import '../../../../l10n/app_localizations.dart';
import 'station_brand_helpers.dart';

/// Layout constants + measurement for the collapsing station-detail header
/// (#3902).
///
/// The compact screen hosts the status row + brand header in a
/// `SliverAppBar.flexibleSpace`, whose `expandedHeight` must be known
/// BEFORE layout. It used to be a round `196` (#1989 trimmed it from 220),
/// which still left ~40 dp of empty brand-green under the address on a
/// phone. Instead of another magic number, [stationHeaderExpandedHeight]
/// measures the exact text the header paints — same strings, same styles,
/// same text scaler, same available width — so the band ends
/// [kHeaderBottomInset] below the last line at ANY font setting and never
/// overflows at a raised text scale.
///
/// Every constant here is consumed by BOTH the widgets and the measurement,
/// which is what keeps the two in lockstep.

/// Horizontal inset of the header block inside the sliver band.
const double kHeaderHorizontalPadding = 16;

/// Gap between the pinned toolbar row (back arrow / actions) and the status
/// row.
const double kHeaderTopGap = 8;

/// Gap between the status row and the brand header.
const double kHeaderStatusGap = 8;

/// Space kept under the address so the band does not end flush on the text.
const double kHeaderBottomInset = 16;

/// Diameter of the open / closed / unknown status dot.
const double kStatusDotSize = 12;

/// Size of the compact rating stars trailing the status row.
const double kRatingStarSize = 16;

/// Brand logo square at the start of the brand header row.
const double kBrandLogoSize = 48;

/// Gap between the brand logo and the heading column.
const double kBrandLogoGap = 12;

/// Top padding of the "Independent station" line under the address.
const double kIndependentLineGap = 2;

/// Style of the status-row text ("Open · updated < 1 min ago"); colour is
/// applied by the row itself and does not affect metrics.
TextStyle? headerStatusStyle(ThemeData theme) =>
    theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);

/// Style of the bold brand / name heading.
TextStyle? headerHeadingStyle(ThemeData theme) =>
    theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold);

/// Style of the address subtitle.
TextStyle? headerSubtitleStyle(ThemeData theme) => theme.textTheme.bodyLarge;

/// Style of the muted italic "Independent station" line.
TextStyle? headerIndependentStyle(ThemeData theme) =>
    theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontStyle: FontStyle.italic,
    );

/// The `SliverAppBar.expandedHeight` that fits exactly: toolbar + status row
/// + brand header (heading, address, optional independent line) + insets.
///
/// Measures with a [TextPainter] under the ambient text scaler at the width
/// the heading column really gets (screen − horizontal insets − logo − gap),
/// so a long address that wraps to two lines is budgeted, not clipped.
/// Rounded up to whole dp so the painted text can never exceed the band by
/// a sub-pixel.
double stationHeaderExpandedHeight(BuildContext context, Station station) {
  final theme = Theme.of(context);
  final l10n = AppLocalizations.of(context);
  final scaler = MediaQuery.textScalerOf(context);
  final textDirection = Directionality.of(context);
  final fullWidth = MediaQuery.sizeOf(context).width;
  final textWidth = math.max(
    0.0,
    fullWidth - 2 * kHeaderHorizontalPadding - kBrandLogoSize - kBrandLogoGap,
  );

  double measure(String text, TextStyle? style, double maxWidth) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      textScaler: scaler,
    )..layout(maxWidth: maxWidth);
    final height = painter.height;
    painter.dispose();
    return height;
  }

  // Status row: dot | text | stars — the tallest of the three wins. The text
  // is measured single-line (it ellipsises rather than wraps).
  final statusRow = [
    kStatusDotSize,
    kRatingStarSize,
    measure(l10n.open, headerStatusStyle(theme), double.infinity),
  ].reduce(math.max);

  // Brand header: the logo square vs the heading column.
  final subtitle = stationHeaderSubtitle(station);
  var column = measure(
    stationDisplayHeading(station),
    headerHeadingStyle(theme),
    textWidth,
  );
  if (subtitle != null) {
    column += measure(subtitle, headerSubtitleStyle(theme), textWidth);
  }
  if (isIndependentSentinel(station)) {
    column += kIndependentLineGap +
        measure(l10n.independentStation, headerIndependentStyle(theme),
            textWidth);
  }
  final brandHeader = math.max(kBrandLogoSize, column);

  return (kToolbarHeight +
          kHeaderTopGap +
          statusRow +
          kHeaderStatusGap +
          brandHeader +
          kHeaderBottomInset)
      .ceilToDouble();
}
