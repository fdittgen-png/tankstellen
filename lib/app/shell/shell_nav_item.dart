import 'package:flutter/material.dart';

/// A single bottom-nav / NavigationRail destination.
///
/// Holds the outlined + filled icon pair plus the user-facing label.
/// Library-private to the `shell/` subtree — the parent [ShellScreen]
/// builds the canonical 5-item list and passes the visible subset down
/// to [ShellNavRail] / [ShellBottomBar].
class ShellNavItem {
  final IconData outlinedIcon;
  final IconData filledIcon;
  final String label;
  const ShellNavItem(this.outlinedIcon, this.filledIcon, this.label);
}

/// A small icon that bounces (scale up → settle) when [controller]
/// fires. Used by both the bottom nav and the NavigationRail so a tab
/// switch animates identically in both layouts.
///
/// The [controller] is shared with the parent state so a single
/// animation drives every place the icon is shown — keeping the
/// state-of-truth at the shell level instead of forking it per nav
/// surface.
class ShellBounceIcon extends StatelessWidget {
  final AnimationController controller;
  final bool selected;
  final IconData icon;
  final double iconSize;
  final Color color;

  const ShellBounceIcon({
    super.key,
    required this.controller,
    required this.selected,
    required this.icon,
    required this.iconSize,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.25, end: 0.95)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.95, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(controller);

    return AnimatedBuilder(
      animation: scaleAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: scaleAnim.value,
          child: child,
        );
      },
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}
