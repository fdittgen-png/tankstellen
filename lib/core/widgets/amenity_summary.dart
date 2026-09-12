// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../domain/station_amenity.dart' hide amenityLabel;
import '../theme/app_text.dart';
import '../../l10n/app_localizations.dart';
import 'amenity_labels.dart';

/// Amenities as one line of text: `Shop · Wash · +2` (#4091).
///
/// The result card used to render `AmenityChips` — a `Wrap` of up to four
/// pills, each with an icon, a border and its own padding. On a phone
/// that wrapped to two rows, so a station with a shop and a car wash cost
/// the card as much height as its price, its name and its address
/// combined. Four bordered pills per row down a list of twenty is also
/// most of what made the screen feel busy.
///
/// Facilities are a tie-breaker, not a reason to drive somewhere, so they
/// get a tie-breaker's weight: the label type, no borders, no icons, two
/// names and a count. The full set — with icons and names — is still on
/// the detail screen, where the user has asked for detail.
///
/// It lives in core because the map's station sheet shows it too
/// (#4093), and a feature may not reach into another feature's widgets.
///
/// The names come from [localizedAmenityLabel], the same switch the
/// chips use, so the two cannot drift apart. The overflow count keeps
/// the #2622 promise that `+N` is never opaque: the hidden facilities
/// are spelled out in the tooltip and the spoken label.
class AmenitySummary extends StatelessWidget {
  const AmenitySummary({
    super.key,
    required this.amenities,
    this.maxNamed = 2,
  });

  final Set<StationAmenity> amenities;

  /// How many facilities are named before the rest become a count.
  final int maxNamed;

  @override
  Widget build(BuildContext context) {
    if (amenities.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final all = amenities.toList();
    final named = all.take(maxNamed).map((a) => localizedAmenityLabel(a, l10n));
    final hidden = all.skip(maxNamed).map((a) => localizedAmenityLabel(a, l10n)).toList();

    // A language-neutral separator, like every other meta line.
    final line = [
      ...named,
      if (hidden.isNotEmpty) '+${hidden.length}',
    ].join(' · ');

    final spoken = hidden.isEmpty
        ? all.map((a) => localizedAmenityLabel(a, l10n)).join(', ')
        : '${all.take(maxNamed).map((a) => localizedAmenityLabel(a, l10n)).join(', ')}, '
            '${l10n.amenityMoreTooltip(hidden.join(', '))}';

    return Tooltip(
      message: spoken,
      child: Semantics(
        label: spoken,
        child: ExcludeSemantics(
          child: Text(
            line,
            style: AppText.label(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
