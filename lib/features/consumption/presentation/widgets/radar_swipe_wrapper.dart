// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../approach/providers/radar_swipe_provider.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/station.dart';
import 'trip_radar_card.dart';

/// Swipe-to-page wrapper around the fallback [RadarCard] (#2633).
///
/// Extracted from `trip_radar_card.dart` to keep that file under the
/// 400-line cap. Wraps the currently-derived candidate in a
/// [Dismissible] that pages the radar in place WITHOUT ever dismissing
/// (every `confirmDismiss` returns `false`):
///
/// - swipe-LEFT (`endToStart`) → `ignore(current.id)` so the derived
///   current advances to the next ranked station;
/// - swipe-RIGHT (`startToEnd`) → `restore()` pops the last-ignored
///   station back (no-op when the stack is empty).
///
/// The same two actions are exposed as `customSemanticsActions` so
/// screen-reader users — for whom the horizontal swipe is invisible —
/// get the capability. The existing tap-to-navigate (`RadarCard`'s
/// `Tooltip` + `ListTile.onTap`) is preserved untouched inside the
/// wrapped card.
///
/// Exhausted case ([current] == null but candidates exist — every
/// station ignored): keeps the last station on screen, shows a
/// "no other station" toast, and resets the ignore stack so the card
/// recovers to the nearest station rather than going blank (#2583).
class RadarSwipeWrapper extends ConsumerStatefulWidget {
  final String title;
  final List<Station> candidates;

  /// The derived current candidate (first ranked station not ignored), or
  /// `null` when every candidate has been swiped past (exhausted).
  final Station? current;
  final List<String> ignored;
  final FuelType fuel;
  final bool scanning;

  const RadarSwipeWrapper({
    super.key,
    required this.title,
    required this.candidates,
    required this.current,
    required this.ignored,
    required this.fuel,
    required this.scanning,
  });

  @override
  ConsumerState<RadarSwipeWrapper> createState() => _RadarSwipeWrapperState();
}

class _RadarSwipeWrapperState extends ConsumerState<RadarSwipeWrapper> {
  @override
  void didUpdateWidget(covariant RadarSwipeWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleExhausted();
  }

  @override
  void initState() {
    super.initState();
    _handleExhausted();
  }

  /// When the list is exhausted (every candidate ignored) recover the
  /// stack to the nearest station and tell the driver there's nothing
  /// further — deferred to a post-frame callback so it never mutates
  /// providers / shows a SnackBar mid-build (#2583).
  void _handleExhausted() {
    if (widget.current != null || widget.candidates.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      SnackBarHelper.show(
        context,
        l?.tripRadarNoOtherStation ?? 'No other station nearby',
      );
      ref.read(radarSwipeProvider.notifier).reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    // Exhausted: keep showing the LAST candidate (never blank, #2583) —
    // the post-frame callback resets the stack so the next frame derives
    // the nearest station again.
    final station = widget.current ?? widget.candidates.last;
    final swipeable = widget.candidates.length > 1 || widget.ignored.isNotEmpty;

    final ignoreLabel = l?.tripRadarIgnoreStation ?? 'Ignore this station';
    final showPreviousLabel =
        l?.tripRadarShowPrevious ?? 'Show previous station';

    final card = RadarCard(
      title: widget.title,
      station: station,
      fuel: widget.fuel,
      distanceMeters: station.dist > 0 ? station.dist * 1000.0 : null,
      live: false,
      scanning: widget.scanning,
      swipeable: swipeable,
    );

    // Screen-reader actions — the horizontal swipe is invisible to
    // TalkBack/VoiceOver, so expose the same capability explicitly.
    final semanticActions = <CustomSemanticsAction, VoidCallback>{
      CustomSemanticsAction(label: ignoreLabel): () =>
          ref.read(radarSwipeProvider.notifier).ignore(station.id),
      if (widget.ignored.isNotEmpty)
        CustomSemanticsAction(label: showPreviousLabel): () =>
            ref.read(radarSwipeProvider.notifier).restore(),
    };

    return Semantics(
      customSemanticsActions: semanticActions,
      child: Dismissible(
        key: ValueKey('radar-swipe-${station.id}'),
        direction: DismissDirection.horizontal,
        dismissThresholds: const {DismissDirection.horizontal: 0.4},
        // ALWAYS false → the card pages in place, never animates away, so
        // the tap-to-navigate target survives every swipe.
        confirmDismiss: (dir) async {
          final notifier = ref.read(radarSwipeProvider.notifier);
          if (dir == DismissDirection.endToStart) {
            notifier.ignore(station.id);
          } else {
            notifier.restore();
          }
          return false;
        },
        // Swipe-RIGHT reveal → restore the previous station.
        background: _SwipeHint(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 24),
          color: theme.colorScheme.primary,
          icon: Icons.undo,
          label: showPreviousLabel,
          iconFirst: true,
        ),
        // Swipe-LEFT reveal → ignore + advance.
        secondaryBackground: _SwipeHint(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          color: DarkModeColors.warning(context),
          icon: Icons.skip_next,
          label: ignoreLabel,
          iconFirst: false,
        ),
        // Fade the new station in as the page advances/restores.
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: KeyedSubtree(
            key: ValueKey(station.id),
            child: card,
          ),
        ),
      ),
    );
  }
}

/// One swipe-reveal background (icon + label) for the radar [Dismissible].
class _SwipeHint extends StatelessWidget {
  final AlignmentGeometry alignment;
  final EdgeInsetsGeometry padding;
  final Color color;
  final IconData icon;
  final String label;

  /// True → icon leads the label (swipe-right hint), false → label leads.
  final bool iconFirst;

  const _SwipeHint({
    required this.alignment,
    required this.padding,
    required this.color,
    required this.icon,
    required this.label,
    required this.iconFirst,
  });

  @override
  Widget build(BuildContext context) {
    final glyph = Icon(icon, color: Colors.white, size: 20);
    final text = Text(
      label,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    );
    return Semantics(
      label: label,
      child: Container(
        alignment: alignment,
        padding: padding,
        color: color,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: iconFirst
              ? [glyph, const SizedBox(width: 8), text]
              : [text, const SizedBox(width: 8), glyph],
        ),
      ),
    );
  }
}
