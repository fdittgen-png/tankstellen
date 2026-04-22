import 'package:flutter/material.dart';

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

  /// Color flashed when price *drops* (new < old). Defaults to green.
  final Color dropColor;

  /// Color flashed when price *increases* (new > old). Defaults to red.
  final Color increaseColor;

  /// Animation duration. Default 500 ms per #595 spec.
  final Duration duration;

  const AnimatedPriceText({
    super.key,
    required this.price,
    required this.child,
    this.dropColor = const Color(0xFF2E7D32), // Material green 800
    this.increaseColor = const Color(0xFFC62828), // Material red 800
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<AnimatedPriceText> createState() => _AnimatedPriceTextState();
}

class _AnimatedPriceTextState extends State<AnimatedPriceText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  Color? _flashColor;

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
    setState(() {
      _flashColor = newPrice < oldPrice ? widget.dropColor : widget.increaseColor;
    });
    _controller
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Animate a Transform.scale (subtle bounce) wrapping the child, plus
    // an overlay Container whose opacity fades the flash color from
    // ~0.25 at t=0 down to 0 at t=1. Kept simple so the scroll path
    // pays zero cost outside the 500 ms after a real price change.
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final tint = _flashColor;
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
