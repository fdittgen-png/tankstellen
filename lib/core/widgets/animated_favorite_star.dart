import 'package:flutter/material.dart';

/// A filled/unfilled star icon that bounces (scale 1.0 → 1.3 → 1.0) and
/// fades its color whenever [isFavorite] flips. Designed as a drop-in
/// replacement for `Icon(isFavorite ? Icons.star : Icons.star_border)`
/// inside an [IconButton] — keeps the 48dp tap target intact because the
/// host `IconButton` owns the hit region; this widget only renders the
/// inner icon.
///
/// Added in #595 so every favorite toggle surface (search card, detail
/// screen, favorites list) shares the same subtle bounce feedback
/// without duplicating animation wiring.
class AnimatedFavoriteStar extends StatefulWidget {
  final bool isFavorite;

  /// Optional size override (passed straight through to [Icon.size]).
  final double? size;

  /// Color used when [isFavorite] is true. Defaults to [Colors.amber] to
  /// match the existing filled-star palette in the search card + app bar.
  final Color activeColor;

  /// Color used when [isFavorite] is false. `null` lets the surrounding
  /// [IconTheme] decide, matching the previous `Icon(color: null)` behaviour.
  final Color? inactiveColor;

  const AnimatedFavoriteStar({
    super.key,
    required this.isFavorite,
    this.size,
    this.activeColor = Colors.amber,
    this.inactiveColor,
  });

  @override
  State<AnimatedFavoriteStar> createState() => _AnimatedFavoriteStarState();
}

class _AnimatedFavoriteStarState extends State<AnimatedFavoriteStar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // 1.0 → 1.3 → 1.0 bounce: two equal-weight tweens over the controller.
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 1,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant AnimatedFavoriteStar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: Icon(
          widget.isFavorite ? Icons.star : Icons.star_border,
          key: ValueKey<bool>(widget.isFavorite),
          color: widget.isFavorite ? widget.activeColor : widget.inactiveColor,
          size: widget.size,
        ),
      ),
    );
  }
}
