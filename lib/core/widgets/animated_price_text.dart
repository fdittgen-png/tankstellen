// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/dark_mode_colors.dart';

/// Wraps an arbitrary price widget (usually the card/detail RichText) in a
/// one-shot "price changed" animation: subtle scale 1.0 → 1.15 → 1.0 over
/// 500 ms and a brief green (drop) or red (increase) tint overlay.
///
/// The animation only fires when [price] actually changes — identical
/// rebuilds (same price, different parent invalidation) stay inert, so
/// calling `WidgetTester.hasRunningAnimations` after pumping a no-op
/// rebuild returns `false`.
///
/// Added in #595 so `FavoriteStations.loadAndRefresh()` price updates are
/// visually noticeable without forcing every price label through a new
/// text widget tree.
class AnimatedPriceText extends StatefulWidget {
  /// The current price. Used both as the visual source of truth and as
  /// the change detector — when this value changes across rebuilds, the
  /// animation fires.
  final double? price;

  /// The child to animate around. Typically the existing `RichText` /
  /// `Text` price span so we don't duplicate formatting logic here.
  final Widget child;

  /// Color flashed when price *drops* (new < old). When null (#2526) it
  /// resolves at build time to [DarkModeColors.success] so the flash is a
  /// dark-mode-legible green (the old const `#2E7D32` green-800 read only
  /// 3.59:1 on the dark surface).
  final Color? dropColor;

  /// Color flashed when price *increases* (new > old). When null (#2526) it
  /// resolves at build time to [DarkModeColors.error] (the old const
  /// `#C62828` red-800 read only 3.28:1 on the dark surface).
  final Color? increaseColor;

  /// Animation duration. Default 500 ms per #595 spec.
  final Duration duration;

  const AnimatedPriceText({
    super.key,
    required this.price,
    required this.child,
    this.dropColor, // #2526 — null → DarkModeColors.success(context)
    this.increaseColor, // #2526 — null → DarkModeColors.error(context)
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<AnimatedPriceText> createState() => _AnimatedPriceTextState();
}

class _AnimatedPriceTextState extends State<AnimatedPriceText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  /// Whether a flash is currently armed, and its direction. The actual
  /// colour is resolved in [build] (#2526) so it can read the live theme
  /// brightness via [DarkModeColors] — `didUpdateWidget` has no usable
  /// context for a scheme lookup. `null` means no flash is active; `true`
  /// = price drop, `false` = price increase.
  bool? _flashIsDrop;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 1,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant AnimatedPriceText oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldPrice = oldWidget.price;
    final newPrice = widget.price;
    if (oldPrice == null || newPrice == null) return;
    if (oldPrice == newPrice) return;
    // #2972 — reduced-motion guard. When the OS "remove animations" flag is
    // on, skip the flash entirely: no scale bounce, no tint overlay. The
    // child already renders the new price, so the end-state is identical;
    // we just never kick the controller, so `hasRunningAnimations` stays
    // false for a motion-sensitive user.
    if (!AppMotion.enabled(context)) return;
    setState(() {
      _flashIsDrop = newPrice < oldPrice;
    });
    _controller.reset();
    unawaited(_controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // #2526 — resolve the flash colour here so it tracks the live theme.
    // An explicit [widget.dropColor] / [widget.increaseColor] wins; when
    // null we fall back to the dark-mode-legible semantic colours.
    final Color? tint = switch (_flashIsDrop) {
      true => widget.dropColor ?? DarkModeColors.success(context),
      false => widget.increaseColor ?? DarkModeColors.error(context),
      null => null,
    };
    // Animate a Transform.scale (subtle bounce) wrapping the child, plus
    // an overlay Container whose opacity fades the flash color from
    // ~0.25 at t=0 down to 0 at t=1. Kept simple so the scroll path
    // pays zero cost outside the 500 ms after a real price change.
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        // 0.25 → 0 linear fade. Peak low enough that text stays legible
        // when dark-mode palettes push the flash toward neon.
        final flashOpacity =
            tint != null ? (0.25 * (1.0 - t)).clamp(0.0, 1.0) : 0.0;
        return Transform.scale(
          scale: _scale.value,
          alignment: Alignment.centerRight,
          child: Stack(
            children: [
              child ?? const SizedBox.shrink(),
              if (tint != null && flashOpacity > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: tint.withValues(alpha: flashOpacity),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}
