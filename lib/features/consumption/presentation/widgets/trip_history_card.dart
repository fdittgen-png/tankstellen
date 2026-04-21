import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/trip_history_repository.dart';

/// One row in the trip history list (#726). Renders the headline
/// metrics the user recognises — distance, avg L/100 km, harsh
/// events, idle fraction — so the list reads at a glance.
class TripHistoryCard extends StatelessWidget {
  final TripHistoryEntry entry;

  const TripHistoryCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = entry.summary;
    final startedAt = s.startedAt;
    final distance = s.distanceKm;
    final avg = s.avgLPer100Km;
    final harsh = s.harshBrakes + s.harshAccelerations;
    final durationSec = startedAt != null && s.endedAt != null
        ? s.endedAt!.difference(startedAt).inSeconds
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.route, size: 28),
        title: Text(
          startedAt == null
              ? (l?.tripHistoryUnknownDate ?? 'Unknown date')
              : _fmtDate(startedAt),
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _Chip(
                icon: Icons.route,
                text: '${distance.toStringAsFixed(1)} km',
              ),
              if (avg != null)
                _Chip(
                  icon: Icons.eco,
                  text: '${avg.toStringAsFixed(1)} L/100km',
                ),
              if (durationSec != null && durationSec > 0)
                _Chip(
                  icon: Icons.timer,
                  text: _fmtDuration(Duration(seconds: durationSec)),
                ),
              if (harsh > 0)
                _Chip(
                  icon: Icons.warning_amber,
                  text: '$harsh',
                  warning: true,
                ),
            ],
          ),
        ),
        isThreeLine: true,
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

  static String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool warning;

  const _Chip({
    required this.icon,
    required this.text,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = warning
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
