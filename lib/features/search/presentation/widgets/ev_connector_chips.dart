// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/fuel_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Compact wrap of colored "pills" identifying the connector types on
/// an EV charging station (e.g. CCS, Type 2, CHAdeMO, Tesla). Each pill
/// is colored to match its connector family and the wrap is bounded to
/// at most [maxConnectors] entries to keep the cards visually balanced.
///
/// Pulled out of `ev_station_card.dart` so the card's `build` method
/// drops the inline Wrap block (and the private `_connectorColor`
/// helper) and so the color mapping can be exercised by widget tests in
/// isolation.
///
/// Accessibility (#566): the whole wrap is merged into a single
/// `Semantics` node announcing "Available connectors: CCS, Type 2, …"
/// so TalkBack/VoiceOver read the chip group as one coherent label
/// instead of emitting a stream of isolated chip texts.
class EvConnectorChips extends StatelessWidget {
  final List<String> connectors;
  final int maxConnectors;

  const EvConnectorChips({
    super.key,
    required this.connectors,
    this.maxConnectors = 3,
  });

  /// Maps a connector type label to a brand-recognisable color. Returns
  /// neutral grey for unknown types so the pill still renders without
  /// breaking the layout.
  ///
  /// #2493 — the generic CCS chip now uses the canonical
  /// [FuelColors.evAccent] crystal-blue instead of the ad-hoc Material
  /// blue (`#2196F3`) it used to hard-code, so the EV accent is one token
  /// across every surface. Type 2 / CHAdeMO / Tesla keep their deliberate
  /// per-connector brand hues (green / orange / pink).
  ///
  /// #2526 — [brightness] makes the hue dark-safe. The light identity hues
  /// (e.g. Tesla pink `#E91E63` read only ~3.9:1 as text on the dark
  /// surface) are lightened on dark to a same-family variant that clears
  /// AA, preserving per-connector identity. Callers that omit [brightness]
  /// keep the canonical light identity hue (the value the chip-colour API
  /// and its tests document).
  static Color colorFor(String type, {Brightness brightness = Brightness.light}) {
    final dark = brightness == Brightness.dark;
    if (type.contains('CCS')) return FuelColors.evAccent; // Crystal-blue (already light)
    if (type.contains('Type 2')) {
      return dark ? const Color(0xFF81C784) : const Color(0xFF4CAF50); // Green
    }
    if (type.contains('CHAdeMO')) {
      return dark ? const Color(0xFFFFB74D) : const Color(0xFFFF9800); // Orange
    }
    if (type.contains('Tesla')) {
      return dark ? const Color(0xFFF06292) : const Color(0xFFE91E63); // Pink
    }
    return dark ? const Color(0xFFBDBDBD) : const Color(0xFF757575); // Grey
  }

  @override
  Widget build(BuildContext context) {
    final visible = connectors.take(maxConnectors).toList();
    final l10n = AppLocalizations.of(context);
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final semanticLabel = visible.isEmpty
        ? (l10n?.evConnectorsNone ?? 'No connector information')
        : '${l10n?.evConnectorsLabel ?? "Available connectors"}: '
              '${visible.join(", ")}';

    return Semantics(
      container: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Wrap(
          spacing: 4,
          runSpacing: 2,
          children: visible.map((type) {
            final color = colorFor(type, brightness: brightness);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                // #2526 — raise the fill alpha on dark and add a hairline
                // outline so the pill actually reads against the dark card
                // (the 15%-alpha fill was near-invisible on a dark surface).
                color: color.withValues(alpha: isDark ? 0.22 : 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: color.withValues(alpha: isDark ? 0.6 : 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                type,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
