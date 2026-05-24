import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../data/trip_history_repository.dart';

/// One row in the Trajets list (#889). Shows date/time + chips for
/// distance, duration, and average consumption. Extracted from
/// `trajets_tab.dart` to keep the tab body under the 400-line guard.
class TrajetRow extends StatelessWidget {
  final TripHistoryEntry entry;
  final VehicleProfile? vehicle;
  final AppLocalizations? l;
  final ThemeData theme;
  final VoidCallback onTap;

  const TrajetRow({
    super.key,
    required this.entry,
    required this.vehicle,
    required this.l,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = entry.summary;
    final startedAt = s.startedAt;
    final durationSec = startedAt != null && s.endedAt != null
        ? s.endedAt!.difference(startedAt).inSeconds
        : null;
    final durationMinutes = durationSec == null ? null : durationSec ~/ 60;
    final isEv = vehicle?.type == VehicleType.ev;
    final avgUnit = isEv ? 'kWh/100 km' : 'L/100 km';
    // Compact density on landscape / tablet widths — drops the
    // per-row vertical margin from 3 → 1 dp and the inner padding
    // from (12, 8) → (10, 4) so a 600+ dp viewport shows ~50 % more
    // trajets without scrolling.
    final compact = MediaQuery.of(context).size.width >= 600;
    final cardMargin = compact
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 1)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 3);
    final innerPadding = compact
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

    return Card(
      key: ValueKey('trajet-${entry.id}'),
      margin: cardMargin,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: innerPadding,
          child: Row(
            children: [
              Icon(Icons.route, size: compact ? 18 : 24),
              SizedBox(width: compact ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      startedAt == null
                          ? (l?.tripHistoryUnknownDate ?? 'Unknown date')
                          : _fmtDate(startedAt),
                      style: compact
                          ? theme.textTheme.bodyMedium
                          : theme.textTheme.titleMedium,
                    ),
                    SizedBox(height: compact ? 2 : 4),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _Chip(
                          icon: Icons.straighten,
                          text: l?.trajetsRowDistance(
                                s.distanceKm.toStringAsFixed(1),
                              ) ??
                              '${s.distanceKm.toStringAsFixed(1)} km',
                        ),
                        if (durationMinutes != null && durationMinutes > 0)
                          _Chip(
                            icon: Icons.timer,
                            text: l?.trajetsRowDuration(
                                  durationMinutes.toString(),
                                ) ??
                                '$durationMinutes min',
                          ),
                        if (s.avgLPer100Km != null)
                          _Chip(
                            icon: Icons.eco,
                            text: l?.trajetsRowAvgConsumption(
                                  s.avgLPer100Km!.toStringAsFixed(1),
                                  avgUnit,
                                ) ??
                                '${s.avgLPer100Km!.toStringAsFixed(1)} $avgUnit',
                          ),
                        if (s.coldStartSurcharge)
                          _Chip(
                            icon: Icons.ac_unit,
                            text: l?.trajetsRowColdStartChip ?? 'Cold start',
                            tooltip: l?.trajetsRowColdStartTooltip ??
                                "Engine didn't reach operating temperature "
                                    'during this trip — fuel consumption '
                                    'was higher than usual.',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $h:$min';
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? tooltip;

  const _Chip({required this.icon, required this.text, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
    final t = tooltip;
    if (t == null) return row;
    return Tooltip(message: t, child: row);
  }
}
