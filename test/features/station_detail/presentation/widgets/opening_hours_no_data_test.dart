// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/station_detail/domain/legacy_opening_hours_bridge.dart';
import 'package:tankstellen/features/station_detail/domain/opening_hours.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/opening_hours_view.dart';

import '../../../../helpers/pump_app.dart';

/// Regression guard for the graceful no-data state of the 11 countries that
/// ship **without** an [OpeningHoursAdapter] today (Epic #2707 Cx, #2716):
///
///   GB, IT, DK, GR, RO, SI, LU, AU, MX, AR, KR.
///
/// Their station services populate neither `StationDetail.openingHours` nor
/// the legacy `Station.is24h` / `StationDetail.openingTimes` fields, so the
/// display layer resolves their schedule through
/// `legacyOpeningHoursBridge(detail)`. This test locks that path end-to-end:
/// the bridge yields [WeeklyOpeningHours.notAvailable], and pumping
/// [OpeningHoursView] with it renders the localized
/// `openingHoursNotAvailable` line — never a fabricated table or status
/// hero. See `docs/guides/opening-hours.md` for the deferral rationale and
/// when to revisit each country.
void main() {
  // A Wednesday — fixed `now` keeps the status line / today-emphasis
  // deterministic. Irrelevant on the no-data path (the view returns early),
  // but passed for parity with the real call site.
  final wednesday = DateTime(2026, 6, 3, 10, 0);

  /// A bare [StationDetail] for a deferred country: no adapter-populated
  /// `openingHours`, no legacy `is24h`, no `openingTimes`. Exactly the shape
  /// every GB/IT/DK/GR/RO/SI/LU/AU/MX/AR/KR station detail has today.
  StationDetail deferredCountryDetail() => const StationDetail(
        station: Station(
          id: 's1',
          name: 'Deferred-country station',
          brand: 'B',
          street: 'St',
          postCode: '1',
          place: 'P',
          lat: 0,
          lng: 0,
          isOpen: true,
          // is24h defaults to false — the deferred services never set it.
        ),
        // openingTimes defaults to const [] — no legacy schedule either.
        // openingHours is null — no adapter ran.
      );

  group('opening-hours no-data — deferred countries (#2716)', () {
    test('bridge maps a no-OH StationDetail to notAvailable', () {
      final detail = deferredCountryDetail();

      // Preconditions: this really is the deferred-country shape.
      expect(detail.openingHours, isNull);
      expect(detail.station.is24h, isFalse);
      expect(detail.openingTimes, isEmpty);

      final resolved = legacyOpeningHoursBridge(detail);
      expect(resolved, WeeklyOpeningHours.notAvailable);
      expect(resolved.availability, OpeningHoursAvailability.notProvided);
      expect(resolved.days, isEmpty);
    });

    testWidgets(
        'view renders the localized no-data line, not a fake table/status',
        (tester) async {
      // Mirror the real call site exactly:
      //   detail.openingHours ?? legacyOpeningHoursBridge(detail)
      final detail = deferredCountryDetail();
      final WeeklyOpeningHours resolved =
          detail.openingHours ?? legacyOpeningHoursBridge(detail);

      await pumpApp(
        tester,
        SingleChildScrollView(
          child: OpeningHoursView(hours: resolved, now: wednesday),
        ),
      );

      // The muted, localized no-data line is shown.
      expect(find.byKey(const ValueKey('opening-hours-not-available')),
          findsOneWidget);
      expect(find.text('Opening hours not available'), findsOneWidget);

      // ...and NOT a fabricated schedule: no status hero, no 24h row, no
      // collapsed-week expand affordance, no holiday row.
      expect(find.byKey(const ValueKey('opening-hours-status-line')),
          findsNothing);
      expect(find.byKey(const ValueKey('opening-hours-24h-row')),
          findsNothing);
      expect(find.byKey(const ValueKey('opening-hours-expand-toggle')),
          findsNothing);
      expect(find.byKey(const ValueKey('opening-hours-holiday-row')),
          findsNothing);
    });

    test('passing the notAvailable sentinel through the bridge is stable', () {
      // A country whose (future) adapter explicitly returned the no-data
      // sentinel must not be "upgraded" by the bridge into a fake schedule.
      final detail = StationDetail(
        station: deferredCountryDetail().station,
        openingHours: WeeklyOpeningHours.notAvailable,
      );
      expect(legacyOpeningHoursBridge(detail), WeeklyOpeningHours.notAvailable);
    });
  });
}
