// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// A double-tap detector that never enters the gesture arena (#4107).
///
/// ## Why not `GestureDetector(onDoubleTap:)`
///
/// A `DoubleTapGestureRecognizer` **holds** the arena for its pointer the
/// moment the first tap lands, and only releases it when the 300 ms
/// double-tap window expires. Every descendant tap — the nav tabs, and
/// for one commit the round search button itself — is therefore withheld
/// for 300 ms before it fires. That is exactly the "the round button
/// does sometimes no longer trigger a research" report #4103 came from:
/// a primary action that answers a third of a second late reads as
/// broken, not slow.
///
/// A [Listener] sits outside the arena entirely. It sees raw pointer
/// downs whatever the recognizers below it go on to decide, competes
/// with nothing, and delays nothing. The second tap of a double-tap does
/// still reach the child — so this is only safe where the child's own tap
/// is cheap and idempotent (switching to the tab you are already on), and
/// that is why it wraps the tab surface and not the search button.
class ShellBarDoubleTap extends StatefulWidget {
  const ShellBarDoubleTap({
    super.key,
    required this.onDoubleTap,
    required this.child,
  });

  /// Fired when two taps land close together in time and space.
  final VoidCallback onDoubleTap;

  final Widget child;

  /// The window a second tap has to arrive in, matching Flutter's own
  /// [kDoubleTapTimeout] so the gesture feels like every other
  /// double-tap in the system.
  static const Duration window = kDoubleTapTimeout;

  /// How far the second tap may land from the first. Flutter's
  /// [kDoubleTapSlop] is measured for a 48 dp target; the bar is a wide
  /// strip, and a user drumming two fingers-widths apart still means
  /// "toggle", so this is deliberately generous.
  static const double slop = 64;

  @override
  State<ShellBarDoubleTap> createState() => _ShellBarDoubleTapState();
}

class _ShellBarDoubleTapState extends State<ShellBarDoubleTap> {
  Duration? _firstAt;
  Offset? _firstAtPosition;

  void _onPointerDown(PointerDownEvent event) {
    final firstAt = _firstAt;
    final firstPos = _firstAtPosition;
    // Event timestamps come from the embedder's clock, so this measures
    // the gesture itself and stays honest under a fake async clock.
    final withinWindow =
        firstAt != null && event.timeStamp - firstAt <= ShellBarDoubleTap.window;
    final withinSlop = firstPos != null &&
        (event.position - firstPos).distance <= ShellBarDoubleTap.slop;
    if (withinWindow && withinSlop) {
      _firstAt = null;
      _firstAtPosition = null;
      widget.onDoubleTap();
      return;
    }
    _firstAt = event.timeStamp;
    _firstAtPosition = event.position;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // Only taps that actually land on the bar count; the transparent
      // gap around it belongs to whatever is behind.
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: _onPointerDown,
      child: widget.child,
    );
  }
}
