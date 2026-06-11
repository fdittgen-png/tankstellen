// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:ui' show DisplayFeatureType;

import 'package:flutter/material.dart';

/// Responsive breakpoints following Material Design 3 guidelines.
///
/// - Compact (phone): < 600dp
/// - Medium (tablet portrait / foldable): 600-840dp
/// - Expanded (tablet landscape / desktop): > 840dp
enum ScreenSize { compact, medium, expanded }

/// Returns the [ScreenSize] category based on the screen width.
ScreenSize screenSizeOf(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return screenSizeFromWidth(width);
}

/// Returns the [ScreenSize] category for a given width in logical pixels.
///
/// Pure function for easy testing without a [BuildContext].
ScreenSize screenSizeFromWidth(double width) {
  if (width >= 840) return ScreenSize.expanded;
  if (width >= 600) return ScreenSize.medium;
  return ScreenSize.compact;
}

/// Determines if the screen is wide enough for split layout.
/// Threshold: 600dp (typical tablet/landscape breakpoint).
///
/// Maintained for backward compatibility — prefer [screenSizeOf] for new code.
bool isWideScreen(BuildContext context) =>
    MediaQuery.of(context).size.width >= 600;

/// Detects whether the device has a display hinge (foldable device).
///
/// Uses [MediaQuery.displayFeatures] to check for a fold or hinge.
/// Returns the hinge bounds if found, or null for regular devices.
Rect? displayHingeOf(BuildContext context) {
  final features = MediaQuery.of(context).displayFeatures;
  for (final feature in features) {
    if (feature.type == DisplayFeatureType.hinge ||
        feature.type == DisplayFeatureType.fold) {
      return feature.bounds;
    }
  }
  return null;
}

/// Layout for foldable devices that positions content around the hinge.
class _FoldableLayout extends StatelessWidget {
  final Rect hinge;
  final Widget leading;
  final Widget trailing;

  const _FoldableLayout({
    required this.hinge,
    required this.leading,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: hinge.left, child: leading),
        SizedBox(width: hinge.width),
        Expanded(child: trailing),
      ],
    );
  }
}

/// Shared master/detail scaffold for the app's two-pane wide layouts.
///
/// The breakpoint, the foldable-hinge split and the 1:1 (medium) / 2:3
/// (expanded) ratios all live in ONE place here. Replaces the per-screen
/// hand-rolled `isWideScreen` checks + literal flex `Row`s in
/// Search / Favorites / Fuel / Trajets.
///
/// - On compact screens (< 600dp), shows only [master] full-width — the
///   detail pane is hidden (unless [forceSplit] is set).
/// - On medium screens (600-840dp), shows [master] beside the detail pane
///   side by side with a 1:1 ratio; on expanded screens (> 840dp) with a
///   2:3 ratio. The detail pane is [detail] when non-null, else
///   [detailPlaceholder]. When both are null, [master] stays full-width
///   on every size.
/// - On foldable devices with a visible hinge, the layout splits the
///   content around the hinge automatically.
///
/// Selection / navigation logic stays with the caller — this widget only
/// owns the layout container.
class ResponsiveMasterDetail extends StatelessWidget {
  /// The primary pane, shown on every screen size.
  final Widget master;

  /// The active detail pane (e.g. a selected station). Takes precedence
  /// over [detailPlaceholder] on wide screens.
  final Widget? detail;

  /// Fallback detail pane shown on wide screens when [detail] is null
  /// (e.g. an inline map or an empty-selection hint).
  final Widget? detailPlaceholder;

  /// Forces the side-by-side split even on a compact-width screen (medium
  /// 1:1 ratio). Lets a caller with its own wider-trigger (e.g. Favorites'
  /// "landscape OR ≥600dp") keep splitting on a sub-600 landscape phone
  /// while the breakpoint + ratio logic still lives here.
  final bool forceSplit;

  const ResponsiveMasterDetail({
    super.key,
    required this.master,
    this.detail,
    this.detailPlaceholder,
    this.forceSplit = false,
  });

  @override
  Widget build(BuildContext context) {
    final detailBody = detail ?? detailPlaceholder;
    if (detailBody == null) return master;

    final size = screenSizeOf(context);
    if (size == ScreenSize.compact && !forceSplit) return master;

    // Check for foldable hinge
    final hinge = displayHingeOf(context);
    if (hinge != null) {
      return _FoldableLayout(
        hinge: hinge,
        leading: master,
        trailing: detailBody,
      );
    }

    // Expanded: 2:3 ratio; medium (and a forced compact split): equal 1:1.
    final leadingFlex = size == ScreenSize.expanded ? 2 : 1;
    final trailingFlex = size == ScreenSize.expanded ? 3 : 1;

    return Row(
      children: [
        Expanded(flex: leadingFlex, child: master),
        const VerticalDivider(width: 1),
        Expanded(flex: trailingFlex, child: detailBody),
      ],
    );
  }
}
