// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../approach/providers/radar_swipe_provider.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/station.dart';
import 'trip_radar_card.dart';

/// Swipe-to-page wrapper around the fallback [RadarCard] (#2661, replacing
/// the #2633 ignore/restore mapping with distance pagination).
///
/// Extracted from `trip_radar_card.dart` to keep that file under the
/// 400-line cap. Wraps the currently-paged candidate in a [Dismissible]
/// that pages the radar in place WITHOUT ever dismissing (every
/// `confirmDismiss` returns `false`):
///
/// - swipe-LEFT (`endToStart`) → `nearer()` — page toward the NEARER
///   station (toward index 0, the nearest);
/// - swipe-RIGHT (`startToEnd`) → `farther(maxIndex)` — page toward the
///   FARTHER station (toward the end of the distance-ranked list).
///
/// Both actions clamp at the ends (idempotent no-ops), so paging never goes
/// blank — the index walk over the ranked [candidates] always lands on a
/// real station. The same two actions are exposed as
/// `customSemanticsActions` so screen-reader users — for whom the
/// horizontal swipe is invisible — get the capability. The existing
/// tap-to-navigate (`RadarCard`'s `Tooltip` + `ListTile.onTap`) is preserved
/// untouched inside the wrapped card.
class RadarSwipeWrapper extends ConsumerWidget {
  final String title;

  /// The distance-ranked priced candidate list (index 0 = nearest).
  final List<Station> candidates;

  /// The station at the current page index (already clamped against
  /// [candidates] by the caller). Tapped to navigate; paged on swipe.
  final Station current;
  final FuelType fuel;
  final bool scanning;

  /// Radar radius in metres (`profile.approachRadiusKm * 1000`) — the
  /// proximity fill bar's "indicated radius" (#2661). Null collapses the bar.
  final double? radiusMeters;

  const RadarSwipeWrapper({
    super.key,
    required this.title,
    required this.candidates,
    required this.current,
    required this.fuel,
    required this.scanning,
    this.radiusMeters,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    final station = current;
    final swipeable = candidates.length > 1;
    final maxIndex = candidates.length - 1;

    final nearerLabel = l.fuelStationRadarNearer;
    final fartherLabel = l.fuelStationRadarFarther;

    final card = RadarCard(
      title: title,
      station: station,
      fuel: fuel,
      distanceMeters: station.dist > 0 ? station.dist * 1000.0 : null,
      live: false,
      scanning: scanning,
      swipeable: swipeable,
      radiusMeters: radiusMeters,
    );

    // Screen-reader actions — the horizontal swipe is invisible to
    // TalkBack/VoiceOver, so expose the same capability explicitly. Both are
    // always available (clamped no-ops at the ends).
    final semanticActions = <CustomSemanticsAction, VoidCallback>{
      CustomSemanticsAction(label: nearerLabel): () =>
          ref.read(radarSwipeProvider.notifier).nearer(),
      CustomSemanticsAction(label: fartherLabel): () =>
          ref.read(radarSwipeProvider.notifier).farther(maxIndex),
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
            // Left swipe → toward the nearer station.
            notifier.nearer();
          } else {
            // Right swipe → toward the farther station.
            notifier.farther(maxIndex);
          }
          return false;
        },
        // Swipe-RIGHT reveal → farther. Pagination is non-destructive, so
        // both hints wear the primary accent (no warning hue).
        background: _SwipeHint(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 24),
          color: theme.colorScheme.primary,
          icon: Icons.chevron_right,
          label: fartherLabel,
          iconFirst: true,
        ),
        // Swipe-LEFT reveal → nearer.
        secondaryBackground: _SwipeHint(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          color: theme.colorScheme.primary,
          icon: Icons.chevron_left,
          label: nearerLabel,
          iconFirst: false,
        ),
        // Fade the new station in as the page advances.
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: KeyedSubtree(key: ValueKey(station.id), child: card),
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

  /// True → icon leads the label (farther hint), false → label leads.
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
