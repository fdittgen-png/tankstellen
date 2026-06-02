// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../station_detail/domain/opening_hours.dart';
import '../opening_hours/opening_hours_adapter.dart';

/// Normalises the Portuguese DGEG `HorarioPosto` opening-hours object (from the
/// `GetDadosPostoMapa` station-detail endpoint) into the common
/// [WeeklyOpeningHours] model (Epic #2707 C7, #2714).
///
/// ## Input shape (verified against the live DGEG detail endpoint)
/// `GetDadosPostoMapa?id=&f=json` returns `resultado.HorarioPosto`, a `Map`
/// with **four** keys — each a per-period schedule string:
///   - `DiasUteis` → the five regular weekdays Mon–Fri.
///   - `Sabado`    → Saturday.
///   - `Domingo`   → Sunday.
///   - `Feriado`   → the OSM `PH` public-holiday pseudo-day
///     ([OpeningDay.publicHoliday]).
///
/// Each value is one of (live shapes, not invented):
///   - `'Aberto 24 horas'` → [DayState.open24h] (open the whole day).
///   - `'HH:MM-HH:MM'`     → [DayState.openRanges] with one [TimeRange]
///     (`'07:00-22:00'`, `'07:00-19:30'`, …). A comma-joined multi-range
///     (`'08:00-12:00, 14:00-18:00'`) is tolerated defensively — each segment
///     becomes a [TimeRange].
///   - `'Fechado'`         → [DayState.closed] (explicitly closed).
///   - `null` / missing / blank → the period is omitted (implicitly unknown).
///
/// The detail `Map` itself (`resultado`) is also accepted as a convenience —
/// the adapter unwraps `HorarioPosto` from it — so callers can hand it the raw
/// `resultado` object without pre-narrowing.
///
/// ## Contract
/// Pure, total, never throws, never returns `null` — unparseable / empty input
/// degrades to [WeeklyOpeningHours.notAvailable] (the [OpeningHoursAdapter]
/// contract). The PT detail screen feeds this adapter directly; a parse fault
/// must never crash it.
class PortugalOpeningHoursAdapter extends OpeningHoursAdapter {
  const PortugalOpeningHoursAdapter();

  /// The DGEG "open 24 hours" marker. Lower-cased + accent-folded before the
  /// compare so `Aberto 24 horas` / `aberto 24 horas` both resolve.
  static const String _open24Token = 'aberto 24 horas';

  /// The DGEG "closed" marker (PT *Fechado*), same folding as above.
  static const String _closedToken = 'fechado';

  /// `HorarioPosto` period key → the [OpeningDay]s it covers. `DiasUteis`
  /// fans out across Mon–Fri; the rest map one-to-one.
  static const Map<String, List<OpeningDay>> _periodToDays = {
    'diasuteis': [
      OpeningDay.mon,
      OpeningDay.tue,
      OpeningDay.wed,
      OpeningDay.thu,
      OpeningDay.fri,
    ],
    'sabado': [OpeningDay.sat],
    'domingo': [OpeningDay.sun],
    'feriado': [OpeningDay.publicHoliday],
  };

  /// Captures one `HH:MM-HH:MM` clock range in four groups.
  static final RegExp _rangeRe =
      RegExp(r'(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})');

  @override
  WeeklyOpeningHours parse(dynamic rawProviderData) {
    try {
      final horario = _narrow(rawProviderData);
      if (horario == null || horario.isEmpty) {
        return WeeklyOpeningHours.notAvailable;
      }

      final days = <DayHours>[];
      var resolvedAny = false;

      for (final entry in _periodToDays.entries) {
        final value = horario[entry.key];
        final state = _stateFor(value);
        if (state == null) continue; // null / blank period → omit (unknown)
        resolvedAny = true;
        for (final day in entry.value) {
          days.add(_dayHours(day, state));
        }
      }

      if (!resolvedAny || days.isEmpty) {
        return WeeklyOpeningHours.notAvailable;
      }

      final coversAllWeekdays = kRegularWeekdays
          .every((d) => days.any((dh) => dh.day == d));
      return WeeklyOpeningHours(
        days: days,
        availability: coversAllWeekdays
            ? OpeningHoursAvailability.full
            : OpeningHoursAvailability.partial,
      );
    } catch (e, st) {
      // The adapter must never propagate a fault to the station-detail UI.
      assert(() {
        // ignore: avoid_print
        print('PortugalOpeningHoursAdapter.parse failed: $e\n$st');
        return true;
      }());
      return WeeklyOpeningHours.notAvailable;
    }
  }

  /// One resolved [_DayState] for a single [day]. Carries the parsed ranges
  /// for [DayState.openRanges].
  DayHours _dayHours(OpeningDay day, _DayState state) {
    switch (state.kind) {
      case DayState.open24h:
        return DayHours.allDay(day);
      case DayState.closed:
        return DayHours.closedDay(day);
      case DayState.openRanges:
        return DayHours(
          day: day,
          state: DayState.openRanges,
          ranges: state.ranges,
        );
      case DayState.unknown:
        return DayHours(day: day, state: DayState.unknown);
    }
  }

  /// Resolves a `HorarioPosto` period value into a [_DayState], or `null` when
  /// the period carries no usable signal (missing / blank / unparseable) so the
  /// caller omits the day (treated as unknown by the model).
  _DayState? _stateFor(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;

    final folded = _fold(raw);
    if (folded == _open24Token) return const _DayState(DayState.open24h);
    if (folded == _closedToken) return const _DayState(DayState.closed);

    final ranges = <TimeRange>[];
    for (final m in _rangeRe.allMatches(raw)) {
      final range = TimeRange.fromClock(
        startHour: int.parse(m.group(1)!),
        startMinute: int.parse(m.group(2)!),
        endHour: int.parse(m.group(3)!),
        endMinute: int.parse(m.group(4)!),
      );
      // A degenerate `HH:MM-HH:MM` with equal bounds carries no duration —
      // drop it (never a 24-hour wrap).
      if (range.isDegenerate) continue;
      ranges.add(range);
    }

    if (ranges.isEmpty) return null; // unrecognised token → no signal
    return _DayState(DayState.openRanges, ranges: ranges);
  }

  /// Narrows [raw] to the `HorarioPosto` map. Accepts the `HorarioPosto` object
  /// itself, or the enclosing `resultado` map (unwrap `HorarioPosto`).
  /// Anything else → `null`.
  Map<dynamic, dynamic>? _narrow(dynamic raw) {
    if (raw is Map) {
      final inner = raw['HorarioPosto'];
      if (inner is Map) return _foldKeys(inner);
      return _foldKeys(raw);
    }
    return null;
  }

  /// Lower-cases the period keys so the lookup is robust to casing drift in the
  /// feed (`DiasUteis` / `diasUteis`).
  Map<String, dynamic> _foldKeys(Map<dynamic, dynamic> m) {
    final out = <String, dynamic>{};
    for (final e in m.entries) {
      out[e.key.toString().toLowerCase().trim()] = e.value;
    }
    return out;
  }

  /// Lower-case + strip the Portuguese accents that appear in the markers so
  /// `Aberto 24 horas` / `Fechado` match regardless of accent drift.
  String _fold(String s) => s
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ã', 'a')
      .replaceAll('é', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('õ', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ç', 'c')
      .trim();
}

/// Internal resolution of one period value: the [DayState] kind plus, for
/// [DayState.openRanges], the parsed [ranges].
class _DayState {
  const _DayState(this.kind, {this.ranges = const []});

  final DayState kind;
  final List<TimeRange> ranges;
}
