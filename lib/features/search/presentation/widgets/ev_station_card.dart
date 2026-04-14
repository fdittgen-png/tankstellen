import 'package:flutter/material.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/theme/fuel_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../domain/entities/fuel_type.dart';
import '../../domain/entities/search_result_item.dart';
import 'ev_connector_chips.dart';

class EVStationCard extends StatelessWidget {
  final EVStationResult result;
  final VoidCallback? onTap;

  const EVStationCard({
    super.key,
    required this.result,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final station = result.station;
    final maxPower = result.maxPowerKW;
    final connectors = result.connectorTypes;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: FuelColors.forType(FuelType.electric),
                width: 4,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Status indicator
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: station.isOperational == true
                          ? DarkModeColors.success(context)
                          : DarkModeColors.warning(context),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.ev_station, size: 14,
                        color: Color(0xFF009688)),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Station info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.operator.isNotEmpty
                          ? station.operator
                          : station.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (station.address.isNotEmpty)
                      Text(
                        station.address,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      '${station.postCode} ${station.place}'.trim(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          PriceFormatter.formatDistance(station.dist),
                          style: theme.textTheme.bodySmall,
                        ),
                        if (station.usageCost != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              station.usageCost!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF009688),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Power + connectors
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Max power
                  Text(
                    maxPower > 0 ? '${maxPower.round()} kW' : '--',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF009688),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Connector type chips
                  EvConnectorChips(connectors: connectors),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}
