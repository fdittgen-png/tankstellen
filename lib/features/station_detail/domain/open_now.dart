// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:freezed_annotation/freezed_annotation.dart';

import 'opening_hours.dart';

part 'open_now.freezed.dart';

/// Whether a station is open right now.
enum OpenStatus { open, closed, unknown }

/// The result of [computeOpenNow]: the current [status] and — when known —
/// the next state change.
///
/// [nextChangeDay] / [nextChangeMinutes] describe the next transition:
/// when [status] is [OpenStatus.open] they are the day + minute the station
/// *closes*; when [OpenStatus.closed] they are when it next *opens*. Both
/// are `null` when there is no determinable next change (e.g. 24/7, or
/// [OpenStatus.unknown]).
@freezed
abstract class OpenNowStatus with _$OpenNowStatus {
  const factory OpenNowStatus({
    required OpenStatus status,
    OpeningDay? nextChangeDay,
    int? nextChangeMinutes,
  }) = _OpenNowStatus;

  /// "Open, no determinable next close" — e.g. a 24/7 station.
  static const OpenNowStatus open = OpenNowStatus(status: OpenStatus.open);

  /// "We don't know" — the schedule was [DayState.unknown] / not provided.
  static const OpenNowStatus unknown =
      OpenNowStatus(status: OpenStatus.unknown);
}

const int _minutesPerDay = 24 * 60;

/// Computes whether [hours] is open at the wall-clock instant [now].
///
/// Pure — pass [now] in (never reads `DateTime.now()`) so it is fully
/// unit-testable. Handles:
///   - whole-station / per-day [DayState.open24h] → open;
///   - multi-interval days;
///   - intervals that **wrap past midnight** (a `22:00-04:00` range is open
///     at `02:00` the *next* day — checked via yesterday's wrapping ranges);
///   - [DayState.unknown] / no-data → [OpenStatus.unknown];
///   - [TimeRange.isDegenerate] ranges are ignored (FR `01:00-01:00`).
///
/// Public holidays are *not* auto-detected here (the model carries no
/// calendar); a caller that knows today is a holiday can resolve the
/// `PH` day itself. This uses [now]'s ISO weekday for the regular cycle.
OpenNowStatus computeOpenNow(WeeklyOpeningHours hours, DateTime now) {
  if (hours.availability == OpeningHoursAvailability.notProvided &&
      hours.days.isEmpty) {
    return OpenNowStatus.unknown;
  }

  final today = openingDayFromIsoWeekday(now.weekday);
  final todayHours = hours.dayFor(today);
  final nowMinutes = now.hour * 60 + now.minute;

  // 1. A range from *yesterday* that wraps past midnight may still cover now.
  final yesterday = _previousDay(today);
  final yHours = hours.dayFor(yesterday);
  if (yHours != null && yHours.state == DayState.openRanges) {
    for (final r in yHours.ranges) {
      if (r.isDegenerate) continue;
      if (r.wrapsPastMidnight && nowMinutes < r.endMinutes) {
        // Still inside yesterday's overnight interval; closes today at end.
        return OpenNowStatus(
          status: OpenStatus.open,
          nextChangeDay: today,
          nextChangeMinutes: r.endMinutes,
        );
      }
    }
  }

  // 2. Today's own state.
  if (todayHours == null || todayHours.state == DayState.unknown) {
    // No signal for today, but yesterday's wrap didn't cover us → unknown
    // only if the whole schedule is unknown; otherwise treat as closed and
    // search forward for the next opening.
    if (_allUnknown(hours)) return OpenNowStatus.unknown;
    return _findNextOpening(hours, today, nowMinutes);
  }

  switch (todayHours.state) {
    case DayState.open24h:
      return OpenNowStatus.open;
    case DayState.closed:
      return _findNextOpening(hours, today, nowMinutes);
    case DayState.unknown:
      if (_allUnknown(hours)) return OpenNowStatus.unknown;
      return _findNextOpening(hours, today, nowMinutes);
    case DayState.openRanges:
      for (final r in todayHours.ranges) {
        if (r.isDegenerate) continue;
        if (r.wrapsPastMidnight) {
          // Open from start through midnight; if now >= start we're open,
          // closing on the *next* day at end.
          if (nowMinutes >= r.startMinutes) {
            return OpenNowStatus(
              status: OpenStatus.open,
              nextChangeDay: _nextDay(today),
              nextChangeMinutes: r.endMinutes,
            );
          }
        } else if (nowMinutes >= r.startMinutes &&
            nowMinutes < r.endMinutes) {
          return OpenNowStatus(
            status: OpenStatus.open,
            nextChangeDay: today,
            nextChangeMinutes: r.endMinutes,
          );
        }
      }
      // Not inside any of today's ranges → closed; find the next opening.
      return _findNextOpening(hours, today, nowMinutes);
  }
}

/// True when no regular weekday carries a resolved state.
bool _allUnknown(WeeklyOpeningHours hours) {
  for (final d in kRegularWeekdays) {
    final dh = hours.dayFor(d);
    if (dh != null && dh.state != DayState.unknown) return false;
  }
  return true;
}

/// Searches forward up to 7 days for the next opening transition, returning
/// an [OpenStatus.closed] result whose next-change points at that opening.
/// Falls back to a bare closed (no next change) when nothing opens.
OpenNowStatus _findNextOpening(
  WeeklyOpeningHours hours,
  OpeningDay today,
  int nowMinutes,
) {
  for (var offset = 0; offset < kRegularWeekdays.length; offset++) {
    final day = _dayAfter(today, offset);
    final dh = hours.dayFor(day);
    if (dh == null) continue;
    if (dh.state == DayState.open24h) {
      // A 24h day in the future: it "opens" at 00:00 of that day. For today
      // (offset 0) we'd have returned open already, so offset>0 here.
      return OpenNowStatus(
        status: OpenStatus.closed,
        nextChangeDay: day,
        nextChangeMinutes: 0,
      );
    }
    if (dh.state != DayState.openRanges) continue;
    final starts = <int>[
      for (final r in dh.ranges)
        if (!r.isDegenerate) r.startMinutes,
    ]..sort();
    for (final start in starts) {
      // On today, only future starts count.
      if (offset == 0 && start <= nowMinutes) continue;
      return OpenNowStatus(
        status: OpenStatus.closed,
        nextChangeDay: day,
        nextChangeMinutes: start,
      );
    }
  }
  return const OpenNowStatus(status: OpenStatus.closed);
}

OpeningDay _previousDay(OpeningDay day) => _dayAfter(day, 6);

OpeningDay _nextDay(OpeningDay day) => _dayAfter(day, 1);

/// [day] advanced by [offset] regular weekdays (wrapping Mon..Sun). Ignores
/// [OpeningDay.publicHoliday], which is not part of the cyclic week.
OpeningDay _dayAfter(OpeningDay day, int offset) {
  final idx = kRegularWeekdays.indexOf(day);
  if (idx < 0) return day; // publicHoliday — not in the cycle.
  return kRegularWeekdays[(idx + offset) % kRegularWeekdays.length];
}

/// Minutes in a day, exported for callers that format a next-change time.
int get minutesPerDay => _minutesPerDay;
