// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/vehicle_profile.dart';
import '../../data/trip_history_repository.dart';
import 'trajet_stripe_colors.dart';

/// One row in the Trajets list (#889). Shows date/time + chips for
/// distance, duration, and average consumption. Extracted from
/// `trajets_tab.dart` to keep the tab body under the 400-line guard.
class TrajetRow extends StatelessWidget {
  final TripHistoryEntry entry;
  final VehicleProfile? vehicle;
  final AppLocalizations l;
  final ThemeData theme;
  final VoidCallback onTap;

  /// Whether this trip was shared WITH the user by another account
  /// (#2240). Shared trips are read-only: the row carries a "Shared"
  /// badge so it reads distinctly from owned trips. Defaults to false
  /// — every owned trip renders exactly as before.
  final bool shared;

  const TrajetRow({
    super.key,
    required this.entry,
    required this.vehicle,
    required this.l,
    required this.theme,
    required this.onTap,
    this.shared = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = entry.summary;
    // #2444 — synthetic reconciliation trajets render DISTINCTLY (a
    // warning-coloured row, like the orange correction fill-up) so the
    // user always knows which trips are real vs. injected stand-ins for
    // unrecorded driving. Tapping opens the virtual-trip edit sheet.
    if (s.isVirtual) {
      return _VirtualTrajetRow(entry: entry, l: l, theme: theme, onTap: onTap);
    }
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

    // #2059 + #2108 — 4dp left-edge stripe carries the trip kind at
    // a glance. Green = OBD2-instrumented (real L/100 km from fuel
    // rate), blue = GPS-only (estimated). The colour binding lives
    // in `TrajetStripeColors` so a future theme rework doesn't
    // silently collapse the two hues onto the same olive/brown like
    // the Eco theme's `primary` / `tertiary` did pre-#2108.
    final stripeColor = TrajetStripeColors.forKind(s.kind, theme.brightness);

    return Card(
      key: ValueKey('trajet-${entry.id}'),
      margin: cardMargin,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: stripeColor, width: 4)),
          ),
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
                          ? (l.tripHistoryUnknownDate)
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
                        if (shared)
                          _Chip(icon: Icons.group, text: l.trajetsSharedBadge),
                        _Chip(
                          icon: Icons.straighten,
                          text: l.trajetsRowDistance(
                            s.distanceKm.toStringAsFixed(1),
                          ),
                        ),
                        if (durationMinutes != null && durationMinutes > 0)
                          _Chip(
                            icon: Icons.timer,
                            text: l.trajetsRowDuration(
                              durationMinutes.toString(),
                            ),
                          ),
                        if (s.avgLPer100Km != null)
                          _Chip(
                            icon: Icons.eco,
                            text: l.trajetsRowAvgConsumption(
                              s.avgLPer100Km!.toStringAsFixed(1),
                              avgUnit,
                            ),
                          ),
                        if (s.coldStartSurcharge)
                          _Chip(
                            icon: Icons.ac_unit,
                            text: l.trajetsRowColdStartChip,
                            tooltip: l.trajetsRowColdStartTooltip,
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

/// Distinct row for a synthetic reconciliation trajet (#2444). Mirrors
/// the orange correction-fill-up row: a warning-coloured slim card with
/// an "auto-fix" icon, the missing distance + fuel, and a tap target
/// that opens the virtual-trip edit sheet.
class _VirtualTrajetRow extends StatelessWidget {
  final TripHistoryEntry entry;
  final AppLocalizations l;
  final ThemeData theme;
  final VoidCallback onTap;

  const _VirtualTrajetRow({
    required this.entry,
    required this.l,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = entry.summary;
    final color = DarkModeColors.warning(context);
    final fuel = s.fuelLitersConsumed;
    final detail = StringBuffer('${s.distanceKm.toStringAsFixed(1)} km');
    if (fuel != null) detail.write(' · ${fuel.toStringAsFixed(1)} L');

    return Card(
      key: ValueKey('virtual-trajet-${entry.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.auto_fix_high, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.reconcileVirtualTrajetLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                detail.toString(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
