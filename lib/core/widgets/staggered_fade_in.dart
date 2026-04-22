import 'dart:async';

import 'package:flutter/material.dart';

/// Fades a child in from `opacity: 0` to `opacity: 1` after a small
/// per-index delay — `index * stepMs`, capped at `maxStaggered`
/// positions so that long result lists don't make the user wait.
///
/// Added in #595 so the shimmer → results transition feels like a
/// cascade rather than a flash. Uses [AnimatedOpacity] + a one-shot
/// [Timer] rather than an AnimationController so the widget stays
/// lightweight inside `ListView.builder`.
class StaggeredFadeIn extends StatefulWidget {
  /// Position within the visible list. Capped internally at
  /// [maxStaggered] so item 1000 doesn't wait 50 s to appear.
  final int index;

  /// Per-index delay. 50 ms matches the #595 spec.
  final int stepMs;

  /// Fade duration per card.
  final Duration duration;

  /// Upper bound on the stagger multiplier. Index `>= maxStaggered` is
  /// clamped so the last card in a 50-result search fades in no later
  /// than `maxStaggered * stepMs` after the list mounts.
  final int maxStaggered;

  final Widget child;

  const StaggeredFadeIn({
    super.key,
    required this.index,
    required this.child,
    this.stepMs = 50,
    this.duration = const Duration(milliseconds: 220),
    this.maxStaggered = 10,
  });

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn> {
  double _opacity = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final stagger = widget.index.clamp(0, widget.maxStaggered);
    final delay = Duration(milliseconds: stagger * widget.stepMs);
    if (delay == Duration.zero) {
      // Next microtask so the first frame still registers opacity=0
      // and AnimatedOpacity lerps to 1.0 rather than snapping.
      scheduleMicrotask(() {
        if (mounted) setState(() => _opacity = 1.0);
      });
    } else {
      _timer = Timer(delay, () {
        if (mounted) setState(() => _opacity = 1.0);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: widget.duration,
      curve: Curves.easeInOut,
      child: widget.child,
    );
  }
}
