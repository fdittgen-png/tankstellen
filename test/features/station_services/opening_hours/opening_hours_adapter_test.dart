// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/station_detail/domain/opening_hours.dart';
import 'package:tankstellen/features/station_services/opening_hours/opening_hours_adapter.dart';

/// A conforming adapter that shape-narrows its raw input and catches any
/// fault, returning the no-data sentinel — the exact contract the
/// [OpeningHoursAdapter] interface documents (pure, never throws, never
/// null). Used to fault-inject the contract (#2349 never-throws boundary).
class _FaultTolerantAdapter extends OpeningHoursAdapter {
  const _FaultTolerantAdapter();

  @override
  WeeklyOpeningHours parse(dynamic rawProviderData) {
    try {
      final s = rawProviderData as String; // throws on a non-String shape
      if (s.isEmpty) return WeeklyOpeningHours.notAvailable;
      return const WeeklyOpeningHours(
        availability: OpeningHoursAvailability.full,
      );
    } catch (_) {
      return WeeklyOpeningHours.notAvailable;
    }
  }
}

void main() {
  group('OpeningHoursAdapter never-throws contract', () {
    const adapter = _FaultTolerantAdapter();

    test('parse returns normally on a malformed shape (fault injection)', () {
      // Feed shapes a String parser does not expect → the `as String` cast
      // throws internally; the contract requires it be caught, not propagated.
      expect(() => adapter.parse(42), returnsNormally);
      expect(adapter.parse(42), WeeklyOpeningHours.notAvailable);
      expect(() => adapter.parse(null), returnsNormally);
      expect(adapter.parse(null), WeeklyOpeningHours.notAvailable);
      expect(() => adapter.parse(const {'unexpected': true}), returnsNormally);
      expect(adapter.parse(const {'unexpected': true}),
          WeeklyOpeningHours.notAvailable);
    });

    test('parse never returns null on empty input', () {
      expect(adapter.parse(''), isNotNull);
      expect(adapter.parse(''), WeeklyOpeningHours.notAvailable);
    });
  });
}
