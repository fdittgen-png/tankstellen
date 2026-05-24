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
    // Placeholder kWh/100 km formula for EV trips — full EV telemetry
    // lands with the OBD2 EV PID set. Until then, treat the combustion
    // path as the canonical avg, and just swap the unit label for EV
    // vehicles so the UI reads correctly when an EV trip IS logged.
    final avgUnit = isEv ? 'kWh/100 km' : 'L/100 km';

    return Card(
      key: ValueKey('trajet-${entry.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.route, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      startedAt == null
                          ? (l?.tripHistoryUnknownDate ?? 'Unknown date')
                          : _fmtDate(startedAt),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
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
