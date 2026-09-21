// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shell_bar_visibility.dart';

/// Past this much of the pull, releasing settles collapsed (#4169).
///
/// One threshold, not two. Hysteresis exists to stop a control
/// oscillating around its midpoint, and a control with no intermediate
/// resting state cannot oscillate: it always settles at 0 or 1. A second
/// number here would be a knob nobody could defend.
const double kShellBarSettleThreshold = 0.45;

/// A flick this fast decides the direction regardless of how far the
/// finger actually travelled. Unchanged from #4097's velocity gate, so a
/// user who has learned the flick keeps exactly the gesture they know.
const double kShellBarFlingVelocity = 200;

/// Owns the bar's collapse progress and the gesture that drives it
/// (#4169, epic #4167).
///
/// One value, `t` ∈ [0, 1] — 0 expanded, 1 collapsed — handed to
/// [builder]. Every property of the bar is a function of it, so they
/// cannot drift apart the way a set of independent implicit animations
/// could.
///
/// ## Progress is transient; the preference is not
///
/// [ShellBarHidden] stays exactly what it was: the SETTLED, persisted
/// choice, and what the three non-gesture ways back still set. This
/// widget's controller is the live, per-frame value and is deliberately
/// not persisted — putting a 60 fps number into the settings box would
/// be writing to disk for the length of every swipe.
///
/// The two are kept in step in one direction each: a settle writes the
/// preference, and a controller that disagrees with the preference
/// animates to meet it — which covers the long-press, the double-tap and
/// the semantics action, and also the case a change notification cannot:
/// a State reused under a NEW provider scope, where the preference
/// changed while nobody was listening. A drag in flight ignores all of
/// it, so the finger always wins.
class ShellBarCollapse extends ConsumerStatefulWidget {
  const ShellBarCollapse({
    super.key,
    required this.dragExtent,
    required this.enabled,
    required this.builder,
  });

  /// How far the finger must travel to cover the whole collapse. The
  /// bar's own height: the control moves with the gesture at roughly
  /// life size, which is what makes it feel pulled rather than triggered.
  final double dragExtent;

  /// False in landscape, where [ShellNavRail] owns the case and the bar
  /// never hides. The controller then stays pinned at 0 and no drag
  /// recognizer is installed at all.
  final bool enabled;

  final Widget Function(BuildContext context, double t) builder;

  @override
  ConsumerState<ShellBarCollapse> createState() => _ShellBarCollapseState();
}

class _ShellBarCollapseState extends ConsumerState<ShellBarCollapse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// True between drag start and drag end. While it is set, an external
  /// change to the preference must not yank the bar out from under the
  /// finger.
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    final hidden = widget.enabled && ref.read(shellBarHiddenProvider);
    _controller = AnimationController(
      vsync: this,
      duration: kShellBarHideDuration,
      value: hidden ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _settle(double target) {
    unawaited(_controller.animateTo(
      target,
      duration: kShellBarHideDuration,
      curve: Curves.easeOutCubic,
    ));
  }

  void _onDragStart(DragStartDetails _) {
    _dragging = true;
    _controller.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0;
    // Downward is collapse, so a positive delta increases progress. The
    // clamp is what makes over-pulling a no-op rather than a rubber band:
    // there is nothing past collapsed to reveal.
    _controller.value =
        (_controller.value + delta / widget.dragExtent).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails details) {
    _dragging = false;
    final v = details.primaryVelocity ?? 0;
    final double target;
    if (v.abs() >= kShellBarFlingVelocity) {
      // A decisive flick means what it says even from a standing start,
      // which is the gesture #4097 shipped and people already have.
      target = v > 0 ? 1 : 0;
    } else {
      target = _controller.value >= kShellBarSettleThreshold ? 1 : 0;
    }
    _settle(target);
    final hidden = target == 1;
    if (ref.read(shellBarHiddenProvider) != hidden) {
      unawaited(ref.read(shellBarHiddenProvider.notifier).set(hidden));
    }
    unawaited(ref.read(shellSwipeCoachSeenProvider.notifier).markSeen());
  }

  @override
  Widget build(BuildContext context) {
    final hidden = widget.enabled && ref.watch(shellBarHiddenProvider);
    final target = hidden ? 1.0 : 0.0;
    if (!_dragging && !_controller.isAnimating && _controller.value != target) {
      // Safe during build, and deliberately not deferred to a
      // post-frame callback: `animateTo` only starts a ticker — it does
      // not touch `value`, so no listener is notified inside this build.
      // Deferring instead costs the externally-triggered paths (the
      // long-press, the double-tap, the semantics action) one frame of
      // dead time before anything moves, which is the difference
      // between "responds" and "hesitates".
      _settle(target);
    }

    final content = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => widget.builder(context, _controller.value),
    );
    if (!widget.enabled) return content;

    return GestureDetector(
      // #4097/#4169 — a DRAG collapses; tap keeps its current meaning, so
      // nothing the user does today changes. Down hides, up shows, and
      // the target is the bar's full width, not a 56 dp circle.
      //
      // A drag recognizer competes for the pointer but never HOLDS the
      // arena until the finger has actually moved past the slop, so a
      // plain tap on a tab or on the round button still resolves the
      // instant the finger leaves. The double-tap deliberately does not
      // live here — see [ShellBarDoubleTap].
      onVerticalDragStart: _onDragStart,
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: content,
    );
  }
}
