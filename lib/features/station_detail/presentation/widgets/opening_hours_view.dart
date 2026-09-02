// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/opening_hours.dart';
import 'opening_hours_format.dart';

/// Google-/Apple-Maps-grade opening-hours display (Epic #2707 C2, #2709).
///
/// Renders a [WeeklyOpeningHours] as:
///   * a single **"Open 24 hours"** row when every day is around-the-clock —
///     never seven identical rows;
///   * a **collapsed week** that groups consecutive identical days into
///     "Mon – Fri 06:30–19:30" spans, expandable to the full per-day table;
///   * **today emphasis** (bold + a leading accent on today's row);
///   * a trailing **public-holidays** row when the schedule carries one;
///   * a muted, informational **"Self-service pump 24/7"** row when the
///     forecourt has an unattended automate (FR `Automate : 24/24`, #2742);
///   * a muted **"Opening hours not available"** line for the no-data case.
///
/// #3902 — the former "Open · Closes 19:30" status hero (+ `24h` badge) is
/// gone: the screen states the open / closed state ONCE, in the header's
/// `StationStatusRow`; this card is the schedule only.
///
/// Resolution is the caller's responsibility — pass
/// `detail.openingHours ?? legacyOpeningHoursBridge(detail)` so un-adapted
/// countries still render via the migration bridge.
class OpeningHoursView extends StatefulWidget {
  /// The resolved weekly schedule to render.
  final WeeklyOpeningHours hours;

  /// Injected wall-clock instant for the status line. Defaults to
  /// `DateTime.now()`; tests pass a fixed value for determinism.
  final DateTime? now;

  const OpeningHoursView({super.key, required this.hours, this.now});

  @override
  State<OpeningHoursView> createState() => _OpeningHoursViewState();
}

class _OpeningHoursViewState extends State<OpeningHoursView> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hours = widget.hours;

    // Graceful no-data: an empty / not-provided schedule renders a single
    // muted line, never a fake table (#2709).
    if (_isNoData(hours)) {
      return _NoDataLine(l10n: l10n);
    }

    final now = widget.now ?? DateTime.now();
    final all24h = _isAllDay24h(hours);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (all24h)
          _Open24Row(key: const ValueKey('opening-hours-24h-row'), l10n: l10n)
        else
          ..._buildWeek(hours, now, l10n),
        _buildHolidayRow(hours, l10n),
        // The 24/7-automate indicator is orthogonal to the staffed schedule:
        // an unattended pump open round-the-clock while the boutique keeps its
        // own per-day hours (FR `Automate : 24/24`, #2742). Shown in addition
        // to — never instead of — the staffed table above, as a muted
        // informational footnote (#3902: it used to be green like a link).
        if (hours.automate24h) ...[
          const SizedBox(height: Spacing.sm),
          _Automate24Line(l10n: l10n),
        ],
      ],
    );
  }

  /// The no-data path: explicitly not-provided, or simply nothing to show.
  bool _isNoData(WeeklyOpeningHours hours) {
    if (hours.availability == OpeningHoursAvailability.notProvided) {
      return true;
    }
    final hasRegular = kRegularWeekdays.any((d) {
      final dh = hours.dayFor(d);
      return dh != null && dh.state != DayState.unknown;
    });
    final hasHoliday = hours.dayFor(OpeningDay.publicHoliday) != null;
    return !hasRegular && !hasHoliday;
  }

  /// True when every regular weekday is [DayState.open24h].
  bool _isAllDay24h(WeeklyOpeningHours hours) =>
      kRegularWeekdays.every((d) => hours.dayFor(d)?.state == DayState.open24h);

  /// The collapsed week (consecutive identical days grouped) with an
  /// expand affordance; on expand, the full per-day table.
  List<Widget> _buildWeek(
    WeeklyOpeningHours hours,
    DateTime now,
    AppLocalizations l10n,
  ) {
    final today = openingDayFromIsoWeekday(now.weekday);
    final rows = <Widget>[];

    if (_expanded) {
      for (final day in kRegularWeekdays) {
        rows.add(
          _DayRow(
            label: fullDayName(day, l10n),
            value: dayValueText(hours.dayFor(day), l10n),
            emphasised: day == today,
          ),
        );
      }
    } else {
      for (final group in _groupWeek(hours)) {
        rows.add(
          _DayRow(
            label: _groupLabel(group, l10n),
            value: dayValueText(group.sample, l10n),
            emphasised: group.containsDay(today),
          ),
        );
      }
    }

    rows.add(
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton(
          key: const ValueKey('opening-hours-expand-toggle'),
          onPressed: () => setState(() => _expanded = !_expanded),
          child: Text(_expanded ? (l10n.showLessHours) : (l10n.showAllHours)),
        ),
      ),
    );
    return rows;
  }

  String _groupLabel(_DayGroup group, AppLocalizations l10n) {
    if (group.from == group.to) return shortDayName(group.from, l10n);
    final from = shortDayName(group.from, l10n);
    final to = shortDayName(group.to, l10n);
    return l10n.dayRange(from, to);
  }

  Widget _buildHolidayRow(WeeklyOpeningHours hours, AppLocalizations l10n) {
    final ph = hours.dayFor(OpeningDay.publicHoliday);
    if (ph == null) return const SizedBox.shrink();
    return _DayRow(
      key: const ValueKey('opening-hours-holiday-row'),
      label: l10n.publicHolidays,
      value: dayValueText(ph, l10n),
      emphasised: false,
    );
  }

  /// Groups consecutive [kRegularWeekdays] sharing the same `(state, ranges)`
  /// into [_DayGroup] spans (Mon..Fri runs collapse to one row).
  List<_DayGroup> _groupWeek(WeeklyOpeningHours hours) {
    final groups = <_DayGroup>[];
    for (final day in kRegularWeekdays) {
      final dh = hours.dayFor(day);
      if (groups.isNotEmpty && _sameShape(groups.last.sample, dh)) {
        groups.last.to = day;
      } else {
        groups.add(_DayGroup(from: day, to: day, sample: dh));
      }
    }
    return groups;
  }

  /// Two days look identical when their state matches and — for ranged days
  /// — their interval lists match minute-for-minute.
  bool _sameShape(DayHours? a, DayHours? b) {
    final sa = a?.state ?? DayState.unknown;
    final sb = b?.state ?? DayState.unknown;
    if (sa != sb) return false;
    if (sa != DayState.openRanges) return true;
    final ra = a!.ranges, rb = b!.ranges;
    if (ra.length != rb.length) return false;
    for (var i = 0; i < ra.length; i++) {
      if (ra[i].startMinutes != rb[i].startMinutes ||
          ra[i].endMinutes != rb[i].endMinutes) {
        return false;
      }
    }
    return true;
  }
}

/// A run of consecutive identical weekdays, [from]..[to], sharing [sample]'s
/// state + ranges.
class _DayGroup {
  final OpeningDay from;
  OpeningDay to;
  final DayHours? sample;

  _DayGroup({required this.from, required this.to, required this.sample});

  /// Whether [day] falls inside this Mon..Sun-ordered span.
  bool containsDay(OpeningDay day) {
    final a = kRegularWeekdays.indexOf(from);
    final b = kRegularWeekdays.indexOf(to);
    final d = kRegularWeekdays.indexOf(day);
    if (a < 0 || b < 0 || d < 0) return false;
    return d >= a && d <= b;
  }
}

/// The muted single-line no-data state.
class _NoDataLine extends StatelessWidget {
  final AppLocalizations l10n;

  const _NoDataLine({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      key: const ValueKey('opening-hours-not-available'),
      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            size: 18,
            color: DarkModeColors.mutedText(context),
          ),
          const SizedBox(width: Spacing.lg),
          Expanded(
            child: Text(
              l10n.openingHoursNotAvailable,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: DarkModeColors.mutedText(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The single "Open 24 hours" row shown for an around-the-clock station.
class _Open24Row extends StatelessWidget {
  final AppLocalizations l10n;

  const _Open24Row({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            size: 18,
            color: DarkModeColors.success(context),
          ),
          const SizedBox(width: Spacing.lg),
          Expanded(
            child: Text(l10n.open24Hours, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// The self-service automate indicator: an unattended, card-payment pump
/// open round-the-clock alongside the staffed boutique schedule (FR
/// `Automate : 24/24`, #2742).
///
/// #3902 — purely informational: rendered in the neutral
/// `onSurfaceVariant` colour with no tap target. It used to be bold green
/// with a pump icon, which read as an action (and the French copy said
/// "Automatiser" — the verb — instead of the noun "Automate").
class _Automate24Line extends StatelessWidget {
  final AppLocalizations l10n;

  const _Automate24Line({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      key: const ValueKey('opening-hours-automate-24h'),
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.local_gas_station, size: 18, color: muted),
          const SizedBox(width: Spacing.lg),
          Expanded(
            child: Text(
              l10n.openingHoursAutomate24h,
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// One label/value table row, with optional today-emphasis (a leading
/// accent bar + bold text).
class _DayRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasised;

  const _DayRow({
    super.key,
    required this.label,
    required this.value,
    required this.emphasised,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weight = emphasised ? FontWeight.w700 : FontWeight.w400;
    final accent = theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 16,
            margin: const EdgeInsetsDirectional.only(end: Spacing.lg),
            decoration: BoxDecoration(
              color: emphasised ? accent : Colors.transparent,
              borderRadius: AppRadius.sm,
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: weight),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: weight),
            ),
          ),
        ],
      ),
    );
  }
}
