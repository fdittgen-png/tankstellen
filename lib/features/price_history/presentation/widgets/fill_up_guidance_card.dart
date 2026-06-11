// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../domain/entities/fill_up_guidance.dart';
import '../../providers/fill_up_guidance_provider.dart';

/// "Best time to fill up" guidance card driven by the on-device,
/// no-ML [fillUpGuidanceProvider] heuristic (#1543).
///
/// Renders nothing when the feature gate is off or the heuristic has
/// too little data to make a defensible claim — the provider returns
/// `null` in both cases.
class FillUpGuidanceCard extends ConsumerWidget {
  final String stationId;
  final FuelType fuelType;

  const FillUpGuidanceCard({
    super.key,
    required this.stationId,
    required this.fuelType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guidance =
        ref.watch(fillUpGuidanceProvider(stationId, fuelType));
    if (guidance == null) return const SizedBox.shrink();

    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (icon, accent) = _iconFor(context, guidance.kind);

    final message = _message(l, guidance);
    final saving = _savingLine(l, guidance);

    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l?.fillUpGuidanceTitle ?? 'Best time to fill up',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(message, style: theme.textTheme.bodyMedium),
                  if (saving != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      saving,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: DarkModeColors.success(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    l?.fillUpGuidanceSampleNote(guidance.sampleCount) ??
                        'Based on ${guidance.sampleCount} readings',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _iconFor(BuildContext context, FillUpGuidanceKind kind) {
    return switch (kind) {
      FillUpGuidanceKind.goodTimeNow => (
          Icons.local_gas_station,
          DarkModeColors.success(context),
        ),
      FillUpGuidanceKind.waitCheaperWindow => (
          Icons.schedule,
          DarkModeColors.warning(context),
        ),
      FillUpGuidanceKind.fillSoonRising => (
          Icons.trending_up,
          DarkModeColors.error(context),
        ),
      FillUpGuidanceKind.neutral ||
      FillUpGuidanceKind.insufficientData =>
        (
          Icons.info_outline,
          Theme.of(context).colorScheme.onSurfaceVariant,
        ),
    };
  }

  String _message(AppLocalizations? l, FillUpGuidance g) {
    switch (g.kind) {
      case FillUpGuidanceKind.goodTimeNow:
        return l?.fillUpGuidanceGoodTimeNow(g.windowDays) ??
            'The current price is in the cheapest part of the last '
                '${g.windowDays} days — a good time to fill up.';
      case FillUpGuidanceKind.waitCheaperWindow:
        final window = _windowPhrase(l, g);
        return l?.fillUpGuidanceWaitCheaper(g.windowDays, window) ??
            'Prices are near their ${g.windowDays}-day high. They are '
                'typically cheaper $window — consider waiting.';
      case FillUpGuidanceKind.fillSoonRising:
        return l?.fillUpGuidanceFillSoon ??
            'Prices are trending up — consider filling up soon.';
      case FillUpGuidanceKind.neutral:
      case FillUpGuidanceKind.insufficientData:
        return l?.fillUpGuidanceNeutral(g.windowDays) ??
            "Today's price is around the ${g.windowDays}-day average.";
    }
  }

  /// Builds the localized "when it's cheaper" phrase from whichever
  /// of day-of-week / day-part the heuristic surfaced.
  String _windowPhrase(AppLocalizations? l, FillUpGuidance g) {
    final day = g.cheapestDayOfWeek == null
        ? null
        : _weekdayName(l, g.cheapestDayOfWeek!);
    final part = g.cheapestDayPart == null
        ? null
        : _dayPartName(l, g.cheapestDayPart!);

    if (day != null && part != null) {
      return l?.fillUpGuidanceWindowDayAndPart(day, part) ?? '$day $part';
    }
    if (day != null) {
      return l?.fillUpGuidanceWindowDayOnly(day) ?? 'on $day';
    }
    if (part != null) {
      return l?.fillUpGuidanceWindowPartOnly(part) ?? 'in the $part';
    }
    return l?.fillUpGuidanceWindowGeneric ?? 'at other times';
  }

  String? _savingLine(AppLocalizations? l, FillUpGuidance g) {
    final saving = g.potentialSavingPerLitre;
    if (saving == null) return null;
    final amount = PriceFormatter.formatPrice(saving);
    return l?.fillUpGuidanceSaving(amount) ?? 'Could save about $amount/L';
  }

  String _weekdayName(AppLocalizations? l, int weekday) {
    if (l == null) return _fallbackWeekday(weekday);
    return switch (weekday) {
      1 => l.fillUpGuidanceWeekday1,
      2 => l.fillUpGuidanceWeekday2,
      3 => l.fillUpGuidanceWeekday3,
      4 => l.fillUpGuidanceWeekday4,
      5 => l.fillUpGuidanceWeekday5,
      6 => l.fillUpGuidanceWeekday6,
      _ => l.fillUpGuidanceWeekday7,
    };
  }

  String _dayPartName(AppLocalizations? l, DayPart part) {
    if (l == null) return part.name;
    return switch (part) {
      DayPart.earlyMorning => l.fillUpGuidancePartEarlyMorning,
      DayPart.morning => l.fillUpGuidancePartMorning,
      DayPart.afternoon => l.fillUpGuidancePartAfternoon,
      DayPart.evening => l.fillUpGuidancePartEvening,
      DayPart.night => l.fillUpGuidancePartNight,
    };
  }

  String _fallbackWeekday(int weekday) => const {
        1: 'Monday',
        2: 'Tuesday',
        3: 'Wednesday',
        4: 'Thursday',
        5: 'Friday',
        6: 'Saturday',
        7: 'Sunday',
      }[weekday]!;
}
