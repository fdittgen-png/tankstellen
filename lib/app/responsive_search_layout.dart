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

/// A responsive layout wrapper that adapts its child layout based on screen
/// size and optional foldable device hinge detection.
///
/// On compact screens (< 600dp), shows only [compactBody].
/// On medium screens (600-840dp), shows [compactBody] and [detailBody] side
/// by side with a 1:1 ratio.
/// On expanded screens (> 840dp), shows them with a 2:3 ratio.
///
/// On foldable devices with a visible hinge, the layout splits content
/// around the hinge automatically.
class ResponsiveLayoutWrapper extends StatelessWidget {
  /// The primary content shown on all screen sizes.
  final Widget compactBody;

  /// The detail content shown alongside [compactBody] on wider screens.
  /// If null, [compactBody] is shown full-width regardless of screen size.
  final Widget? detailBody;

  /// When true, the side-by-side split is forced even on a compact-width
  /// screen, using the medium (1:1) ratio. Lets a caller with its own
  /// wider-trigger (e.g. Favorites' "landscape OR ≥600dp") keep splitting
  /// on a sub-600 landscape phone while the breakpoint + ratio logic still
  /// lives here. When false (the default), compact screens show only
  /// [compactBody].
  final bool forceSplit;

  const ResponsiveLayoutWrapper({
    super.key,
    required this.compactBody,
    this.detailBody,
    this.forceSplit = false,
  });

  @override
  Widget build(BuildContext context) {
    if (detailBody == null) return compactBody;

    final size = screenSizeOf(context);
    if (size == ScreenSize.compact && !forceSplit) return compactBody;

    // Check for foldable hinge
    final hinge = displayHingeOf(context);
    if (hinge != null) {
      return _FoldableLayout(
        hinge: hinge,
        leading: compactBody,
        trailing: detailBody!,
      );
    }

    // Expanded: 2:3 ratio; medium (and a forced compact split): equal 1:1.
    final leadingFlex = size == ScreenSize.expanded ? 2 : 1;
    final trailingFlex = size == ScreenSize.expanded ? 3 : 1;

    return Row(
      children: [
        Expanded(flex: leadingFlex, child: compactBody),
        const VerticalDivider(width: 1),
        Expanded(flex: trailingFlex, child: detailBody!),
      ],
    );
  }
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
/// Delegates to [ResponsiveLayoutWrapper] so the breakpoint, the
/// foldable-hinge split and the 1:1 (medium) / 2:3 (expanded) ratios all
/// live in ONE place. Replaces the per-screen hand-rolled `isWideScreen`
/// checks + literal flex `Row`s in Search / Favorites / Fuel / Trajets.
///
/// - On compact screens (< 600dp), shows only [master] full-width — the
///   detail pane is hidden (unless [forceSplit] is set).
/// - On medium / expanded screens, shows [master] beside the detail pane
///   ([detail] when non-null, else [detailPlaceholder]). When both detail
///   and placeholder are null, [master] stays full-width on every size.
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

  /// Forwarded to [ResponsiveLayoutWrapper.forceSplit] — forces the
  /// side-by-side split even on a compact-width screen (medium 1:1 ratio).
  /// Used by Favorites to honour its "landscape OR ≥600dp" trigger.
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
    return ResponsiveLayoutWrapper(
      compactBody: master,
      detailBody: detail ?? detailPlaceholder,
      forceSplit: forceSplit,
    );
  }
}
