// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/domain/ev/charging_station.dart';
import '../../../ev/presentation/widgets/connector_status_style.dart';
import 'ev_connector_chips.dart';

/// A single connector row showing type, power, current type, quantity, and status.
class EVConnectorTile extends StatelessWidget {
  final EvConnector connector;
  const EVConnectorTile({super.key, required this.connector});

  String get _typeLabel => connector.rawType ?? connector.type.label;

  /// Surface a status chip whenever the upstream told us anything — either
  /// a free-form label string OR a normalised status that isn't
  /// [ConnectorStatus.unknown]. The chip's colour, icon and text then all
  /// derive from the canonical enum (#2493), so the operational scale shows
  /// localised in every locale instead of only when the API string was
  /// English.
  bool get _hasStatus =>
      connector.statusLabel != null ||
      connector.status != ConnectorStatus.unknown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = _typeLabel;
    // #2493 — connector-family tints are a deliberate per-connector colour
    // scheme (CCS/Type 2/CHAdeMO/Tesla); reuse the single map shared with
    // the connector chips rather than re-declaring it here.
    final connColor = EvConnectorChips.colorFor(label);
    final status = connector.status;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: connColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: connColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${connector.maxPowerKw.round()} kW',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          if (connector.currentType != null)
            Text(
              connector.currentType!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const Spacer(),
          if (connector.quantity > 0)
            Text(
              'x${connector.quantity}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          if (_hasStatus) ...[
            const SizedBox(width: 8),
            Builder(
              builder: (context) {
                final statusCol = status.color(context);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusCol.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(status.icon, size: 12, color: statusCol),
                      const SizedBox(width: 3),
                      Text(
                        status.label(context),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: statusCol,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
