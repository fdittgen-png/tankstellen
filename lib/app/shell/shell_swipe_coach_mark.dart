// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../l10n/app_localizations.dart';

/// Teaches the swipe-away gesture, once (#4106).
///
/// #4097 is undiscoverable by design — a gesture with no affordance. It
/// has three ways back, but nothing told a user it existed in the first
/// place. This is that one sentence.
///
/// ## Why an [OverlayPortal]
///
/// The hint belongs ABOVE the bar, pointing down at it: sitting on top
/// of the tabs it would cover the labels it is trying to explain, and
/// the bar's own `Stack` clips to 64 dp so it physically cannot grow out
/// of it. An overlay child is laid out against the whole screen, so the
/// pill floats over the body content with its chevrons aimed at the bar
/// — the gesture drawn, not just described.
///
/// Deliberately not a modal, not a dimmed overlay, and not a tour:
///
///  * it animates in (fade + rise) rather than appearing,
///  * the chevrons nudge downward on a loop — the motion IS the
///    instruction, and a still arrow reads as decoration,
///  * it retires itself after [_linger] so a user who ignored it is
///    never nagged,
///  * tapping it, performing the gesture, or the explicit `Dismiss`
///    affordance all close it, and it is shown once ever.
class ShellSwipeCoachMark extends StatefulWidget {
  const ShellSwipeCoachMark({
    super.key,
    required this.onDismiss,
    required this.barHeight,
  });

  final VoidCallback onDismiss;

  /// The bar's own height, so the pill can sit just clear of its top
  /// edge whatever the orientation gives it.
  final double barHeight;

  /// How long an ignored hint stays up. Long enough to read twice at a
  /// glance, short enough that it is gone before it becomes furniture.
  static const Duration _linger = Duration(seconds: 7);

  @override
  State<ShellSwipeCoachMark> createState() => _ShellSwipeCoachMarkState();
}

class _ShellSwipeCoachMarkState extends State<ShellSwipeCoachMark>
    with TickerProviderStateMixin {
  final OverlayPortalController _portal = OverlayPortalController();

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  /// The downward nudge. Slow and small: a hint, not a jitter.
  late final AnimationController _nudge = AnimationController(
    vsync: this,
    duration: _nudgeCycle,
  );

  static const Duration _nudgeCycle = Duration(milliseconds: 1400);

  /// Cycles of the nudge, sized to fill [ShellSwipeCoachMark._linger].
  ///
  /// Deliberately FINITE rather than `repeat()`: an endless animation
  /// never lets a frame scheduler go idle, so every `pumpAndSettle` in
  /// any test that renders this pill would hang until the suite timed
  /// out. It also stops the pill from twitching for the whole seven
  /// seconds — the nudge has said its piece after a few passes.
  static final int _nudgeCycles =
      (ShellSwipeCoachMark._linger.inMilliseconds / _nudgeCycle.inMilliseconds)
          .floor();

  Timer? _retire;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _portal.show();
    unawaited(_enter.forward());
    unawaited(_runNudge());
    _retire = Timer(
        ShellSwipeCoachMark._linger, () => unawaited(_close()));
  }

  @override
  void dispose() {
    _retire?.cancel();
    _enter.dispose();
    _nudge.dispose();
    super.dispose();
  }

  /// Play the nudge a bounded number of times. See [_nudgeCycles].
  Future<void> _runNudge() async {
    for (var i = 0; i < _nudgeCycles; i++) {
      if (!mounted || _closing) return;
      await _nudge.forward(from: 0);
    }
  }

  /// Fade back out before handing the dismissal up, so the hint leaves
  /// the way it arrived instead of blinking off.
  Future<void> _close() async {
    if (_closing || !mounted) return;
    _closing = true;
    _retire?.cancel();
    await _enter.reverse();
    if (!mounted) return;
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: _buildOverlayChild,
      // The hint lives entirely in the overlay; nothing occupies the
      // bar's own stack cell, so it can never intercept a tap meant for
      // the round button beneath it.
      child: const SizedBox.shrink(),
    );
  }

  Widget _buildOverlayChild(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final curve = CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic);
    // Clear of the bar, the system inset below it, and a breath of gap.
    final bottom =
        widget.barHeight + MediaQuery.paddingOf(context).bottom + 14;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom, left: 16, right: 16),
        child: FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(curve),
            child: Semantics(
              liveRegion: true,
              label: l10n.shellSwipeCoachMark,
              button: true,
              onTap: () => unawaited(_close()),
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => unawaited(_close()),
                // Performing the gesture on the hint itself must count as
                // performing it — the bar below reads the same drag.
                onVerticalDragEnd: (_) => unawaited(_close()),
                child: Material(
                  color: theme.colorScheme.inverseSurface,
                  borderRadius: AppRadius.lg,
                  elevation: 6,
                  shadowColor: Colors.black.withValues(alpha: 0.4),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _NudgingChevrons(
                          animation: _nudge,
                          color: theme.colorScheme.onInverseSurface,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            l10n.shellSwipeCoachMark,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onInverseSurface,
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // An explicit way out, for anyone who does not
                        // read a tap-anywhere pill as dismissible.
                        TextButton(
                          onPressed: () => unawaited(_close()),
                          style: TextButton.styleFrom(
                            foregroundColor:
                                theme.colorScheme.inversePrimary,
                            visualDensity: VisualDensity.compact,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 32),
                            tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(l10n.dismiss),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two chevrons that drift down and fade, on a loop — the gesture drawn.
///
/// The pair reads as "keep going down"; a single chevron reads as
/// "collapse", which is the outcome and not the action.
class _NudgingChevrons extends StatelessWidget {
  const _NudgingChevrons({required this.animation, required this.color});

  final Animation<double> animation;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        // One travel per cycle, held still for the back half so the
        // motion has a rest beat instead of pumping continuously.
        final t = (animation.value * 2).clamp(0.0, 1.0);
        final eased = Curves.easeInOut.transform(t);
        return Transform.translate(
          offset: Offset(0, eased * 6),
          child: Opacity(
            opacity: 1 - eased * 0.45,
            child: Icon(
              Icons.keyboard_double_arrow_down_rounded,
              size: 20,
              color: color,
            ),
          ),
        );
      },
    );
  }
}
