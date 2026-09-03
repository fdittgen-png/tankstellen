// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Horizontal drag (logical px) that counts as a page swipe.
const double kHelpTipSwipeThreshold = 40;

/// The paging body of a `HelpBanner` (#3938, Epic #3937).
///
/// Renders the CURRENT tip and, when there is more than one, the
/// prev / `n/N` / next group under it. Two deliberate decisions, both
/// carried over from the sibling project's `HelpHint` that solved this
/// first:
///
///  * **No inner `PageView`.** An extra `Scrollable` inside a screen breaks
///    every `scrollUntilVisible` that assumes exactly one, so paging is a
///    plain state change driven by the chevrons and by a horizontal drag.
///  * **Sized by the current tip, not the tallest.** A one-tip surface keeps
///    the footprint the banner had before this widget existed; an
///    [AnimatedSize] smooths the height change when a longer tip pages in.
///
/// The nav group lives in a [Wrap] so that in a narrow pane the chevrons
/// drop to their own line rather than squeezing their 48 dp tap targets.
class HelpTipPager extends StatefulWidget {
  const HelpTipPager({
    super.key,
    required this.tips,
    required this.page,
    required this.onPageChanged,
    required this.keyPrefix,
    this.navLeading,
    this.textStyle,
    this.foreground,
  });

  /// The surface's tips, in teaching order. Never empty.
  final List<String> tips;

  /// Index of the tip on screen — always a valid index into [tips].
  final int page;

  /// Called with the target index (already wrapped) on a chevron tap or a
  /// swipe. The parent owns the page and persists it.
  final ValueChanged<int> onPageChanged;

  /// Prefix for the widget keys, so a screen hosting two bubbles keeps
  /// them addressable in tests (`help-bubble-next-<prefix>`).
  final String keyPrefix;

  /// Control parked at the start of the nav row — the bubble's dismiss
  /// button. Putting it on the nav line rather than beside the text buys
  /// the tip the button's ~70 dp back, which at 320 dp is the difference
  /// between a five-line tip and a twelve-line one.
  final Widget? navLeading;

  final TextStyle? textStyle;
  final Color? foreground;

  @override
  State<HelpTipPager> createState() => _HelpTipPagerState();
}

class _HelpTipPagerState extends State<HelpTipPager> {
  /// +1 when the last navigation went forward, -1 backward — the slide
  /// transition enters from the side the tip "comes from".
  int _direction = 1;

  /// Accumulated horizontal drag of the swipe in flight.
  double _dragDx = 0;

  void _goTo(int target) {
    final count = widget.tips.length;
    final next = ((target % count) + count) % count;
    setState(() => _direction = target >= widget.page ? 1 : -1);
    widget.onPageChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tips = widget.tips;
    // A rebuild with a shorter catalog must never index out of range.
    final page = tips.isEmpty ? 0 : widget.page.clamp(0, tips.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          key: ValueKey('help-bubble-pager-${widget.keyPrefix}'),
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (_) => _dragDx = 0,
          onHorizontalDragUpdate: (details) => _dragDx += details.delta.dx,
          onHorizontalDragEnd: (_) {
            if (tips.length < 2) return;
            // Swiping left reveals the next tip, right the previous — the
            // same wrap as the chevrons.
            if (_dragDx <= -kHelpTipSwipeThreshold) {
              _goTo(page + 1);
            } else if (_dragDx >= kHelpTipSwipeThreshold) {
              _goTo(page - 1);
            }
          },
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: AlignmentDirectional.topStart,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0.15 * _direction, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: SizedBox(
                key: ValueKey('help-bubble-tip-${widget.keyPrefix}-$page'),
                width: double.infinity,
                child: Text(
                  tips.isEmpty ? '' : tips[page],
                  style: widget.textStyle,
                ),
              ),
            ),
          ),
        ),
        if (tips.length > 1)
          // A Wrap, not a Row: in a narrow pane the chevrons must never
          // squeeze the dismiss button below the 48 dp tap-target floor —
          // the nav group drops to its own line instead.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (widget.navLeading != null) widget.navLeading!,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon-only, so the label the glyph replaces has to
                  // live in BOTH a tooltip (long-press) and a semantics
                  // node — an IconButton's tooltip is not a semantics
                  // label.
                  Semantics(
                    label: l10n.helpBubblePreviousTip,
                    button: true,
                    excludeSemantics: true,
                    child: IconButton(
                      key: ValueKey('help-bubble-prev-${widget.keyPrefix}'),
                      tooltip: l10n.helpBubblePreviousTip,
                      icon: const Icon(Icons.navigate_before, size: 20),
                      color: widget.foreground,
                      onPressed: () => _goTo(page - 1),
                    ),
                  ),
                  Semantics(
                    label: l10n.helpBubbleTipPositionSemantic(
                      page + 1,
                      tips.length,
                    ),
                    excludeSemantics: true,
                    child: Text(
                      l10n.helpBubbleTipPosition(page + 1, tips.length),
                      key: ValueKey('help-bubble-position-${widget.keyPrefix}'),
                      style: widget.textStyle,
                    ),
                  ),
                  Semantics(
                    label: l10n.helpBubbleNextTip,
                    button: true,
                    excludeSemantics: true,
                    child: IconButton(
                      key: ValueKey('help-bubble-next-${widget.keyPrefix}'),
                      tooltip: l10n.helpBubbleNextTip,
                      icon: const Icon(Icons.navigate_next, size: 20),
                      color: widget.foreground,
                      onPressed: () => _goTo(page + 1),
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }
}
