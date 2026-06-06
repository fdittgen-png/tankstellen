// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Per-index start-delay step. 50 ms matches the #595 spec.
const int _kStepMs = 50;

/// Fade duration of a single card.
const int _kFadeMs = 220;

/// Upper bound on the stagger multiplier — a row at index `>= this` is
/// clamped so the last card in a long search fades in no later than
/// `_kMaxStaggered * _kStepMs` after the list mounts.
const int _kMaxStaggered = 10;

/// Fades a child in from `opacity: 0` to `opacity: 1` as one slice of a
/// shared fade timeline, offset by a small per-index delay.
///
/// Added in #595 so the shimmer → results transition feels like a
/// cascade rather than a flash.
///
/// #1773 — every row used to own an [AnimatedOpacity] (its own ticker)
/// plus a one-shot `Timer`; a 50-result search spun up dozens of
/// tickers and timers. Now the whole list shares ONE
/// [AnimationController] ([timelineDuration] long) created by the host;
/// each row is a stateless [Interval] slice of it rendered through a
/// [FadeTransition] — one ticker for the list, none per row, no timers.
class StaggeredFadeIn extends StatefulWidget {
  /// The list-wide fade timeline. The host creates a single
  /// [AnimationController] of [timelineDuration], `forward()`s it, and
  /// passes it to every row.
  final AnimationController controller;

  /// Position within the visible list; clamped at [_kMaxStaggered].
  final int index;

  final Widget child;

  const StaggeredFadeIn({
    super.key,
    required this.controller,
    required this.index,
    required this.child,
  });

  /// Total length of the shared timeline — the last staggered start
  /// offset plus one card's fade. Use this as the controller duration.
  static Duration get timelineDuration =>
      const Duration(milliseconds: _kMaxStaggered * _kStepMs + _kFadeMs);

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn> {
  late CurvedAnimation _opacity;

  @override
  void initState() {
    super.initState();
    _opacity = _buildOpacity();
  }

  @override
  void didUpdateWidget(StaggeredFadeIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.index != widget.index) {
      _opacity.dispose();
      _opacity = _buildOpacity();
    }
  }

  /// The row's opacity is its [Interval] of the shared timeline: it
  /// starts at `clampedIndex * step` and finishes one fade later.
  CurvedAnimation _buildOpacity() {
    final total = (_kMaxStaggered * _kStepMs + _kFadeMs).toDouble();
    final clamped = widget.index.clamp(0, _kMaxStaggered);
    final begin = (clamped * _kStepMs) / total;
    final end = (clamped * _kStepMs + _kFadeMs) / total;
    return CurvedAnimation(
      parent: widget.controller,
      curve: Interval(begin, end, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _opacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // #2972 — reduced-motion guard. With the OS "remove animations" flag on
    // we skip the fade timeline entirely and render the row at its end-state
    // (fully opaque) immediately, so a motion-sensitive user sees the full
    // results list with no cascade and no running ticker slice.
    if (!AppMotion.enabled(context)) return widget.child;
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}
