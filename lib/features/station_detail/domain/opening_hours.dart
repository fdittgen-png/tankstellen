// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:freezed_annotation/freezed_annotation.dart';

part 'opening_hours.freezed.dart';
part 'opening_hours.g.dart';

/// A day of the week, plus the OSM `PH` (public-holiday) pseudo-day.
///
/// The seven weekdays are ordered Monday-first to match ISO 8601 and
/// `DateTime.weekday` (Mon = 1 … Sun = 7). [publicHoliday] mirrors the OSM
/// `Key:opening_hours` `PH` token — AT *Feiertag*, PT *Feriado* — and has
/// no ISO weekday; it is carried separately so a country adapter can model
/// the common "closed on public holidays" rule without inventing an 8th
/// weekday in the regular Mon–Sun cycle.
enum OpeningDay { mon, tue, wed, thu, fri, sat, sun, publicHoliday }

/// Maps a 1..7 ISO weekday (`DateTime.weekday`) onto an [OpeningDay].
///
/// Pure helper. Returns [OpeningDay.mon] for an out-of-range value rather
/// than throwing — it must never be a crash site. Callers that may receive
/// `PH` should branch on it before calling this.
OpeningDay openingDayFromIsoWeekday(int isoWeekday) {
  switch (isoWeekday) {
    case DateTime.monday:
      return OpeningDay.mon;
    case DateTime.tuesday:
      return OpeningDay.tue;
    case DateTime.wednesday:
      return OpeningDay.wed;
    case DateTime.thursday:
      return OpeningDay.thu;
    case DateTime.friday:
      return OpeningDay.fri;
    case DateTime.saturday:
      return OpeningDay.sat;
    case DateTime.sunday:
      return OpeningDay.sun;
    default:
      return OpeningDay.mon;
  }
}

/// The seven regular weekdays in Mon..Sun order, excluding
/// [OpeningDay.publicHoliday].
const List<OpeningDay> kRegularWeekdays = [
  OpeningDay.mon,
  OpeningDay.tue,
  OpeningDay.wed,
  OpeningDay.thu,
  OpeningDay.fri,
  OpeningDay.sat,
  OpeningDay.sun,
];

/// A single opening interval within one day, in minutes-from-midnight
/// (local time). Both bounds are 0..1439.
///
/// When [endMinutes] is less than or equal to [startMinutes] the interval
/// *wraps past midnight* into the following day (OSM e.g. `22:00-04:00`).
/// A range where the two bounds are equal is [isDegenerate] — it carries no
/// duration. Some providers emit such a sentinel (the FR feed's
/// `01:00-01:00`) to mean "no real interval"; [isDegenerate] lets callers
/// filter it out instead of treating it as a 24-hour wrap.
@freezed
abstract class TimeRange with _$TimeRange {
  const TimeRange._();

  const factory TimeRange({
    required int startMinutes,
    required int endMinutes,
  }) = _TimeRange;

  factory TimeRange.fromJson(Map<String, dynamic> json) =>
      _$TimeRangeFromJson(json);

  /// Convenience: build from local `HH:mm` 24h clock parts.
  factory TimeRange.fromClock({
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) =>
      TimeRange(
        startMinutes: startHour * 60 + startMinute,
        endMinutes: endHour * 60 + endMinute,
      );

  /// True when the two bounds coincide → the range carries no duration and
  /// should be filtered (the FR `01:00-01:00` no-interval sentinel).
  bool get isDegenerate => startMinutes == endMinutes;

  /// True when the interval crosses midnight into the next day
  /// (`endMinutes <= startMinutes`, e.g. `22:00-04:00`). A degenerate range
  /// is *not* treated as a wrap.
  bool get wrapsPastMidnight => !isDegenerate && endMinutes <= startMinutes;
}

/// The shape of a single day's opening information.
///
/// - [closed] — explicitly closed all day.
/// - [open24h] — open the whole day (OSM `24/7` for one day).
/// - [openRanges] — open during the [DayHours.ranges].
/// - [unknown] — the provider gave no usable signal for this day.
enum DayState { closed, open24h, openRanges, unknown }

/// One day's opening hours: which [day], its [state], and — for
/// [DayState.openRanges] — the list of [ranges] (multiple intervals per day
/// are allowed, e.g. a lunch break `08:00-12:00, 14:00-18:00`).
@freezed
abstract class DayHours with _$DayHours {
  const factory DayHours({
    required OpeningDay day,
    required DayState state,
    @Default([]) List<TimeRange> ranges,
  }) = _DayHours;

  factory DayHours.fromJson(Map<String, dynamic> json) =>
      _$DayHoursFromJson(json);

  /// A whole-day-open ([DayState.open24h]) entry for [day].
  factory DayHours.allDay(OpeningDay day) =>
      DayHours(day: day, state: DayState.open24h);

  /// An explicitly-closed entry for [day].
  factory DayHours.closedDay(OpeningDay day) =>
      DayHours(day: day, state: DayState.closed);
}

/// How complete the parsed opening-hours data is.
///
/// - [full] — every day the provider covers is resolved (open/closed/24h).
/// - [partial] — some days resolved, others [DayState.unknown].
/// - [notProvided] — the provider gave no opening-hours data at all.
enum OpeningHoursAvailability { full, partial, notProvided }

/// A station's complete weekly opening hours.
///
/// [days] holds at most one [DayHours] per [OpeningDay]; a missing day is
/// implicitly [DayState.unknown]. A whole-station 24/7 station is every
/// regular weekday as [DayState.open24h]. [availability] flags how much of
/// the schedule the source actually provided, and [rawSource] keeps the
/// untouched provider string (OSM `opening_hours` value, etc.) for debugging
/// / round-tripping. Use [notAvailable] for the graceful no-data state.
///
/// [automate24h] is an *orthogonal* indicator: some sites (the FR
/// Prix-Carburants `Automate : 24/24` flag, #2742) run an unattended pump
/// around the clock **while the staffed boutique keeps its own per-day
/// [days] schedule**. It is true only for those sites; a plain whole-station
/// 24/7 schedule (every day [DayState.open24h]) leaves it false. The display
/// layer renders a "24/7 automate" badge from it *in addition to* the
/// staffed table, instead of collapsing everything to a single "Open 24
/// hours" row.
@freezed
abstract class WeeklyOpeningHours with _$WeeklyOpeningHours {
  const WeeklyOpeningHours._();

  const factory WeeklyOpeningHours({
    @Default([]) List<DayHours> days,
    @Default(OpeningHoursAvailability.notProvided)
    OpeningHoursAvailability availability,
    String? rawSource,
    @Default(false) bool automate24h,
  }) = _WeeklyOpeningHours;

  factory WeeklyOpeningHours.fromJson(Map<String, dynamic> json) =>
      _$WeeklyOpeningHoursFromJson(json);

  /// The graceful no-data sentinel: no days,
  /// [OpeningHoursAvailability.notProvided]. Adapters return this on missing
  /// / unparseable input so the no-data UI path is uniform.
  static const WeeklyOpeningHours notAvailable = WeeklyOpeningHours();

  /// A whole-station 24/7 schedule: all seven regular weekdays open24h.
  ///
  /// Pass [automate24h] `true` for a pump-only 24/7 site that carries no
  /// staffed per-day schedule (the FR `Automate : 24/24` feed with no
  /// boutique hours, #2742) — the display still shows the "24/7 automate"
  /// badge.
  factory WeeklyOpeningHours.allWeek24h({
    String? rawSource,
    bool automate24h = false,
  }) =>
      WeeklyOpeningHours(
        days: [for (final d in kRegularWeekdays) DayHours.allDay(d)],
        availability: OpeningHoursAvailability.full,
        rawSource: rawSource,
        automate24h: automate24h,
      );

  /// The [DayHours] for [day], or `null` when the source did not cover it
  /// (treat a `null` as [DayState.unknown]).
  DayHours? dayFor(OpeningDay day) {
    for (final d in days) {
      if (d.day == day) return d;
    }
    return null;
  }
}
