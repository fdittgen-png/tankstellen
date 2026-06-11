// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/domain/opening_hours.dart';
import '../opening_hours/opening_hours_adapter.dart';

/// Normalises the Chilean CNE "Bencina en Línea" `horario_atencion` field
/// into the common [WeeklyOpeningHours] model (Epic #2707 C8, #2715).
///
/// ## Input shape
/// [parse] accepts the raw `horario_atencion` value — a short `String`, e.g.
/// `"24_horas"`, `"Cerrado"`, or a free-text Spanish schedule
/// (`"Lunes a Domingo 07:00-22:00"`). A `Map` carrying the field under
/// `horario_atencion` (a whole `data[]` station row) is also accepted as a
/// convenience so the Chile parse path can hand the row through unchanged.
///
/// ## Real-feed values (verified, not invented)
/// The CNE feed exposes `horario_atencion` as a free-form short string; the
/// live values this adapter was grounded on are:
///   - **`24_horas`** (the documented default — see `ChileStationService` and
///     the existing `chile_response_parser.dart` `isOpen` derivation) →
///     [WeeklyOpeningHours.allWeek24h]. Accents/spacing tolerated
///     (`24 horas`, `24horas`).
///   - **A `cerrado` token** (e.g. `"Temporalmente CERRADO por mantenimiento"`,
///     matching the existing `isOpen` `contains('cerrado')` rule) → every
///     regular weekday [DayState.closed].
///   - **A free-text schedule** with one or more `HH:MM-HH:MM` clock ranges
///     and optional Spanish day / day-range labels
///     (`"Lunes a Viernes 07:00-22:00, Sábado 08:00-14:00"`) → best-effort
///     per-day [DayState.openRanges]. A bare range with no day label
///     (`"07:00-22:00"`) is applied to every regular weekday.
///   - **Anything else** — empty, the `"HH"` placeholder the API docs ship,
///     or a string with no recognisable clock → [WeeklyOpeningHours.notAvailable]
///     ([OpeningHoursAvailability.notProvided]).
///
/// This adapter is purely additive: it does NOT change the boolean `isOpen`
/// derivation in `chile_response_parser.dart` (#2715 keeps it intact). It only
/// produces the richer [WeeklyOpeningHours] threaded onto `Station.openingHours`.
///
/// Honours the [OpeningHoursAdapter] contract: pure, never throws, never
/// returns `null`.
class ChileOpeningHoursAdapter extends OpeningHoursAdapter {
  const ChileOpeningHoursAdapter();

  /// The CNE field that carries the schedule on a `data[]` station row.
  // i18n-ignore: CNE feed JSON key, not user-facing text
  static const String _fieldKey = 'horario_atencion';

  /// The documented 24/7 marker (and `chile_response_parser`'s default).
  // i18n-ignore: CNE feed enum value, not user-facing text
  static const String _open24Token = '24_horas';

  /// The closed marker the existing `isOpen` derivation keys on.
  // i18n-ignore: CNE feed enum value, not user-facing text
  static const String _closedToken = 'cerrado';

  /// Spanish weekday label → [OpeningDay]. Accent-folded + lower-cased before
  /// lookup (`miércoles`/`miercoles`, `sábado`/`sabado` both resolve). Used to
  /// attribute a clock range to a specific day in a free-text schedule.
  static const Map<String, OpeningDay> _dayByLabel = {
    'lunes': OpeningDay.mon,
    'martes': OpeningDay.tue,
    'miercoles': OpeningDay.wed,
    'jueves': OpeningDay.thu,
    'viernes': OpeningDay.fri,
    'sabado': OpeningDay.sat,
    'domingo': OpeningDay.sun,
  };

  /// Captures an `HH:MM-HH:MM` (or `HH.MM-HH.MM`) clock range.
  static final RegExp _rangeRe = RegExp(
    r'(\d{1,2})[.:](\d{2})\s*-\s*(\d{1,2})[.:](\d{2})',
  );

  /// Captures a `<label>` token immediately preceding a clock range, plus the
  /// optional `a <label2>` span (`Lunes a Viernes 07:00-22:00`). The schedule
  /// is split on these matches so each range is attributed to its day(s).
  static final RegExp _segmentRe = RegExp(
    r'([a-zà-ÿ]+)(?:\s+a\s+([a-zà-ÿ]+))?\s+(\d{1,2}[.:]\d{2}\s*-\s*\d{1,2}[.:]\d{2})',
    caseSensitive: false,
  );

  @override
  WeeklyOpeningHours parse(dynamic rawProviderData) {
    try {
      final raw = _narrow(rawProviderData);
      if (raw == null) return WeeklyOpeningHours.notAvailable;

      final trimmed = raw.trim();
      if (trimmed.isEmpty) return WeeklyOpeningHours.notAvailable;

      final folded = _fold(trimmed);

      // 24_horas (and spacing variants) → whole week open 24h. Compare against
      // the canonical token with separators stripped so `24 horas`, `24horas`
      // and `24_HORAS` all match the documented `24_horas` default.
      final compact = folded.replaceAll(' ', '').replaceAll('_', '');
      if (compact == _open24Token.replaceAll('_', '')) {
        return WeeklyOpeningHours.allWeek24h(rawSource: trimmed);
      }

      // A `cerrado` token → every regular weekday explicitly closed. Mirrors
      // the existing `isOpen` `contains('cerrado')` rule so the two signals
      // agree.
      if (folded.contains(_closedToken)) {
        return WeeklyOpeningHours(
          days: [for (final d in kRegularWeekdays) DayHours.closedDay(d)],
          availability: OpeningHoursAvailability.full,
          rawSource: trimmed,
        );
      }

      // Otherwise a free-text schedule: pull the per-day ranges out.
      return _parseSchedule(trimmed, folded);
    } catch (e, st) {
      // Contract: the adapter feeds user-facing UI and must never propagate a
      // parse fault to the station-detail screen — degrade to no-data,
      // release-visibly (#3148).
      reportParseFailure('CL', e, st);
      return WeeklyOpeningHours.notAvailable;
    }
  }

  /// Narrow [rawProviderData] to the `horario_atencion` string. Accepts the
  /// bare value or a `Map` station row carrying it. Anything else → `null`.
  String? _narrow(dynamic raw) {
    if (raw is String) return raw;
    if (raw is Map) return raw[_fieldKey]?.toString();
    return null;
  }

  /// Best-effort parse of a free-text schedule. Day-labelled segments
  /// (`Lunes a Viernes 07:00-22:00`) attribute their range to the named
  /// day(s); a schedule with clock ranges but no day labels applies every
  /// range to all regular weekdays. No usable clock range → notAvailable.
  WeeklyOpeningHours _parseSchedule(String rawSource, String folded) {
    final byDay = <OpeningDay, List<TimeRange>>{};
    var matchedLabelledSegment = false;

    for (final m in _segmentRe.allMatches(folded)) {
      final startDay = _dayByLabel[m.group(1)];
      if (startDay == null) continue;
      final range = _rangeFrom(m.group(3)!);
      if (range == null) continue;
      matchedLabelledSegment = true;
      final endDay = m.group(2) != null ? _dayByLabel[m.group(2)] : null;
      for (final day in _spanDays(startDay, endDay)) {
        (byDay[day] ??= <TimeRange>[]).add(range);
      }
    }

    if (matchedLabelledSegment) {
      return _build(byDay, rawSource);
    }

    // No day labels — apply every clock range to the whole regular week.
    final ranges = <TimeRange>[];
    for (final m in _rangeRe.allMatches(folded)) {
      final range = _rangeFromMatch(m);
      if (range != null) ranges.add(range);
    }
    if (ranges.isEmpty) return WeeklyOpeningHours.notAvailable;
    for (final day in kRegularWeekdays) {
      byDay[day] = List.of(ranges);
    }
    return _build(byDay, rawSource);
  }

  /// Assemble the per-day map into a [WeeklyOpeningHours] (full when all seven
  /// regular weekdays resolved, else partial). Empty → notAvailable.
  WeeklyOpeningHours _build(
    Map<OpeningDay, List<TimeRange>> byDay,
    String rawSource,
  ) {
    if (byDay.isEmpty) return WeeklyOpeningHours.notAvailable;
    final days = <DayHours>[
      for (final day in kRegularWeekdays)
        if (byDay[day] case final r? when r.isNotEmpty)
          DayHours(day: day, state: DayState.openRanges, ranges: r),
    ];
    if (days.isEmpty) return WeeklyOpeningHours.notAvailable;
    return WeeklyOpeningHours(
      days: days,
      availability: days.length == kRegularWeekdays.length
          ? OpeningHoursAvailability.full
          : OpeningHoursAvailability.partial,
      rawSource: rawSource,
    );
  }

  /// Inclusive Mon..Sun span from [start] to [end] (a single day when [end] is
  /// null). Wraps within the week so `Viernes a Lunes` covers Fri–Mon.
  List<OpeningDay> _spanDays(OpeningDay start, OpeningDay? end) {
    if (end == null) return [start];
    final startIdx = kRegularWeekdays.indexOf(start);
    final endIdx = kRegularWeekdays.indexOf(end);
    if (startIdx < 0 || endIdx < 0) return [start];
    final out = <OpeningDay>[];
    var i = startIdx;
    while (true) {
      out.add(kRegularWeekdays[i]);
      if (i == endIdx) break;
      i = (i + 1) % kRegularWeekdays.length;
    }
    return out;
  }

  /// `HH:MM-HH:MM` → a [TimeRange], or `null` when unparseable / degenerate.
  TimeRange? _rangeFrom(String text) {
    final m = _rangeRe.firstMatch(text);
    return m == null ? null : _rangeFromMatch(m);
  }

  TimeRange? _rangeFromMatch(RegExpMatch m) {
    final sh = int.tryParse(m.group(1)!);
    final sm = int.tryParse(m.group(2)!);
    final eh = int.tryParse(m.group(3)!);
    final em = int.tryParse(m.group(4)!);
    if (sh == null || sm == null || eh == null || em == null) return null;
    if (!_validClock(sh, sm) || !_validClock(eh, em, allow24: true)) {
      return null;
    }
    final range = TimeRange.fromClock(
      startHour: sh,
      startMinute: sm,
      endHour: eh,
      endMinute: em,
    );
    // A degenerate `HH:MM-HH:MM` carries no interval → drop it.
    return range.isDegenerate ? null : range;
  }

  bool _validClock(int h, int m, {bool allow24 = false}) {
    if (allow24 && h == 24 && m == 0) return true;
    return h >= 0 && h <= 23 && m >= 0 && m <= 59;
  }

  /// Lower-case + strip Spanish accents so label / token lookups are robust to
  /// casing and accent drift in the feed.
  String _fold(String s) => s
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ñ', 'n');
}
