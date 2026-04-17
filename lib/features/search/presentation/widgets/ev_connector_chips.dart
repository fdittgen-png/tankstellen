import 'package:flutter/material.dart';

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
  static Color colorFor(String type) {
    if (type.contains('CCS')) return const Color(0xFF2196F3); // Blue
    if (type.contains('Type 2')) return const Color(0xFF4CAF50); // Green
    if (type.contains('CHAdeMO')) return const Color(0xFFFF9800); // Orange
    if (type.contains('Tesla')) return const Color(0xFFE91E63); // Pink
    return const Color(0xFF757575); // Grey
  }

  @override
  Widget build(BuildContext context) {
    final visible = connectors.take(maxConnectors).toList();
    final l10n = AppLocalizations.of(context);
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
            final color = colorFor(type);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
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
