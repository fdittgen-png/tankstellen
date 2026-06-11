// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/open_now.dart';
import '../../../../core/domain/opening_hours.dart';
import 'opening_hours_format.dart';

/// The hero status line of the opening-hours card (Epic #2707 C2, #2709):
/// a coloured dot + "Open · Closes 19:30" / "Closing soon · …" / "Closed ·
/// Opens 14:00" / "Closed · Opens Mon 06:30", with a compact `24h` badge
/// when the station is around-the-clock.
///
/// Hidden entirely when [computeOpenNow] yields [OpenStatus.unknown] *and*
/// there is no 24h badge to justify the row. The status is derived from the
/// injected [now] so the widget is deterministic under test.
class OpeningHoursStatusLine extends StatelessWidget {
  final WeeklyOpeningHours hours;
  final DateTime now;
  final bool badge24h;

  const OpeningHoursStatusLine({
    super.key,
    required this.hours,
    required this.now,
    required this.badge24h,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final status = computeOpenNow(hours, now);

    // Hidden when unknown — unless a 24h badge still earns the row its place.
    if (status.status == OpenStatus.unknown && !badge24h) {
      return const SizedBox.shrink();
    }

    final isOpen = status.status == OpenStatus.open;
    final closingSoon = isOpen && _closingSoon(status);
    final Color colour = closingSoon
        ? DarkModeColors.warning(context)
        : (isOpen
            ? DarkModeColors.success(context)
            : DarkModeColors.mutedText(context));

    final headline =
        isOpen ? (l10n?.openNow ?? 'Open') : (l10n?.openNowClosed ?? 'Closed');
    final detail = _detailText(status, l10n);

    return Row(
      key: const ValueKey('opening-hours-status-line'),
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
        ),
        const SizedBox(width: Spacing.md),
        Flexible(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(
                text: headline,
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: colour, fontWeight: FontWeight.w700),
              ),
              if (detail != null)
                TextSpan(
                  text: ' · $detail',
                  style: theme.textTheme.bodyMedium,
                ),
            ]),
          ),
        ),
        if (badge24h) ...[
          const SizedBox(width: Spacing.md),
          _Badge24h(label: l10n?.badge24h ?? '24h'),
        ],
      ],
    );
  }

  /// The "Closes …" / "Opens …" trailing fragment, or `null` when there is
  /// no determinable next change (a 24/7 station).
  String? _detailText(OpenNowStatus status, AppLocalizations? l10n) {
    if (status.nextChangeDay == null || status.nextChangeMinutes == null) {
      return null;
    }
    final time = formatHhmm(status.nextChangeMinutes!);
    if (status.status == OpenStatus.open) {
      return l10n?.closesAt(time) ?? 'Closes $time';
    }
    // Closed → opens. Same-day vs other-day phrasing.
    final today = openingDayFromIsoWeekday(now.weekday);
    if (status.nextChangeDay == today) {
      return l10n?.opensToday(time) ?? 'Opens $time';
    }
    final day = shortDayName(status.nextChangeDay!, l10n);
    return l10n?.opensAt(day, time) ?? 'Opens $day $time';
  }

  /// True when an open station closes in under an hour (the amber
  /// "closing soon" emphasis). Handles a wrap past midnight.
  bool _closingSoon(OpenNowStatus status) {
    if (status.nextChangeMinutes == null) return false;
    final nowMinutes = now.hour * 60 + now.minute;
    var delta = status.nextChangeMinutes! - nowMinutes;
    if (delta < 0) delta += minutesPerDay;
    return delta > 0 && delta < 60;
  }
}

/// The compact `24h` pill rendered beside the status line.
class _Badge24h extends StatelessWidget {
  final String label;

  const _Badge24h({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('opening-hours-24h-badge'),
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md, vertical: Spacing.xs),
      decoration: BoxDecoration(
        color: DarkModeColors.successSurface(context),
        borderRadius: AppRadius.sm,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: DarkModeColors.success(context),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
